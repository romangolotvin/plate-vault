# Plate Vault — iOS

Flutter-проект уже общий для Android и iOS (`com.platevault.app`).  
IPA **нельзя** собрать на Windows/Linux — нужен macOS + Xcode.

---

## Подробно: поставить себе на iPhone через Xcode (бесплатный Apple ID)

Платный Apple Developer **не нужен**. Нужны: **Mac**, **Xcode**, **кабель**, свой **Apple ID**.

Приложение с Personal Team живёт на телефоне **около 7 дней**, потом надо снова нажать Run в Xcode.

### 0. Один раз на Mac

1. Установи **Xcode** из App Store (большой, подожди загрузку).
2. Открой Xcode → согласись с лицензией → дождись установки доп. компонентов.
3. Установи Flutter и проверь:
   ```bash
   flutter doctor
   ```
   В списке должны быть галочки у **Xcode** и **CocoaPods**  
   (если нет pods: `brew install cocoapods` или `sudo gem install cocoapods`).
4. Клонируй/открой проект и **обязательно** подготовь iOS (не открывай Xcode раньше):
   ```bash
   cd ~/dev/plate-vault
   git pull
   chmod +x tool/ios_prepare.sh
   ./tool/ios_prepare.sh
   ```
   Скрипт сделает `flutter clean` → `pub get` → `pod install` → откроет workspace.

   Вручную то же самое:
   ```bash
   flutter clean && flutter pub get
   cd ios && pod install && cd ..
   open ios/Runner.xcworkspace
   ```

### Ошибка `Missing package product FlutterGeneratedPluginSwiftPackage`

Проект переведён на **CocoaPods** (SwiftPM выключен в `pubspec.yaml`).  
Если видишь эту ошибку — ты на старом checkout или открыл Xcode до `pod install`:

```bash
cd ~/dev/plate-vault
git pull origin cursor/ios-version-76f1
./tool/ios_prepare.sh
```

В Xcode: **File → Close Workspace**, затем снова открой **`ios/Runner.xcworkspace`** (не `.xcodeproj`).

### 1. Открой правильный файл в Xcode

```bash
open ios/Runner.xcworkspace
```

Важно: открывай **`Runner.xcworkspace`**, не `Runner.xcodeproj`.  
Если Xcode уже что-то открыл криво — File → Close Workspace, потом снова `open ios/Runner.xcworkspace`.

### 2. Добавь Apple ID в Xcode

1. Меню **Xcode → Settings…** (или Preferences…).
2. Вкладка **Accounts**.
3. Кнопка **+** слева внизу → **Apple ID** → войди своим Apple ID / паролем / 2FA.
4. В списке слева должен появиться аккаунт; справа — **Personal Team** (бесплатная команда).

### 3. Выбери телефон как цель сборки

1. Разблокируй iPhone, подключи **USB-кабель** к Mac.
2. На iPhone: **Доверять этому компьютеру?** → Доверять.
3. Вверху окна Xcode, слева от кнопки ▶, есть селектор устройства:
   - вместо `Any iOS Device` / симулятора выбери **свой iPhone** (имя телефона).
4. Если телефона нет в списке:
   - кабель/другой порт;
   - на iPhone: Настройки → Конфиденциальность и безопасность → Режим разработчика (iOS 16+) → включить и перезагрузить;
   - Window → Devices and Simulators → убедись, что iPhone виден.

### 4. Signing: Team и Bundle ID

В левой панели (Navigator):

1. Кликни синюю иконку проекта **Runner** (самый верхний пункт).
2. В средней колонке TARGETS выбери **Runner** (не RunnerTests).
3. Вкладка **Signing & Capabilities**.
4. Включи **Automatically manage signing**.
5. **Team** → выбери свой **Personal Team** (имя + Apple ID).
6. **Bundle Identifier** смени на уникальный, например:
   ```
   com.platevault.app.roman
   ```
   (бесплатный Personal Team часто **не даёт** занять чужой/общий id вроде `com.platevault.app` — будет ошибка provisioning).
7. Дождись, пока Xcode сам создаст Provisioning Profile.  
   Статус должен стать без красных ошибок: **Signing Certificate: Apple Development**.

Если красная ошибка:

| Сообщение | Что делать |
|-----------|------------|
| Failed to register bundle identifier | Смени Bundle ID на другой уникальный |
| Personal development teams do not support… | Убери лишние Capabilities; для Plate Vault обычно ничего сверх Signing не нужно |
| No devices registered | Подключи iPhone и выбери его целью (шаг 3) |
| Untrusted Developer на телефоне после установки | См. шаг 7 |

### 5. Deployment target (если спросит)

В том же TARGET **Runner** → вкладка **General**:

- **Minimum Deployments** / iOS → **15.5** (нужно для google_mlkit; ниже нельзя).

### 6. Сборка и установка на телефон

1. Вверху Xcode нажми **▶ Run** (или `Cmd + R`).
2. Первый раз может долго компилировать Flutter/плагины — жди.
3. Если Xcode пишет про Mac Keychain / codesign — разреши доступ (**Always Allow**).
4. Когда сборка зелёная, приложение **Plate Vault** появится на домашнем экране iPhone и само откроется (или открой иконку руками).

Из терминала вместо кнопки ▶ тоже можно (после настройки Signing в Xcode):

```bash
flutter devices          # должен быть твой iPhone
flutter run --release    # или без --release для отладки
```

### 7. Первый запуск на iPhone: доверие к разработчику

Если иконка есть, но приложение не открывается / «Ненадёжный разработчик»:

1. iPhone → **Настройки → Основные → VPN и управление устройством**  
   (на старых iOS: Основные → Профили и управление устройством).
2. В блоке **Разработчик** нажми свой Apple ID.
3. **Доверять** → подтверди.
4. Снова открой Plate Vault.

Камера: при первом скане iOS спросит доступ — разреши.

### 8. Через ~7 дней приложение «сломается»

Personal Team подпись **истекает**. Симптом: иконка есть, при открытии сразу закрывается / «больше не проверяется».

Что делать: снова подключи iPhone к Mac → Xcode → ▶ Run. Подпись обновится ещё на ~7 дней.

Платный Developer ($99/год) + TestFlight убирает этот лимит.

---

## Чеклист «если что-то красное в Xcode»

1. Открыт именно **`Runner.xcworkspace`**.
2. Сделан `flutter pub get` (и при необходимости `cd ios && pod install`).
3. Apple ID добавлен в **Xcode → Settings → Accounts**.
4. Target = **твой iPhone**, не симулятор (симулятор камеру/часть плагинов может не дать).
5. **Automatically manage signing** + **Personal Team**.
6. Bundle ID **уникальный** (`com.platevault.app.твоёимя`).
7. На iPhone включён **Режим разработчика** (iOS 16+).
8. После установки — **Доверять** профилю разработчика в Настройках.

---

## Платный путь (TestFlight / App Store)

Если позже купишь Apple Developer:

1. Team в Xcode = платный team (не Personal).
2. Bundle ID можно вернуть на `com.platevault.app`.
3. Сборка IPA:
   ```bash
   TEAM_ID=XXXXXXXXXX ./build-ipa.sh
   ```
4. Загрузка в App Store Connect → TestFlight → Install на iPhone через приложение TestFlight.

---

## Быстрые команды (Mac)

```bash
cd plate-vault
flutter pub get
flutter test
open ios/Runner.xcworkspace
# дальше Signing + ▶ Run — см. инструкцию выше

./build-ipa.sh              # только с платным Team + ExportOptions
./build-ipa.sh --no-codesign # только проверка компиляции
```

## Обновления в приложении

Пока `appStoreId = YOUR_APP_ID`, кнопка «Проверить обновления» на iOS открывает **GitHub Releases**.  
После публикации в App Store подставьте числовой ID в `lib/core/constants.dart`.

## Разрешения (`ios/Runner/Info.plist`)

- Камера / фото — OCR номеров  
- Motion — античит «два ракурса»  
- `ITSAppUsesNonExemptEncryption = false` — export compliance  

## Firebase

В `lib/firebase_options.dart` сейчас placeholder iOS keys → offline mode.  
Перед продом: `flutterfire configure` (см. `docs/STORE.md`).
