# Plate Vault — iOS

Flutter-проект уже общий для Android и iOS (`com.platevault.app`).  
IPA **нельзя** собрать на Windows/Linux — нужен macOS + Xcode.

## Как поставить себе на iPhone

Как с APK «скачал с GitHub и поставил» на iPhone **не получится** — Apple так не даёт.

Практичный путь для себя:

1. **Apple Developer** (платный аккаунт, ~$99/год) на [developer.apple.com](https://developer.apple.com).
2. На **Mac** открой проект, выбери Team, собери IPA:
   ```bash
   flutter pub get
   open ios/Runner.xcworkspace   # Signing → твой Team
   TEAM_ID=XXXXXXXXXX ./build-ipa.sh
   ```
3. Залей IPA в **App Store Connect → TestFlight** (Transporter или Xcode Organizer).
4. На iPhone поставь приложение **TestFlight** из App Store → прими приглашение → **Install**.

Без Mac можно попросить друга/CI с macOS собрать и залить в TestFlight — на телефон всё равно ставится через TestFlight.

Альтернативы без TestFlight (хуже для «просто себе»):

- **Development / Ad Hoc** профиль: устройство должно быть в списке UDID, установка через Xcode/Apple Configurator.
- **App Store** публично — после модерации.

Бесплатный sideload в стиле Android (просто `.ipa` с GitHub) для обычного iPhone без джейлбрейка не подходит.

## Быстрый старт (Mac)

```bash
cd plate-vault
flutter pub get
flutter test
open ios/Runner.xcworkspace
```

В Xcode → **Runner** → **Signing & Capabilities**:

1. Team = ваш Apple Developer Team  
2. Bundle ID = `com.platevault.app`  
3. Автоматический signing

Сборка IPA:

```bash
./build-ipa.sh
# или только проверка компиляции без подписи:
./build-ipa.sh --no-codesign
```

Готовый файл: `build/ios-dist/plate-vault-release.ipa`  
либо `build/ios/ipa/*.ipa`.

## Установка на iPhone

| Способ | Когда |
|--------|--------|
| **TestFlight** | Бета через App Store Connect (рекомендуется) |
| **App Store** | После модерации — пропишите `appStoreId` в `lib/core/constants.dart` |
| **Ad Hoc / Development** | Устройства в профиле; смените `method` в `ios/ExportOptions.plist` на `ad-hoc` / `development` |

Sideload как у Android-APK на iOS без аккаунта разработчика по сути недоступен.

## CI

Workflow `.github/workflows/ios.yml` на `macos-latest`:

- `flutter test` + `flutter analyze`
- `flutter build ios --release --no-codesign`
- артефакт `plate-vault-*-ios-unsigned.zip` (проверка сборки, **не** для установки)

Подписанный IPA в CI — только с секретами сертификатов/профилей (пока не подключены).

## Обновления в приложении

Пока `appStoreId = YOUR_APP_ID`, кнопка «Проверить обновления» на iOS открывает **GitHub Releases**.  
После публикации в App Store подставьте числовой ID — откроется страница Store.

## Разрешения (`ios/Runner/Info.plist`)

- Камера / фото — OCR номеров  
- Motion — античит «два ракурса»  
- `ITSAppUsesNonExemptEncryption = false` — стандартный export compliance  

## Firebase

В `lib/firebase_options.dart` сейчас placeholder iOS keys → offline mode.  
Перед продом: `flutterfire configure` (см. `docs/STORE.md`).
