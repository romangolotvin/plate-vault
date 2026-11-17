"""Application bootstrap."""

from __future__ import annotations

import os
import sys

from PySide6.QtWidgets import QApplication

from . import config as cfg
from .audio import ensure_bubble_sound, get_sound_bus
from .config import ensure_data_dirs
from .theme import build_stylesheet
from .ui.main_window import MainWindow


def _prepare_assets() -> None:
    ensure_data_dirs()
    ensure_bubble_sound()
    # Generate hero / icons if missing
    try:
        from .assets_gen import generate_all

        generate_all()
    except Exception:
        pass


def run() -> int:
    # Allow headless import/tests; GUI needs display
    if os.environ.get("OCULUS_HEADLESS") == "1":
        return 0

    _prepare_assets()
    app = QApplication(sys.argv)
    app.setApplicationName(cfg.APP_NAME)
    app.setOrganizationName(cfg.APP_ORG)
    app.setStyle("Fusion")
    app.setStyleSheet(build_stylesheet())

    # Warm up sound bus
    get_sound_bus()

    window = MainWindow()
    window.show()
    window.bootstrap_permissions()
    return app.exec()
