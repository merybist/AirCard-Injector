# AirCard Injector — USB Pairing Helper for AirCard-iOS on iOS 26 and later

<p align="center">
  <img src="assets/app_icon_1024.png" width="128" height="128" alt="AirCard Injector icon" />
</p>

<p align="center">
  A small macOS companion for <a href="https://github.com/Mak5er/AirCard-iOS">AirCard-iOS</a>.<br>
  It creates a USB pairing record, finds the resulting <code>pairingFile.plist</code>, and places it in an AirCard IPA.
</p>

<p align="center">
  <a href="README_RU.md">🇷🇺 Инструкция на русском</a> •
  <a href="#demo">Demo</a> •
  <a href="#requirements">Requirements</a> •
  <a href="#how-to-use">How to use</a> •
  <a href="#troubleshooting">Troubleshooting</a>
</p>

---

## Why this exists

On iOS 26 and later, the Developer Mode **Pair on This iPhone** flow can be unavailable or fail for AirCard-iOS. AirCard Injector provides a macOS USB-based path for creating the pairing record needed by AirCard.

It uses [idevice_pair](https://github.com/jkcoxson/idevice_pair) by [@jkcoxson](https://github.com/jkcoxson), then packages the selected pairing file into an AirCard IPA.

## Demo

> **Placeholder — add a 20–30 second GIF here:** connect an iPhone by USB → click **Refresh** → launch the generator → pairing file is found → create the IPA. Blur device names and never show the contents of a pairing file.

## Requirements

- macOS 14 or later.
- An iPhone connected with a **data-capable USB cable**, unlocked, and trusted by the Mac.
- An original `AirCard-iOS.ipa`, either selected locally or downloaded from the release picker.
- A sideloading method for the generated IPA, such as SideStore, LiveContainer, TrollStore, or AltStore.

> **Placeholder — add a tested-compatibility table:** the iOS builds, AirCard-iOS versions, and Apple Silicon/Intel Macs you verified.

## How to use

1. Download `AirCardInjector.dmg` from [Releases](https://github.com/merybist/AirCard-Injector/releases), open it, and drag the app to `Applications`.
2. Connect and unlock your iPhone. Tap **Trust This Computer** if prompted.
3. In **Step 1**, confirm that AirCard Injector shows **iPhone connected via USB**. Click **Refresh** after reconnecting a cable or device.
4. Click **Launch Key Generator (idevice_pair)** and complete the USB pairing flow. AirCard Injector watches `Documents` and `Downloads` for a new pairing file; you can also choose one manually.
5. In **Step 2**, choose an AirCard-iOS release or select a local `.ipa`.
6. Click **Inject Pairing & Create Ready IPA**, choose where to save the result, then install that IPA with your preferred sideloading tool.

The original IPA is not overwritten: the save dialog creates a separate personalized IPA.

## Troubleshooting

| What you see | What to do |
| --- | --- |
| **No iPhone detected via USB** | Unlock the iPhone, use a data-capable cable, reconnect it, accept **Trust This Computer**, then click **Refresh**. |
| The generator opens but no pairing file is found | Complete the pairing flow in `idevice_pair`; then use **Browse…** to select the resulting `.plist` manually if it is not in `Documents` or `Downloads`. |
| No AirCard release appears | Choose **Custom .ipa…** and select an original local AirCard-iOS IPA. |
| Injection fails | Check that the selected IPA is a valid archive containing `Payload/*.app`, then retry with a newly saved output filename. |

## Privacy

A pairing file contains credentials tied to your device. Keep it private: do not attach it to issues, tweets, screenshots, or chat messages.

## Building from source

```bash
git clone https://github.com/merybist/AirCard-Injector.git
cd AirCard-Injector
./scripts/build_dmg.sh
```

The DMG is created at `build/AirCardInjector.dmg`.

## Credits

- [@Mak5er](https://github.com/Mak5er) — creator of [AirCard-iOS](https://github.com/Mak5er/AirCard-iOS).
- [@jkcoxson](https://github.com/jkcoxson) — creator of [idevice_pair](https://github.com/jkcoxson/idevice_pair).

## License

MIT. See [LICENSE](LICENSE).
