"""Home dashboard with big section buttons."""

from __future__ import annotations

from PySide6.QtCore import Signal
from PySide6.QtGui import QPixmap
from PySide6.QtWidgets import QGridLayout, QLabel, QVBoxLayout, QWidget

from ... import config as cfg
from ..widgets import HeroBanner, ModuleCardButton


class HomePage(QWidget):
    navigate = Signal(str)

    def __init__(self, parent=None) -> None:
        super().__init__(parent)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 16, 20, 16)
        layout.addWidget(
            HeroBanner(
                "Oculus",
                "Легальный тулбокс наблюдения и проверки для своих / whitelist целей.",
            )
        )

        art = QLabel()
        art.setMinimumHeight(140)
        banner = cfg.IMAGES_DIR / "hero_eye.png"
        if banner.exists():
            pix = QPixmap(str(banner))
            art.setPixmap(pix.scaledToWidth(720))
            art.setStyleSheet("border-radius: 16px;")
        else:
            art.setStyleSheet(
                f"background: qlineargradient(x1:0,y1:0,x2:1,y2:1,"
                f"stop:0 {cfg.COLOR_BG_ELEVATED}, stop:1 {cfg.COLOR_ACCENT});"
                "border-radius: 16px;"
            )
        layout.addWidget(art)

        grid = QGridLayout()
        grid.setSpacing(14)
        sections = [
            ("recon", "Разведка", "DNS, WHOIS, поддомены"),
            ("scanners", "Сканеры", "Порты и баннеры"),
            ("web", "Веб-проверки", "Заголовки, SQLi/XSS detect"),
            ("ssl", "SSL/TLS", "Сертификат и протоколы"),
            ("bruteforce", "Брутфорс", "Словарь с лимитами"),
            ("loadtest", "Нагрузка", "Контролируемый RPS"),
            ("reports", "Отчёты", "HTML / PDF / JSON"),
        ]
        self._cards: list[ModuleCardButton] = []
        for i, (key, title, desc) in enumerate(sections):
            card = ModuleCardButton(title, desc)
            card.clicked.connect(lambda k=key: self.navigate.emit(k))
            grid.addWidget(card, i // 2, i % 2)
            self._cards.append(card)
        layout.addLayout(grid)
        layout.addStretch(1)

    def set_modules_enabled(self, enabled: bool) -> None:
        # Home cards only navigate — always clickable so user can explore UI.
        # Actual module actions stay gated on section pages.
        _ = enabled
        for card in self._cards:
            card.setEnabled(True)
