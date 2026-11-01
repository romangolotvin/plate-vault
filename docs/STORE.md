# Публикация Plate Vault в Google Play и App Store

Чеклист, чтобы первая загрузка в магазины прошла с меньшим числом отказов.

## Общие идентификаторы

| Платформа | ID |
|-----------|-----|
| Android `applicationId` | `com.platevault.app` |
| iOS Bundle ID | `com.platevault.app` |
| Версия | из `pubspec.yaml` (`x.y.z+build`) |

Не меняйте package / bundle после первой публикации без крайней необходимости.

## Google Play

1. Создайте приложение в [Play Console](https://play.google.com/console).
2. Сгенерируйте upload keystore (храните вне git):
   ```bash
   keytool -genkey -v -keystore E:\dev\keys\plate-vault-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias platevault
   ```
3. Подключите signing в `android/app/build.gradle.kts` (сейчас стоит debug signing для разработки).
4. Соберите App Bundle:
   ```bash
   set PUB_CACHE=E:\dev\pub-cache
   E:\dev\flutter\bin\flutter.bat build appbundle --release
   ```
5. Заполните Data safety, Privacy policy URL, content rating, скриншоты phone + 7" / 10" при необходимости.
6. Укажите разрешения камеры/фото с обоснованием (OCR госномеров).

## App Store

1. Создайте App ID `com.platevault.app` в Apple Developer.
2. Создайте приложение в App Store Connect.
3. Privacy Nutrition Labels + usage strings уже в `ios/Runner/Info.plist` (см. также [IOS.md](IOS.md)).
4. В Xcode выберите Team для `ios/Runner.xcworkspace`.
5. Пропишите `teamID` в `ios/ExportOptions.plist`.
6. Соберите на macOS:
   ```bash
   ./build-ipa.sh
   # или: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
   ```
7. Загрузите через Transporter / Xcode Organizer / TestFlight.
8. После публикации подставьте числовой App Store ID в `lib/core/constants.dart` (`appStoreId`).

## Переход с GitHub Updates на магазины

Сейчас в настройках используется `GithubReleaseUpdateService`.

После публикации замените в `lib/app_state.dart` конструктор:

```dart
AppState({UpdateService? updateService})
  : updateService = updateService ?? StoreUpdateService();
```

И пропишите реальные URL в `lib/core/constants.dart` (`playStoreUrl`, `appStoreUrl`).

## Firebase перед продом

1. `dart pub global activate flutterfire_cli`
2. `flutterfire configure --project=YOUR_PROJECT`
3. Включите Email/Password в Authentication.
4. Задеплойте правила из `firebase/firestore.rules`.
