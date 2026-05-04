# 🚀 SpeedBarrow

A premium, high-performance macOS network activity monitor that lives in your menu bar and provides a high-fidelity dashboard of your app-by-app data usage.

![SpeedBarrow Icon](Assets.xcassets/AppIcon.appiconset/speedbarrow_app_icon_1777924928718%201.png)

## ✨ Features

- **Live Menu Bar Stats**: Real-time download and upload speeds at a glance.
- **Per-App Monitoring**: See exactly which apps are consuming your bandwidth.
- **Session Totals**: Track total data used during your current session.
- **Privacy Focused**: No data is saved to disk; everything is cleared when the app is closed.
- **Native & Lightweight**: Built with SwiftUI and optimized for macOS 13+.

## 📥 Installation & Setup

1. **Download**: Download the latest `SpeedBarrow.dmg` from the [Releases](https://github.com/YOUR_USERNAME/speedbarrow/releases) page.
2. **Install**: Open the `.dmg` and drag `SpeedBarrow` to your **Applications** folder.
3. **Open**: Double-click `SpeedBarrow` in your Applications folder.

---

### 🛡️ macOS Gatekeeper (Important)

Since SpeedBarrow is an independent project and not currently signed with an Apple Developer certificate, macOS will show a security warning when you first open it.

**Option 1: The Right-Click Method (Easiest)**
1. Locate the app in **Finder** (Applications folder).
2. **Right-click** (or Control-click) the app icon and select **Open**.
3. A similar dialog will appear, but this time it will have an **Open** button. Click it.

**Option 2: The Terminal Method (Advanced)**
If you prefer using the terminal, run the following command to remove the quarantine flag:
```bash
xattr -cr /Applications/SpeedBarrow.app
```

---

## 🛠️ Build from Source

If you want to build the app yourself:

1. Clone the repository.
2. Run the build script:
   ```bash
   ./build_app.sh
   ```
3. The `SpeedBarrow.app` bundle will be created in the root directory.

## 📄 License

MIT License - feel free to use and modify!
