# Plate Vault

Collector vault for **license plates** (Android + iOS): scan, rarity, folklore valuation, Street trust, dual leaderboards.

## Trust model (anti-cheat)

| Level | How you add | Portfolio flex | Street leaderboard |
|-------|-------------|----------------|--------------------|
| **Street** | Live in-app camera | Full | Counts |
| **Unverified** | Manual / gallery | Marked / limited share flex | Does **not** count |

Two boards: **Street** (verified only) and **Неквалифицированный** (all plates). Local-first; Firestore when configured.

## Valuation folklore (RUB hobby scale)

- Common civilian ≈ low thousands
- Mirrors + Caucasus / province ≈ **~70k** (Tier 1)
- **МЕР + 777 + MSK/SPB** = top tier (hundreds of thousands → millions), **not** ~70k
- In-app **price breakdown** (series · digits · region · combo)

## In-app OTA (Android)

**Настройки → Проверить обновления** → download with progress → FileProvider install.  
Needs `REQUEST_INSTALL_PACKAGES`. No browser.

## iOS

Сборка IPA только на **macOS + Xcode**. Подробно: [docs/IOS.md](docs/IOS.md).

```bash
flutter pub get
open ios/Runner.xcworkspace   # выберите Team (Signing)
./build-ipa.sh                # → build/ios-dist/plate-vault-release.ipa
```

CI: `.github/workflows/ios.yml` собирает unsigned `.app` zip на `macos-latest` (проверка компиляции).  
До App Store кнопка обновлений на iOS открывает GitHub Releases.

## Paths (E: toolchain)

| What | Path |
|------|------|
| Project | `E:\dev\plate-vault` |
| Flutter | `E:\dev\flutter` |
| Pub cache | `E:\dev\pub-cache` |
| Gradle | `E:\dev\gradle` |
| Release APK | `E:\dev\builds\plate-vault-release.apk` |
| Release IPA (Mac) | `build/ios-dist/plate-vault-release.ipa` |

```powershell
$env:Path = "E:\dev\flutter\bin;$env:Path"
$env:PUB_CACHE = "E:\dev\pub-cache"
$env:GRADLE_USER_HOME = "E:\dev\gradle"
cd E:\dev\plate-vault
flutter pub get
flutter test
flutter build apk --release
```

## IDs

- Android / iOS: `com.platevault.app`
- GitHub: `romangolotvin/plate-vault`

## Firebase (optional)

Placeholder keys in `lib/firebase_options.dart` → offline / local leaderboards.  
Configure with FlutterFire when ready; rules in `firebase/firestore.rules`.

## Structure

```
lib/
  core/           theme, OTA, plate widgets, share card, motion
  data/
    models/       CollectionItem + TrustLevel
    leaderboard/  Street + Unverified boards
    plates/       country visuals / OCR formats
    series/       RU folklore + CIS stubs
    valuation/    collector estimate
  features/       collection, scan, leaderboard, public, settings
```

See also: [docs/IOS.md](docs/IOS.md), [docs/PLATE_FONTS.md](docs/PLATE_FONTS.md), [docs/STORE.md](docs/STORE.md).
