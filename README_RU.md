# AirCard Injector — USB-помощник для AirCard-iOS на iOS 26 и новее

<p align="center">
  <img src="assets/app_icon_1024.png" width="128" height="128" alt="Иконка AirCard Injector" />
</p>

<p align="center">
  Небольшая macOS-утилита для <a href="https://github.com/Mak5er/AirCard-iOS">AirCard-iOS</a>.<br>
  Она создаёт pairing-запись по USB, находит <code>pairingFile.plist</code> и добавляет его в IPA AirCard.
</p>

<p align="center">
  <a href="README.md">🇬🇧 English version</a> •
  <a href="#демо">Демо</a> •
  <a href="#требования">Требования</a> •
  <a href="#как-пользоваться">Как пользоваться</a> •
  <a href="#решение-проблем">Решение проблем</a>
</p>

---

## Зачем это нужно

На iOS 26 и новее сценарий **Pair on This iPhone** в Developer Mode может быть недоступен или завершаться ошибкой для AirCard-iOS. AirCard Injector даёт macOS-путь через USB для создания pairing-записи, необходимой AirCard.

Утилита использует [idevice_pair](https://github.com/jkcoxson/idevice_pair) от [@jkcoxson](https://github.com/jkcoxson), затем упаковывает выбранный pairing-файл в IPA AirCard.

## Демо

<p align="center">
  <img src="https://github.com/merybist/merybist/blob/865efa28afb07cd3f5b4f9bbf6473852dcf642be/0923.gif?raw=true" alt="Демо AirCard Injector" width="640" />
</p>

## Требования

- macOS 14 или новее.
- iPhone, подключённый **кабелем с передачей данных**, разблокированный и доверяющий Mac.
- Оригинальный `AirCard-iOS.ipa`: его можно выбрать на диске или скачать через список релизов.
- Способ установить созданный IPA: SideStore, LiveContainer, TrollStore или AltStore.

## Проверенная совместимость

| Компонент | Проверенная конфигурация |
| --- | --- |
| iPhone | iPhone 14 Pro |
| iOS | 26.5.2 |
| AirCard-iOS | v1.3 |
| AirCard Injector | v2.0.1 |
| Mac | iMac (iMac19,1), Intel Core i5 |
| macOS | 15.7.7 |
| Архитектура | Intel (x86_64) |

## Как пользоваться

1. Скачай `AirCardInjector.dmg` из [Releases](https://github.com/merybist/AirCard-Injector/releases), открой образ и перетащи программу в `Applications`.
2. Подключи и разблокируй iPhone. Если появится запрос, нажми **Trust This Computer**.
3. В **Step 1** убедись, что приложение показывает **iPhone connected via USB**. После переподключения кабеля или телефона нажми **Refresh**.
4. Нажми **Launch Key Generator (idevice_pair)** и закончи pairing по USB. AirCard Injector следит за `Documents` и `Downloads`; pairing-файл также можно выбрать вручную.
5. В **Step 2** выбери релиз AirCard-iOS или локальный `.ipa`.
6. Нажми **Inject Pairing & Create Ready IPA**, выбери место сохранения и установи получившийся IPA привычным sideload-инструментом.

Исходный IPA не перезаписывается: окно сохранения создаёт отдельный персонализированный IPA.

## Решение проблем

| Что видно | Что сделать |
| --- | --- |
| **No iPhone detected via USB** | Разблокируй iPhone, используй кабель с передачей данных, переподключи устройство, подтверди **Trust This Computer** и нажми **Refresh**. |
| Генератор открылся, но pairing-файл не найден | Закончи pairing в `idevice_pair`; если файл не лежит в `Documents` или `Downloads`, выбери его вручную через **Browse…**. |
| В списке нет релиза AirCard | Нажми **Custom .ipa…** и выбери оригинальный локальный IPA AirCard-iOS. |
| Инъекция не удалась | Проверь, что IPA — корректный архив с `Payload/*.app`, затем повтори операцию, выбрав новое имя выходного файла. |

## Приватность

Pairing-файл содержит учётные данные, привязанные к устройству. Не публикуй его в issue, твитах, скриншотах или чатах.

## Сборка из исходников

```bash
git clone https://github.com/merybist/AirCard-Injector.git
cd AirCard-Injector
./scripts/build_dmg.sh
```

DMG появится по пути `build/AirCardInjector.dmg`.

## Благодарности

- [@Mak5er](https://github.com/Mak5er) — автор [AirCard-iOS](https://github.com/Mak5er/AirCard-iOS).
- [@jkcoxson](https://github.com/jkcoxson) — автор [idevice_pair](https://github.com/jkcoxson/idevice_pair).

## Лицензия

MIT. Подробнее — в [LICENSE](LICENSE).
