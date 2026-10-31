# Plate Vault 1.3.0 — Street trust + dual leaderboards

## Anti-cheat / trust
- **Street** — live in-app camera capture; qualifies for Street leaderboard
- **Unverified / неквалифицированный** — manual entry or gallery; stays in collection, marked, no Street score
- Trust flag stored on every `CollectionItem`

## Leaderboards
1. **Street** — only Street-verified plates, by portfolio value
2. **Неквалифицированный** — all plates (manual/gallery included)
- Local-first; publishes to Firestore when Firebase is configured

## Also in this build
- Folklore valuation tiers: МЕР+777+MSK/SPB = top tier; mirrors+Caucasus ≈ ~70k; price breakdown UI
- In-app OTA: download + progress + FileProvider install (no browser)
- Juicier UI: springy tabs, plate shine, rarity pulse, value count-up, celebrations, enter animations
- Collection: Street vs all worth, sort/filter, favorites, showcase, achievements, duplicate detect, share card
- Expanded RU folklore/security/admin series + region hints; thicker GOST glyphs

## Install / OTA
1. Install this APK (or update from **Настройки → Проверить обновления**)
2. Allow install from this source if Android asks
3. Later updates download inside the app — no Chrome / browser cache
