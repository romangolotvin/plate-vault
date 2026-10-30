# Plate Vault

Мобильное приложение (Android + iOS) для коллекции **госномеров** любых стран:

- ручной ввод и OCR с камеры/галереи;
- оценка редкости;
- локальный аккаунт или Firebase Auth;
- публичный показ коллекции;
- проверка обновлений через GitHub Releases (с заделом под Play / App Store).

## Расположение на диске

Проект и toolchain рассчитаны на диск **E:** (на C: мало места):

| Что | Путь |
|-----|------|
| Проект | `E:\dev\plate-vault` |
| Flutter SDK | `E:\dev\flutter` |
| Pub cache | `E:\dev\pub-cache` |

```powershell
$env:Path = "E:\dev\flutter\bin;$env:Path"
$env:PUB_CACHE = "E:\dev\pub-cache"
cd E:\dev\plate-vault
flutter pub get
flutter run
```

## Идентификаторы для магазинов

- Android: `com.platevault.app`
- iOS: `com.platevault.app`

Чеклист публикации: [docs/STORE.md](docs/STORE.md).

## Firebase (опционально)

Пока ключи-плейсхолдеры в `lib/firebase_options.dart` — приложение работает **офлайн**.

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

Затем задеплойте правила из `firebase/firestore.rules`.

## Автообновление

1. Создайте GitHub-репозиторий и пропишите `githubOwner` / `githubRepo` в `lib/core/constants.dart`.
2. Соберите APK / создайте Release (workflow: `.github/workflows/android-release.yml`).
3. В приложении: **Настройки → Проверить обновления**.
4. После публикации в магазинах переключитесь на `StoreUpdateService` (см. STORE.md).

## Структура

```
lib/
  core/           theme, constants, update
  data/           models, rarity, ocr, repositories
  features/       auth, collection, scan, public, settings
```
