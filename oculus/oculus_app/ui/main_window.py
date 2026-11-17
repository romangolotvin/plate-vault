"""Main application window."""

from __future__ import annotations

from PySide6.QtCore import Qt
from PySide6.QtGui import QIcon, QPixmap, QPainter, QColor
from PySide6.QtWidgets import QHBoxLayout, QMainWindow, QStackedWidget, QWidget, QMessageBox

from .. import config as cfg
from ..config import ensure_data_dirs, load_settings
from ..permissions import ensure_permissions, permissions_granted
from .pages.bruteforce import BruteforcePage
from .pages.home import HomePage
from .pages.loadtest import LoadTestPage
from .pages.recon import ReconPage
from .pages.reports import ReportsPage
from .pages.scanners import ScannersPage
from .pages.ssl_page import SslPage
from .pages.web_checks import WebChecksPage
from .sidebar import Sidebar


def _make_icon(color: str, letter: str) -> QIcon:
    pix = QPixmap(64, 64)
    pix.fill(Qt.GlobalColor.transparent)
    p = QPainter(pix)
    p.setRenderHint(QPainter.RenderHint.Antialiasing)
    p.setBrush(QColor(color))
    p.setPen(Qt.PenStyle.NoPen)
    p.drawRoundedRect(4, 4, 56, 56, 14, 14)
    p.setPen(QColor("white"))
    font = p.font()
    font.setBold(True)
    font.setPointSize(22)
    p.setFont(font)
    p.drawText(pix.rect(), Qt.AlignmentFlag.AlignCenter, letter)
    p.end()
    return QIcon(pix)


class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        ensure_data_dirs()
        self.setWindowTitle(f"{cfg.APP_NAME} {cfg.APP_VERSION}")
        self.resize(1180, 760)
        self.setMinimumSize(960, 640)

        central = QWidget()
        self.setCentralWidget(central)
        layout = QHBoxLayout(central)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        self.sidebar = Sidebar()
        icons = {
            "home": _make_icon(cfg.COLOR_ACCENT, "◉"),
            "recon": _make_icon("#2F6FED", "R"),
            "scanners": _make_icon("#355F9E", "S"),
            "web": _make_icon("#3D7EFF", "W"),
            "ssl": _make_icon("#4C8DFF", "T"),
            "bruteforce": _make_icon("#2A63D6", "B"),
            "loadtest": _make_icon("#1F4B9A", "N"),
            "reports": _make_icon("#163056", "O"),
        }
        items = []
        for key, label, _icon_key in cfg.NAV_SECTIONS:
            items.append((key, label, icons.get(key)))
        self.sidebar.set_items(items)
        self.sidebar.navigate.connect(self.show_page)
        layout.addWidget(self.sidebar)

        self.stack = QStackedWidget()
        layout.addWidget(self.stack, 1)

        self.pages: dict[str, QWidget] = {
            "home": HomePage(),
            "recon": ReconPage(),
            "scanners": ScannersPage(),
            "web": WebChecksPage(),
            "ssl": SslPage(),
            "bruteforce": BruteforcePage(),
            "loadtest": LoadTestPage(),
            "reports": ReportsPage(),
        }
        for key, page in self.pages.items():
            self.stack.addWidget(page)
        self.pages["home"].navigate.connect(self.show_page)

        self._page_index = {key: i for i, key in enumerate(self.pages.keys())}
        self.show_page("home")
        self._apply_permissions_state()

    def _apply_permissions_state(self) -> None:
        enabled = permissions_granted()
        for page in self.pages.values():
            if hasattr(page, "set_modules_enabled"):
                page.set_modules_enabled(enabled)

    def show_page(self, key: str) -> None:
        idx = self._page_index.get(key)
        if idx is None:
            return
        self.stack.setCurrentIndex(idx)
        self.sidebar.select(key)

    def bootstrap_permissions(self) -> None:
        ok = ensure_permissions(self)
        self._apply_permissions_state()
        if not ok:
            QMessageBox.warning(
                self,
                "Oculus",
                "Без разрешений модули останутся неактивны. "
                "Перезапустите приложение, чтобы пройти мастер снова.",
            )
        else:
            settings = load_settings()
            if settings.get("permissions_accepted"):
                self.statusBar().showMessage("Разрешения выданы · модули активны", 5000)
