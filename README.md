# SpeedBarrow 🚀

SpeedBarrow is a premium macOS utility to monitor your network speed directly from your menu bar or in a beautiful dashboard.

## Features
- **Live Menu Bar Stats**: Alternates between Download and Upload speeds.
- **Testing Animation**: Live status feedback during speed tests.
- **Premium Dashboard**: Glassmorphic UI with gauges, latency stats, and history.
- **Smart Dock Behavior**: Stays in the menu bar; dock icon only appears when the window is open.
- **HTTP-based Testing**: Robust throughput measurements using global CDN endpoints.

## Tech Stack
- **SwiftUI**: For the modern, responsive UI.
- **AppKit**: For deep integration with the macOS Menu Bar (NSStatusItem).
- **Concurrency**: Swift async/await for non-blocking speed tests.

## How to Build
1. Open the project in Xcode.
2. Set the target to macOS 13.0+.
3. In `Info.plist`, ensure `Application is agent (UIElement)` is set to `YES` to start as a menu bar app.
4. Build and Run!

## Design
The app features a "liquid glass" aesthetic with vibrant gradients and smooth animations, fitting perfectly into the modern macOS Ventura/Sonoma ecosystem.
