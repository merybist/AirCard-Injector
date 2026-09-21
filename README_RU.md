# AirCard Injector (Фикс пейринга для iOS 26+)

<p align="center">
  <img src="assets/app_icon_1024.png" width="128" height="128" alt="AirCard Injector Icon" />
</p>

<p align="center">
  <b>Нативная утилита для macOS, позволяющая обойти ограничения on-device пейринга на iOS 26 и автоматически вшить сертификаты авторизации в AirCard-iOS.</b>
</p>

<p align="center">
  <a href="README.md">🇬🇧 English Documentation</a> •
  <a href="#быстрый-старт">Быстрый старт</a> •
  <a href="#в-чём-проблема-на-ios-26">Суть проблемы на iOS 26</a> •
  <a href="#благодарности-и-авторы-credits">Благодарности (Credits)</a>
</p>

---

## ⚡ В чём проблема на iOS 26?

Приложение [AirCard-iOS](https://github.com/Mak5er/AirCard-iOS) позволяет менять обложки и кастомизировать дизайн банковских карт в Apple Wallet без джейлбрейка, используя петлевое VPN-соединение (`LocalDevVPN` или WireGuard в `SideStore`).

Однако **на iOS 26 беспроводной on-device пейринг в Developer Mode физически не работает**:
- При попытке спаривания через `remotepairingd` на порт 49152 соединение мгновенно разрывается: `Connection reset by peer` (`TunnelFailurePairVerify`).
- Устройство отклоняет попытки верификации через loopback (`only device-initiated pair-setup is supported`).

### 💡 Решение

Вместо нестабильного RPPairing, **AirCard Injector** использует штатный протокол **Lockdown Pairing Record** (работающий по порту `62078` через локальный VPN):
1. Вы один раз подключаете iPhone к Mac по кабелю и нажимаете спаривание через встроенный `idevice_pair`.
2. Извлекается официальный сертификатный файл со всеми криптографическими ключами.
3. AirCard Injector автоматически вшивает `pairingFile.plist` внутрь Payload установочного пакета `AirCard-iOS.ipa`.
4. На выходе получается готовый `AirCard-Injected.ipa`, который сразу подключается к сервису без необходимости настраивать Developer Mode на самом телефоне!

---

## ✨ Возможности

- 🖥️ **Нативный macOS SwiftUI интерфейс**: Стильный, быстрый и отзывчивый дизайн.
- 🍏 **Universal Binary**: Скомпилирован под Apple Silicon (M1/M2/M3/M4) и процессоры Intel.
- 🔌 **Встроенный генератор ключей**: Запускает `idevice_pair` для спаривания по USB за несколько секунд без Xcode и платного аккаунта Apple Developer.
- 🔍 **Умный анализ файлов**: Автоматически проверяет валидность сертификатов (`alt_irk`, `DeviceCertificate`, `HostPrivateKey`).
- 📦 **Автоматическая инжекция**: Патчит IPA на лету, не нарушая целостность бандла.
- 🚀 **Совместимость**: Работает с **SideStore**, **LiveContainer**, **TrollStore**, **AltStore** и **iLoader**.

---

## 🚀 Быстрый старт

### 1. Скачивание
Скачайте готовый `AirCardInjector.dmg` со страницы [**Releases**](https://github.com/merybist/AirCard-Injector/releases), откройте его и перетащите `AirCardInjector.app` в папку «Программы» (Applications).

### 2. Пейринг по кабелю
1. Подключите iPhone к Mac через провод Lightning / USB-C.
2. На экране iPhone выберите **«Доверять этому компьютеру»** и введите код-пароль разблокировки.
3. В приложении AirCard Injector нажмите синюю кнопку **«Launch Key Generator (idevice_pair)»**.
4. Завершите спаривание в один клик. Программа автоматически обнаружит сгенерированный файл!

### 3. Выбор базового IPA
В блоке Step 2 укажите путь к оригинальному `AirCard-iOS.ipa` (или нажмите *Download Latest Release from GitHub*).

### 4. Инжекция и установка
1. Нажмите кнопку **«Inject Pairing & Generate IPA»**.
2. Установите полученный файл `AirCard-Injected.ipa` на iPhone через SideStore, LiveContainer, TrollStore или AltStore.
3. Включите петлевой VPN (`LocalDevVPN` или SideStore WireGuard), запустите AirCard и меняйте обложки карт в Wallet!

---

## 🛠️ Сборка из исходников

Требования:
- macOS 14.0 или новее
- Xcode Command Line Tools (`xcode-select --install`)
- Опционально: `create-dmg` (`brew install create-dmg`)

Сборка:
```bash
git clone https://github.com/merybist/AirCard-Injector.git
cd AirCard-Injector

# Сборка Universal binary и оформленного DMG
./scripts/build_dmg.sh
```
Готовый образ появится по пути `build/AirCardInjector.dmg`.

---

## 🤝 Благодарности и авторы (Credits)

Огромная благодарность разработчикам и проектам, благодаря которым это стало возможным:

* **[@merybist](https://github.com/merybist)** — Создатель и разработчик AirCard Injector, реверс-инжиниринг протокола пейринга на iOS 26, интеграция Lockdown, разработка macOS GUI и релизного DMG пайплайна.
* **[@Mak5er](https://github.com/Mak5er)** — Автор оригинального проекта **[AirCard-iOS](https://github.com/Mak5er/AirCard-iOS)**, создавший фундаментальный механизм подмены обложек Apple Wallet.
* **[Команда libimobiledevice / idevicepair](https://libimobiledevice.org/)** (*Nikias Bassen и др.*) — Авторы ключевой библиотеки `libimobiledevice` и утилиты `idevicepair`, обеспечивших надёжное USB-сопряжение с устройствами iOS.
* **[@0xjohnnydev](https://github.com/0xjohnnydev)** / **AirLift** — Исследования петлевых туннелей на iOS.

---

## 📄 Лицензия

Проект распространяется под лицензией [MIT](LICENSE).
