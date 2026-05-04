import SwiftUI
import AppKit

@main
struct SpeedBarrowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var processMonitor = ProcessMonitor()
    var mainWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Status Bar
        statusBarController = StatusBarController(processMonitor)
        
        // Listen for open window requests
        NotificationCenter.default.addObserver(self, selector: #selector(openMainWindow), name: Notification.Name("OpenMainWindow"), object: nil)
        
        // Ensure the app is activated and visible in the Dock
        NSApp.setActivationPolicy(.regular)
        
        // Open window automatically on launch
        openMainWindow()
    }
    
    @objc func openMainWindow() {
        if mainWindow == nil {
            let contentView = MainView(processMonitor: processMonitor)
            
            mainWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            mainWindow?.title = "SpeedBarrow"
            mainWindow?.center()
            mainWindow?.contentView = NSHostingView(rootView: contentView)
            mainWindow?.isReleasedWhenClosed = false
            mainWindow?.titlebarAppearsTransparent = true
            mainWindow?.titleVisibility = .hidden
            
            mainWindow?.delegate = self
        }
        
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Do not change activation policy here so it stays in dock, or just do nothing.
    }
}
