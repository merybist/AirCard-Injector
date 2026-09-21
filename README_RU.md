# AirCard Injector — Фикс для AirCard-iOS на iOS 26+

<p align="center">
  <img src="assets/app_icon_1024.png" width="128" height="128" alt="AirCard Injector Icon" />
</p>

<p align="center">
  <b>Готовый фикс для запуска <a href="https://github.com/Mak5er/AirCard-iOS">AirCard-iOS</a> на версиях iOS 26+.</b><br>
  Позволяет спарить iPhone по кабелю, извлечь рабочий файл сопряжения и вшить его прямо в IPA приложения AirCard, обходя ошибку пейринга в Developer Mode.
</p>

<p align="center">
  <a href="README.md">🇬🇧 English Version</a> •
  <a href="#в-чём-проблема-aircard-ios-на-ios-26">Суть проблемы</a> •
  <a href="#как-пользоваться">Как пользоваться</a> •
  <a href="#авторы">Авторы</a>
</p>

---

## ⚠️ В чём проблема: почему AirCard-iOS не работает на iOS 26+?

[AirCard-iOS](https://github.com/Mak5er/AirCard-iOS) — отличный проект от [@Mak5er](https://github.com/Mak5er), позволяющий менять дизайн карт в Apple Wallet без джейлбрейка.

Но **на iOS 26 и новее приложение стандартно не работает**:
- Встроенная функция беспроводного пейринга в Developer Mode (`Pair on This iPhone`) на iOS 26+ сломана или отсутствует.
- Приложение выдаёт бесконечные ошибки соединения (`Connection reset by peer`, `TunnelFailurePairVerify`).
- Без правильного файла сопряжения сканер карт не запускается, и обложки поменять невозможно.

---

## 💡 Как этот фикс решает проблему?

**AirCard Injector** — это утилита для macOS, которая решает проблему в несколько кликов:

1. **Один раз спаривает iPhone по проводу**: с помощью встроенного модуля `idevice_pair` от [@jkcoxson](https://github.com/jkcoxson).
2. **Забирает валидные ключи**: автоматически находит и проверяет сгенерированный `pairingFile.plist`.
3. **Вшивает файл прямо в AirCard-iOS**: берёт оригинальный `AirCard-iOS.ipa` и добавляет файлы авторизации внутрь пакета.
4. **Готовый результат**: на выходе получается пропатченный `AirCard-Injected.ipa`, который сразу видит карты через ваш локальный VPN (`LocalDevVPN` / `SideStore WireGuard`) без каких-либо ошибок!

---

## 🚀 Как пользоваться

### Шаг 1. Скачайте AirCard Injector
Скачайте образ **`AirCardInjector.dmg`** со страницы [**Releases**](https://github.com/merybist/AirCard-Injector/releases), откройте его и перетащите программу в папку `Applications` (Программы).

### Шаг 2. Подключите iPhone по кабелю
1. Подключите iPhone к Mac через провод Lightning / Type-C.
2. На экране телефона нажмите **«Доверять этому компьютеру»** и введите код разблокировки.
3. Откройте **AirCard Injector** и нажмите синюю кнопку **Launch Key Generator (idevice_pair)**.
4. Завершите сопряжение. Программа сама подхватит полученный файл ключей!

### Шаг 3. Выберите базовый IPA
В блоке Step 2 укажите оригинальный `AirCard-iOS.ipa` (или нажмите *Download Latest Release from GitHub*, чтобы скачать официальный билд).

### Шаг 4. Нажмите Inject и установите
1. Нажмите **Inject Pairing & Generate IPA**.
2. Установите готовый `AirCard-Injected.ipa` на телефон через **SideStore**, **LiveContainer**, **TrollStore** или **AltStore**.
3. Включите петлевой VPN (`LocalDevVPN` или SideStore WireGuard), откройте AirCard и спокойно меняйте обложки в Wallet!

---

## 🛠️ Сборка из исходников

```bash
git clone https://github.com/merybist/AirCard-Injector.git
cd AirCard-Injector
./scripts/build_dmg.sh
```
Готовый DMG появится в `build/AirCardInjector.dmg`.

---

## 🤝 Авторы

* **[@merybist](https://github.com/merybist)** — Создатель AirCard Injector, разработка фикса пейринга для iOS 26+, macOS приложение и DMG установщик.
* **[@Mak5er](https://github.com/Mak5er)** — Создатель **[AirCard-iOS](https://github.com/Mak5er/AirCard-iOS)**.
* **[@jkcoxson](https://github.com/jkcoxson)** — Автор утилиты **[idevice_pair](https://github.com/jkcoxson/idevice_pair)**.

---

## 📄 Лицензия

MIT License. Подробнее в файле [LICENSE](LICENSE).
