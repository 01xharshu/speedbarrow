import SwiftUI

struct PopoverView: View {
    @ObservedObject var processMonitor: ProcessMonitor
    
    var body: some View {
        VStack(spacing: 16) {
            header
            
            Divider()
            
            if processMonitor.topApps.isEmpty {
                Text("Analyzing traffic...")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(processMonitor.topApps.prefix(3)) { app in
                        HStack {
                            Text(app.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text(formatSpeed(app.liveSpeedIn + app.liveSpeedOut))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            Divider()
            
            actions
        }
        .padding()
        .frame(width: 250)
        .background(VisualEffectView(material: .popover, blendingMode: .withinWindow))
    }
    
    private var header: some View {
        HStack {
            Image(systemName: "network")
                .font(.title2)
                .foregroundColor(.blue)
            Text("SpeedBarrow")
                .font(.headline)
            Spacer()
        }
    }
    
    private var actions: some View {
        VStack(spacing: 8) {
            Button("Open Full Dashboard") {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.title == "SpeedBarrow" }) {
                    window.makeKeyAndOrderFront(nil)
                } else {
                    NotificationCenter.default.post(name: Notification.Name("OpenMainWindow"), object: nil)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        let kbps = bytesPerSecond * 8 / 1000
        if kbps < 1000 { return String(format: "%.1f Kbps", kbps) }
        let mbps = kbps / 1000
        return String(format: "%.1f Mbps", mbps)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
