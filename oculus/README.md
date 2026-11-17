# Oculus

Легальный desktop-тулбокс для авторизованного тестирования **своих** сайтов и инфраструктуры.

- GUI (не консоль), Windows `.exe` через PyInstaller
- Тёмно-синяя тема, выдвижное боковое меню с иконками
- Скруглённые кнопки, анимации нажатия, звук «пузыря»
- Мастер разрешений при первом запуске
- Модули: разведка, порты, веб (safe detect), SSL, брутфорс-словарь, нагрузка, отчёты

**Не включает:** DDoS на чужие системы, эксплойты, malware, C2.

## Стек

Python 3.12 + **PySide6** — быстрая разработка сетевых модулей и GUI на Linux/Windows, упаковка в `.exe` через PyInstaller.

## Запуск (dev)

```bash
cd oculus
pip install -r requirements.txt
python main.py
```

Whitelist по умолчанию: `localhost`, `127.0.0.1` (`~/.oculus/scope.json`).

## Сборка Windows exe

```bat
build_windows.bat
```

или:

```bash
pyinstaller --noconfirm --windowed --name Oculus --add-data "assets;assets" main.py
```

## Безопасность

Каждый сетевой модуль проверяет whitelist (`Scope.allows`). Нагрузка ограничена caps. SQLi/XSS — только detection (canary / error heuristics), без exploit payload.
