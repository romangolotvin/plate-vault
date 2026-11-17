# Oculus — отчёт по этапам

## Этап 1. Архитектура — ✅

- Выбран стек: **Python 3.12 + PySide6** (GUI) + PyInstaller → Windows `.exe`
- Обоснование: быстрые сетевые модули, анимации/звуки Qt, сборка на Linux/Windows; WPF неудобен на Linux-агенте
- Структура: `oculus_app/{ui,modules,core}`, `assets/`, `tests/`, `ARCHITECTURE.md`

## Этап 2. Каркас GUI — ✅

- `MainWindow` + выдвижной `Sidebar` (иконки + подписи)
- Главный экран с крупными скруглёнными кнопками-разделами
- Тёмно-синяя тема (`theme.py`, палитра в `config.py`)
- Страницы: Разведка / Сканеры / Веб / SSL / Брутфорс / Нагрузка / Отчёты

## Этап 3. Анимации и звуки — ✅

- Кнопки `RoundedButton`: glow-анимация при press/release + визуальный pressed-offset
- Звук клика `assets/sounds/bubble_pop.wav` (генерируется автоматически)
- Переключатель sound в настройках первого запуска

## Этап 4. Модули — ✅

| Модуль | Статус | Примечание |
|--------|--------|------------|
| DNS / WHOIS(RDAP) / поддомены | ✅ | whitelist |
| Порт-сканер + banner | ✅ | rate/timeout |
| Веб: crawl, headers, SQLi/XSS **detect** | ✅ | без exploit payload |
| SSL/TLS аудит | ✅ | |
| Брутфорс словарь (Basic Auth) | ✅ | delay + cap + stop |
| Нагрузочный тест | ✅ | caps RPS/conc/duration, kill-switch |
| Отчёты HTML/JSON/PDF | ✅ | `~/.oculus/reports` |

## Этап 5. Разрешения при первом запуске — ✅

- `PermissionsDialog`: сеть + запись отчётов + юридическое подтверждение
- До согласия кнопки модулей **disabled**
- Флаг в `~/.oculus/settings.json`

## Проверки

- Smoke: import GUI offscreen, навигация по страницам
- `tests/test_scope_and_modules.py` — scope + portscan + report
- DNS localhost → HTML/JSON/PDF отчёт

## Сборка exe

На Windows: `oculus/build_windows.bat` → `dist/Oculus/Oculus.exe`
