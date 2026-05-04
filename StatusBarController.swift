import AppKit
import SwiftUI

@MainActor
class StatusBarController {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var processMonitor: ProcessMonitor
    private var timer: Timer?
    private var showDownload = true
    
    init(_ processMonitor: ProcessMonitor) {
        self.statusBar = NSStatusBar.system
        self.statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        self.processMonitor = processMonitor
        
        // Since PopoverView is now passive, we pass the monitor to it.
        // We'll update PopoverView next.
        let popoverView = PopoverView(processMonitor: processMonitor)
        self.popover.contentViewController = NSHostingController(rootView: popoverView)
        self.popover.behavior = .transient
        
        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusText()
            }
        }
    }
    
    private func updateStatusText() {
        guard let button = statusItem.button else { return }
        
        // Alternate every 3 seconds (3 frames of 1.0s)
        let frameCount = Int(Date().timeIntervalSince1970) % 6
        showDownload = frameCount < 3
        
        if showDownload {
            button.title = String(format: "↓ %@", formatSpeed(processMonitor.systemLiveIn))
        } else {
            button.title = String(format: "↑ %@", formatSpeed(processMonitor.systemLiveOut))
        }
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        let kbps = bytesPerSecond * 8 / 1000
        if kbps < 1000 { return String(format: "%.1f Kbps", kbps) }
        let mbps = kbps / 1000
        return String(format: "%.1f Mbps", mbps)
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}
