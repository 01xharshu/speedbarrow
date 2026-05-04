import SwiftUI

struct MainView: View {
    @ObservedObject var processMonitor: ProcessMonitor
    
    var body: some View {
        VStack(spacing: 20) {
            header
            
            Divider()
            
            appUsageList
        }
        .padding(30)
        .frame(minWidth: 700, minHeight: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SpeedBarrow")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Network Activity Monitor")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 30) {
                VStack(alignment: .trailing) {
                    Text("LIVE DOWNLOAD")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Text(formatSpeed(processMonitor.systemLiveIn))
                        .font(.system(.title3, design: .monospaced))
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .trailing) {
                    Text("LIVE UPLOAD")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Text(formatSpeed(processMonitor.systemLiveOut))
                        .font(.system(.title3, design: .monospaced))
                        .foregroundColor(.purple)
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private var appUsageList: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack {
                Text("APPLICATION")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("LIVE USAGE (Speed)")
                    .frame(width: 200, alignment: .trailing)
                Text("SESSION TOTAL")
                    .frame(width: 150, alignment: .trailing)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    if processMonitor.topApps.isEmpty {
                        Text("Monitoring network traffic...")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(processMonitor.topApps) { app in
                            HStack {
                                HStack(spacing: 12) {
                                    Image(systemName: "app.fill")
                                        .foregroundColor(app.liveSpeedIn + app.liveSpeedOut > 1000 ? .green : .secondary)
                                    Text(app.name)
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("↓ \(formatSpeed(app.liveSpeedIn))")
                                        .foregroundColor(.blue)
                                    Text("↑ \(formatSpeed(app.liveSpeedOut))")
                                        .foregroundColor(.purple)
                                }
                                .font(.system(.caption, design: .monospaced))
                                .frame(width: 200, alignment: .trailing)
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(formatBytes(app.totalBytesIn + app.totalBytesOut))
                                        .fontWeight(.bold)
                                }
                                .font(.system(.subheadline, design: .monospaced))
                                .frame(width: 150, alignment: .trailing)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(Color.primary.opacity(0.03))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        let kbps = bytesPerSecond * 8 / 1000
        if kbps < 1000 { return String(format: "%.1f Kbps", kbps) }
        let mbps = kbps / 1000
        return String(format: "%.1f Mbps", mbps)
    }
    
    private func formatBytes(_ bytes: Double) -> String {
        let kb = bytes / 1024
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024
        if mb < 1024 { return String(format: "%.1f MB", mb) }
        let gb = mb / 1024
        return String(format: "%.1f GB", gb)
    }
}
