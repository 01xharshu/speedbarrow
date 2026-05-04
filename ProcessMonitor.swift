import Foundation
import Combine

struct AppNetworkUsage: Identifiable {
    let id: String
    let name: String
    var liveSpeedIn: Double
    var liveSpeedOut: Double
    var totalBytesIn: Double
    var totalBytesOut: Double
}

@MainActor
class ProcessMonitor: ObservableObject {
    @Published var topApps: [AppNetworkUsage] = []
    @Published var systemLiveIn: Double = 0
    @Published var systemLiveOut: Double = 0
    
    private var timer: Timer?
    private var prevSystemIn: Double = 0
    private var prevSystemOut: Double = 0
    private var lastUpdate: Date = Date()
    
    private var previousSnapshot: [String: (Double, Double)] = [:]
    private var accumulatedTotals: [String: (Double, Double)] = [:]
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task {
                await self?.updateAllStats()
            }
        }
    }
    
    private func updateAllStats() async {
        await updateSystemStats()
        await updateAppStats()
    }
    
    private func updateSystemStats() async {
        let output = await runCommand("/usr/sbin/netstat", arguments: ["-ibn"])
        guard let output = output else { return }
        let lines = output.components(separatedBy: .newlines)
        var totalIn: Double = 0
        var totalOut: Double = 0
        var seen: Set<String> = []
        for line in lines {
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard parts.count >= 10 else { continue }
            let iface = parts[0]
            if (iface.hasPrefix("en") || iface.hasPrefix("ap") || iface.hasPrefix("wi")) && !seen.contains(iface) {
                if line.contains("<Link") {
                    if let ib = Double(parts[6]), let ob = Double(parts[9]) {
                        totalIn += ib
                        totalOut += ob
                        seen.insert(iface)
                    }
                }
            }
        }
        let now = Date()
        let deltaT = now.timeIntervalSince(lastUpdate)
        if deltaT > 0 && prevSystemIn > 0 {
            self.systemLiveIn = max(0, (totalIn - prevSystemIn) / deltaT)
            self.systemLiveOut = max(0, (totalOut - prevSystemOut) / deltaT)
        }
        prevSystemIn = totalIn
        prevSystemOut = totalOut
        lastUpdate = now
    }
    
    private func updateAppStats() async {
        // Run the most basic nettop command
        let output = await runCommand("/usr/bin/nettop", arguments: ["-P", "-L", "1", "-n"])
        guard let output = output, !output.isEmpty else { return }
        
        let lines = output.components(separatedBy: .newlines)
        var currentMap: [String: (Double, Double)] = [:]
        
        for line in lines {
            let parts = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count < 6 { continue }
            
            // nettop columns are usually: 
            // 0: time (skip if it contains :)
            // 1: process name
            // 2: interface
            // 3: state
            // 4: rx_bytes
            // 5: tx_bytes
            
            var nameIndex = 0
            if parts[0].contains(":") { nameIndex = 1 } // Skip timestamp
            
            let namePart = parts[nameIndex]
            if namePart.isEmpty || namePart.lowercased().contains("process") || namePart == "time" { continue }
            
            let name = namePart.components(separatedBy: ".").first ?? namePart
            if name == "SpeedBarrow" { continue }
            
            // Find rx/tx by looking for the largest numeric columns (usually indices 4 and 5)
            // We search columns from index 2 to 7 to find the first two numbers
            var bytes: [Double] = []
            for i in (nameIndex + 1)..<min(parts.count, 10) {
                if let val = Double(parts[i]) {
                    bytes.append(val)
                    if bytes.count == 2 { break }
                }
            }
            
            if bytes.count == 2 {
                let existing = currentMap[name] ?? (0, 0)
                currentMap[name] = (existing.0 + bytes[0], existing.1 + bytes[1])
            }
        }
        
        var apps: [AppNetworkUsage] = []
        for (name, raw) in currentMap {
            let prev = previousSnapshot[name] ?? (raw.0, raw.1)
            let deltaIn = max(0, raw.0 - prev.0)
            let deltaOut = max(0, raw.1 - prev.1)
            
            let total = accumulatedTotals[name] ?? (0, 0)
            let newTotal = (total.0 + deltaIn, total.1 + deltaOut)
            accumulatedTotals[name] = newTotal
            
            // Show any app that has any historical activity or any live activity
            if newTotal.0 > 0 || newTotal.1 > 0 || deltaIn > 0 || deltaOut > 0 {
                apps.append(AppNetworkUsage(
                    id: name,
                    name: name,
                    liveSpeedIn: deltaIn / 2.0,
                    liveSpeedOut: deltaOut / 2.0,
                    totalBytesIn: newTotal.0,
                    totalBytesOut: newTotal.1
                ))
            }
            previousSnapshot[name] = raw
        }
        
        // Sort by live speed, then total bytes
        self.topApps = apps.sorted {
            let sA = $0.liveSpeedIn + $0.liveSpeedOut
            let sB = $1.liveSpeedIn + $1.liveSpeedOut
            if sA != sB { return sA > sB }
            return ($0.totalBytesIn + $0.totalBytesOut) > ($1.totalBytesIn + $1.totalBytesOut)
        }
    }
    
    private func runCommand(_ path: String, arguments: [String]) async -> String? {
        return await Task.detached(priority: .userInitiated) {
            let task = Process()
            task.launchPath = path
            task.arguments = arguments
            let pipe = Pipe()
            task.standardOutput = pipe
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                return String(data: data, encoding: .utf8)
            } catch {
                return nil
            }
        }.value
    }
}
