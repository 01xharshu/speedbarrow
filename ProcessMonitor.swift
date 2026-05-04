import Foundation
import Combine

struct AppNetworkUsage: Identifiable {
    let id: String // Process name
    let name: String
    var liveSpeedIn: Double // Bytes per second
    var liveSpeedOut: Double // Bytes per second
    var totalBytesIn: Double
    var totalBytesOut: Double
}

@MainActor
class ProcessMonitor: ObservableObject {
    @Published var topApps: [AppNetworkUsage] = []
    @Published var systemLiveIn: Double = 0
    @Published var systemLiveOut: Double = 0
    
    private var timer: Timer?
    
    // Track previous raw values to calculate speed (deltas)
    // Key: Process Name, Value: (bytesIn, bytesOut, timestamp)
    private var previousSnapshot: [String: (Double, Double, Date)] = [:]
    
    // Accumulate total bytes since SpeedBarrow started
    private var accumulatedTotals: [String: (Double, Double)] = [:]
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        // Update every 1 second for real-time feel
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task {
                await self?.updateUsage()
            }
        }
    }
    
    private func updateUsage() async {
        let task = Process()
        task.launchPath = "/usr/bin/nettop"
        task.arguments = ["-P", "-L", "1", "-m", "tcp", "-m", "udp"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                parseNettop(output)
            }
        } catch {
            print("Nettop error: \(error)")
        }
    }
    
    private func parseNettop(_ output: String) {
        let lines = output.components(separatedBy: .newlines)
        var currentRawMap: [String: (Double, Double)] = [:]
        let now = Date()
        
        var totalSystemInDelta: Double = 0
        var totalSystemOutDelta: Double = 0
        
        for line in lines {
            let parts = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 6 {
                let name = parts[0].components(separatedBy: ".").first ?? parts[0]
                if name == "time" || name == "SpeedBarrow" { continue } // Skip header and ourselves
                
                if let bytesIn = Double(parts[4]), let bytesOut = Double(parts[5]) {
                    let current = currentRawMap[name] ?? (0, 0)
                    currentRawMap[name] = (current.0 + bytesIn, current.1 + bytesOut)
                }
            }
        }
        
        var updatedApps: [AppNetworkUsage] = []
        
        for (name, currentRaw) in currentRawMap {
            let prev = previousSnapshot[name]
            var liveIn: Double = 0
            var liveOut: Double = 0
            
            if let prev = prev {
                let timeDelta = now.timeIntervalSince(prev.2)
                if timeDelta > 0 {
                    let deltaIn = max(0, currentRaw.0 - prev.0)
                    let deltaOut = max(0, currentRaw.1 - prev.1)
                    liveIn = deltaIn / timeDelta
                    liveOut = deltaOut / timeDelta
                    
                    totalSystemInDelta += deltaIn
                    totalSystemOutDelta += deltaOut
                    
                    let existingTotal = accumulatedTotals[name] ?? (0, 0)
                    accumulatedTotals[name] = (existingTotal.0 + deltaIn, existingTotal.1 + deltaOut)
                }
            } else {
                // First time seeing this process, don't calculate speed yet, just record total starting point
                accumulatedTotals[name] = (0, 0)
            }
            
            previousSnapshot[name] = (currentRaw.0, currentRaw.1, now)
            
            let total = accumulatedTotals[name] ?? (0, 0)
            
            let usage = AppNetworkUsage(
                id: name,
                name: name,
                liveSpeedIn: liveIn,
                liveSpeedOut: liveOut,
                totalBytesIn: total.0,
                totalBytesOut: total.1
            )
            updatedApps.append(usage)
        }
        
        // Clean up dead processes from tracking to save memory
        previousSnapshot = previousSnapshot.filter { currentRawMap.keys.contains($0.key) }
        
        // Update system live speeds based on the aggregated deltas over the polling interval
        self.systemLiveIn = totalSystemInDelta // since timer is ~1s, delta approx equals speed
        self.systemLiveOut = totalSystemOutDelta
        
        // Sort by highest live activity first, then by total consumed
        let sorted = updatedApps
            .filter { $0.totalBytesIn > 0 || $0.totalBytesOut > 0 || $0.liveSpeedIn > 0 || $0.liveSpeedOut > 0 }
            .sorted { 
                let speedA = $0.liveSpeedIn + $0.liveSpeedOut
                let speedB = $1.liveSpeedIn + $1.liveSpeedOut
                if speedA != speedB { return speedA > speedB }
                return ($0.totalBytesIn + $0.totalBytesOut) > ($1.totalBytesIn + $1.totalBytesOut)
            }
        
        self.topApps = sorted
    }
}
