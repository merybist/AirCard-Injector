# AirCard Injector (iOS 26+ Pairing Fix)

<p align="center">
  <img src="assets/app_icon_1024.png" width="128" height="128" alt="AirCard Injector Icon" />
</p>

<p align="center">
  <b>Native macOS companion tool to bypass iOS 26 on-device pairing limitations and inject valid pairing credentials into AirCard-iOS.</b>
</p>

<p align="center">
  <a href="README_RU.md">🇷🇺 Документация на русском</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#the-problem-on-ios-26">Why This Is Needed</a> •
  <a href="#credits--acknowledgements">Credits</a>
</p>

---

## ⚡ The Problem on iOS 26

[AirCard-iOS](https://github.com/Mak5er/AirCard-iOS) lets you replace and customize your Apple Wallet cards on iOS without a jailbreak using loopback VPN tunneling (`LocalDevVPN` / `SideStore WireGuard`). 

However, **on iOS 26, on-device Developer Mode pairing is non-existent or permanently broken**:
- Attempting on-device pairing via `remotepairingd` (port 49152) fails with `Connection reset by peer` (`TunnelFailurePairVerify`).
- The device rejects local loopback pair-verification (`only device-initiated pair-setup is supported`).

### 💡 The Solution

Instead of broken on-device RPPairing, **AirCard Injector** uses the official **Lockdown Pairing Record** (running on port `62078` through the loopback VPN):
1. Pairs your iPhone with your Mac once via USB using bundled `idevice_pair`.
2. Extracts the official lockdown record containing certificates and cryptographic identity.
3. Automatically embeds and patches `pairingFile.plist` directly into the `AirCard-iOS.ipa` bundle.
4. Generates a ready-to-sideload `AirCard-Injected.ipa` that connects instantly without requiring Developer Mode on-device setup!

---

## ✨ Features

- 🖥️ **Native macOS SwiftUI App**: Clean, responsive interface built with Apple Human Interface Guidelines in mind.
- 🍏 **Universal Binary**: Fully optimized for both Apple Silicon (M1/M2/M3/M4) and Intel Macs.
- 🔌 **Built-in Pairing Helper**: Launches `idevice_pair` to pair with your iPhone over USB in seconds without Xcode or a paid Apple Developer account.
- 🔍 **Real-time Inspection**: Inspects and validates plists on the fly, verifying `alt_irk`, `DeviceCertificate`, and `HostPrivateKey`.
- 📦 **Automated Payload Patcher**: Re-packages and injects the plist into the IPA's Document and App bundle targets cleanly without breaking bundle signatures.
- 🚀 **Sideload Ready**: Compatible with **SideStore**, **LiveContainer**, **TrollStore**, **AltStore**, and **iLoader**.

---

## 🚀 Quick Start

### 1. Download or Build
Download the latest `AirCardInjector.dmg` from the [**Releases**](https://github.com/merybist/AirCard-Injector/releases) page, open it, and drag `AirCardInjector.app` to your Applications folder.

### 2. Pair iPhone via USB
1. Connect your iPhone to your Mac with a USB / Lightning / USB-C cable.
2. If prompted on the iPhone, tap **Trust This Computer** and enter your passcode.
3. In AirCard Injector, click **Launch Key Generator (idevice_pair)**.
4. Complete the one-click pairing prompt. Your fresh pairing record is automatically detected!

### 3. Select Base IPA
1. Under Step 2, select your base `AirCard-iOS.ipa` (or click *Download Latest Release from GitHub* to fetch the latest official build).

### 4. Inject and Install
1. Click **Inject Pairing & Generate IPA**.
2. Sideload the resulting `AirCard-Injected.ipa` to your iPhone using SideStore, LiveContainer, TrollStore, or AltStore.
3. On your iPhone, enable your loopback VPN (`LocalDevVPN` or `SideStore WireGuard`), launch AirCard, and enjoy Apple Wallet customization!

---

## 🛠️ Building from Source

Requirements:
- macOS 14.0 or later
- Xcode Command Line Tools (`xcode-select --install`)
- Optional: `create-dmg` (`brew install create-dmg`) for DMG packaging

Clone and build:
```bash
git clone https://github.com/merybist/AirCard-Injector.git
cd AirCard-Injector

# Build Universal binary and styled DMG
./scripts/build_dmg.sh
```
The compiled DMG will be generated in `build/AirCardInjector.dmg`.

---

## 🤝 Credits & Acknowledgements

Special thanks and appreciation to the authors and projects that made this possible:

* **[@merybist](https://github.com/merybist)** — Creator & maintainer of AirCard Injector, reverse-engineering iOS 26 pairing architecture, lockdown integration fix, macOS GUI tool & DMG distribution.
* **[@Mak5er](https://github.com/Mak5er)** — Creator of the core **[AirCard-iOS](https://github.com/Mak5er/AirCard-iOS)** project, revolutionizing Apple Wallet card artwork customization.
* **[libimobiledevice / idevicepair](https://libimobiledevice.org/)** (*Nikias Bassen, et al.*) — Authors of `libimobiledevice` and the `idevicepair` protocol implementation enabling trusted USB communication with iOS devices.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
