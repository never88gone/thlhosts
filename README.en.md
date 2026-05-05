# 🍡 THLHosts (Tanghulu Hosts)

[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20tvOS-blue?logo=apple)](https://developer.apple.com)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange?logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![TestFlight](https://img.shields.io/badge/TestFlight-Join%20Beta-blue?logo=apple)](https://testflight.apple.com/join/uB86FKvp)

**[中文](README.md)**

A fully local Hosts management tool for **iOS** and **tvOS**. It establishes a local VPN tunnel to intercept DNS queries based on your custom Hosts rules — no jailbreak required, completely offline, protecting your privacy and data security.

---

## 🧪 TestFlight Beta

Join the public beta to try the latest version:

**[➡️ Join TestFlight Beta](https://testflight.apple.com/join/uB86FKvp)**

---

## ✨ Features

- **DNS-level Hosts Interception**: Uses `NetworkExtension` Packet Tunnel to proxy DNS system-wide
- **Multi-configuration Management**: Create, edit, import, and switch between multiple Hosts config files
- **One-tap Toggle**: Start/stop the service instantly with the master switch
- **Remote URL Subscription**: Download and sync Hosts configs from a remote URL (e.g., neoHosts)
- **Local File Import**: Import `.hosts` / `.txt` files directly from the file system
- **tvOS QR Upload**: Built-in HTTP server — scan a QR code on your phone to upload configs to Apple TV
- **IPv6 Bypass Prevention**: Automatically intercepts `AAAA` queries for matched domains, forcing IPv4 fallback
- **Real-time Logs**: Built-in log panel to monitor DNS interception status in real time
- **Multilingual**: Supports Simplified Chinese and English
- **Multiple Themes**: Several built-in dark themes

---

## 📱 Platform Support

| Platform | Minimum Version | Notes |
|----------|----------------|-------|
| iOS / iPadOS | 16.0+ | iPhone with navigation, iPad with split view |
| tvOS | 16.0+ | Apple TV with QR code upload |

---

## 🏗 Project Structure

```
THLHOSTSApp/
├── Models/
│   ├── HostsFile.swift          # Data model
│   ├── HostsStorage.swift       # Persistent storage
│   └── HostsViewModel.swift     # Business logic ViewModel
├── NetworkExtension/
│   ├── PacketTunnelProvider.swift  # VPN core: DNS interception & forwarding
│   └── HostsManager.swift          # Extension internal management
├── Utils/
│   ├── HSBHostsManager.swift    # VPN configuration & launch management
│   └── HSBLogger.swift          # In-app logger
├── Views/SwiftUI/
│   ├── MainView.swift           # Main view (iOS SplitView / tvOS Stack)
│   ├── HostsListView.swift      # Config list
│   ├── HostsDetailView.swift    # Config detail & editor
│   ├── SettingsView.swift       # Settings page
│   └── LogView.swift            # Log panel
└── Resources/
    ├── zh-Hans.lproj/           # Simplified Chinese
    └── en.lproj/                # English
```

---

## 🔧 How It Works

```
User requests a domain
        │
        ▼
[System DNS Query] ──────────────────────────────────┐
        │                                            │
        ▼                                            │
[PacketTunnelProvider (Local VPN)]                   │
        │                                            │
        ├─ Hosts match (A record)  → Return custom IP ←──┘
        ├─ Hosts match (AAAA record) → Return empty (force IPv4 fallback)
        └─ No match → Forward to upstream DNS (default: 114.114.114.114)
```

> All traffic is processed locally on-device and never passes through any external server.

---

## 🚀 Build & Run

### Requirements

- Xcode 15+
- CocoaPods

### Steps

```bash
# Clone the repo
git clone <repo-url>
cd thlhosts

# Install dependencies
pod install

# Open the project in Xcode
open THLHOSTS.xcworkspace
```

### Xcode Configuration

You need to configure the following in Xcode:

1. **Bundle ID**: Update the Bundle Identifier for both the main App and NetworkExtension targets
2. **App Group**: Set the same App Group in both targets (format: `group.xxx.thlhosts`)
3. **Capabilities**:
   - Main App: `Personal VPN`, `App Groups`
   - Network Extension: `Network Extensions` (Packet Tunnel), `App Groups`
4. **Provisioning Profile**: Enable the above entitlements in the Apple Developer portal and download matching profiles

> ⚠️ VPN functionality requires a real device. `NetworkExtension` is not supported in the simulator.

---

## 📖 Usage

1. **Add Config**: Tap `+` in the top-right corner to create a local config, or subscribe to a remote Hosts list via URL
2. **Edit Config**: Tap a config item to view details, edit content directly or import from a file
3. **Activate Config**: Tap the dot on the left of a config item to enable/disable it (only one can be active at a time)
4. **Start Service**: Toggle the master switch to start the VPN service
5. **Verify Effect**: If interception doesn't take effect immediately, try toggling **Flight Mode** on and off to flush the system DNS cache

---

## 🤝 Contributing

Issues and Pull Requests are welcome!

1. Fork this repo
2. Create your branch (`git checkout -b feature/awesome-feature`)
3. Commit your changes (`git commit -m 'Add awesome feature'`)
4. Push to the branch (`git push origin feature/awesome-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🔒 Privacy Policy

Please see [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

---

## 📬 Contact

Feel free to open an Issue for any questions or feedback.
