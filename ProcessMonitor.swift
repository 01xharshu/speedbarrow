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
        let output = await runCommand("/usr/sbin/netstat", arguments: ["-ib"])
        guard let output = output else { return }
        
        let lines = output.components(separatedBy: .newlines)
        var totalIn: Double = 0
        var totalOut: Double = 0
        
        for line in lines {
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.contains("en0") || parts.contains("en1") {
                if parts.count >= 10 {
                    if let ibytes = Double(parts[6]), let obytes = Double(parts[9]) {
                        totalIn += ibytes
                        totalOut += obytes
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
        // Run nettop with -P (per-process) and -L 1 (one sample)
        let output = await runCommand("/usr/bin/nettop", arguments: ["-P", "-L", "1", "-n"])
        guard let output = output, !output.isEmpty else { return }
        
        let lines = output.components(separatedBy: .newlines)
        var currentMap: [String: (Double, Double)] = [:]
        
        // Find column indices from header
        var rxIndex = 4 // default
        var txIndex = 5 // default
        
        if let header = lines.first {
            let cols = header.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            if let ri = cols.firstIndex(of: "rx_bytes") { rxIndex = ri }
            if let ti = cols.firstIndex(of: "tx_bytes") { txIndex = ti }
        }
        
        for line in lines.dropFirst() {
            let parts = line.components(separatedBy: ",")
            if parts.count <= max(rxIndex, txIndex) { continue }
            
            let namePart = parts[0]
            if namePart.isEmpty || namePart == "time" { continue }
            
            let name = namePart.components(separatedBy: ".").first ?? namePart
            if name == "SpeedBarrow" || name == "process-name" { continue }
            
            if let rx = Double(parts[rxIndex]), let tx = Double(parts[txIndex]) {
                let existing = currentMap[name] ?? (0, 0)
                currentMap[name] = (existing.0 + rx, existing.1 + tx)
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
            
            // Only add apps that have actually sent or received data in this session
            if newTotal.0 > 0 || newTotal.1 > 0 {
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
        
        // Sort by live activity, then by total
        self.topApps = apps.sorted {
            let sA = $0.liveSpeedIn + $0.liveSpeedOut
            let sB = $1.liveSpeedIn + $1.liveSpeedOut
            if sA != sB { return sA > sB }
            return ($0.totalBytesIn + $0.totalBytesOut) > ($1.totalBytesIn + $1.totalBytesOut)
        }
    }
    
    private func runCommand(_ path: String, arguments: [String]) async -> String? {
        return await Task.detached(priority: .background) {
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
