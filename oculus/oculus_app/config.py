"""Paths, constants, and persisted user settings for Oculus."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

APP_NAME = "Oculus"
APP_ORG = "OculusLab"
APP_VERSION = "0.1.0"

ROOT_DIR = Path(__file__).resolve().parent.parent
ASSETS_DIR = ROOT_DIR / "assets"
ICONS_DIR = ASSETS_DIR / "icons"
IMAGES_DIR = ASSETS_DIR / "images"
SOUNDS_DIR = ASSETS_DIR / "sounds"

# User data lives next to the app in portable mode, or under ~/.oculus
DATA_DIR = Path.home() / ".oculus"
SETTINGS_PATH = DATA_DIR / "settings.json"
REPORTS_DIR = DATA_DIR / "reports"
SCOPE_PATH = DATA_DIR / "scope.json"

# Dark-blue palette
COLOR_BG = "#0B1A33"
COLOR_BG_ELEVATED = "#122445"
COLOR_PANEL = "#163056"
COLOR_ACCENT = "#3D7EFF"
COLOR_ACCENT_HOVER = "#5B93FF"
COLOR_ACCENT_PRESS = "#2A63D6"
COLOR_TEXT = "#E8F0FF"
COLOR_TEXT_MUTED = "#9BB0D0"
COLOR_BORDER = "#2A4570"
COLOR_SUCCESS = "#3DDC97"
COLOR_WARN = "#F5C542"
COLOR_DANGER = "#FF6B7A"

# Load-test hard caps (own sites / authorized only)
LOAD_MAX_RPS = 50
LOAD_MAX_CONCURRENCY = 20
LOAD_MAX_DURATION_SEC = 120

# Bruteforce safety
BRUTE_MAX_ATTEMPTS_PER_MIN = 30
BRUTE_DEFAULT_DELAY_MS = 400

NAV_SECTIONS = [
    ("home", "Главная", "home"),
    ("recon", "Разведка", "recon"),
    ("scanners", "Сканеры", "scanner"),
    ("web", "Веб-проверки", "web"),
    ("ssl", "SSL/TLS", "ssl"),
    ("bruteforce", "Брутфорс", "lock"),
    ("loadtest", "Нагрузка", "gauge"),
    ("reports", "Отчёты", "report"),
]


def ensure_data_dirs() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)
    ICONS_DIR.mkdir(parents=True, exist_ok=True)
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)
    SOUNDS_DIR.mkdir(parents=True, exist_ok=True)


def load_settings() -> dict[str, Any]:
    ensure_data_dirs()
    if not SETTINGS_PATH.exists():
        return {
            "permissions_accepted": False,
            "network_allowed": False,
            "reports_write_allowed": False,
            "sound_enabled": True,
            "animations_enabled": True,
        }
    try:
        return json.loads(SETTINGS_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {
            "permissions_accepted": False,
            "network_allowed": False,
            "reports_write_allowed": False,
            "sound_enabled": True,
            "animations_enabled": True,
        }


def save_settings(data: dict[str, Any]) -> None:
    ensure_data_dirs()
    SETTINGS_PATH.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
