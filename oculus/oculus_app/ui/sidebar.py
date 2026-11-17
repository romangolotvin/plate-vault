"""Collapsible left drawer with icons + labels."""

from __future__ import annotations

from PySide6.QtCore import QEasingCurve, QPropertyAnimation, Qt, Signal
from PySide6.QtGui import QIcon
from PySide6.QtWidgets import QFrame, QLabel, QPushButton, QVBoxLayout

from .. import config as cfg
from ..audio import get_sound_bus


class SidebarButton(QPushButton):
    def __init__(self, key: str, text: str, icon: QIcon | None = None, parent=None) -> None:
        super().__init__(text, parent)
        self.key = key
        self._full_text = text
        self.setCheckable(True)
        self.setCursor(Qt.CursorShape.PointingHandCursor)
        self.setMinimumHeight(44)
        self.setToolTip(text)
        if icon:
            self.setIcon(icon)
        self.setStyleSheet(
            f"""
            QPushButton {{
                text-align: left;
                padding: 10px 14px;
                border: none;
                border-radius: 12px;
                background: transparent;
                color: {cfg.COLOR_TEXT};
            }}
            QPushButton:hover {{
                background: {cfg.COLOR_PANEL};
            }}
            QPushButton:checked {{
                background: {cfg.COLOR_ACCENT};
                color: white;
            }}
            """
        )
        self.clicked.connect(lambda: get_sound_bus().play_click())


class Sidebar(QFrame):
    navigate = Signal(str)

    def __init__(self, parent=None) -> None:
        super().__init__(parent)
        self.setObjectName("Sidebar")
        self._expanded_width = 220
        self._collapsed_width = 72
        self._expanded = True
        self.setFixedWidth(self._expanded_width)

        self._layout = QVBoxLayout(self)
        self._layout.setContentsMargins(12, 16, 12, 16)
        self._layout.setSpacing(8)

        self._brand = QLabel("Oculus")
        self._brand.setStyleSheet("font-size: 22px; font-weight: 700;")
        self._layout.addWidget(self._brand)

        self._hint = QLabel("обзор · проверка · отчёт")
        self._hint.setObjectName("SectionHint")
        self._layout.addWidget(self._hint)

        self._nav_box = QVBoxLayout()
        self._nav_box.setSpacing(8)
        self._layout.addLayout(self._nav_box)
        self._layout.addStretch(1)

        toggle = QPushButton("☰ меню")
        toggle.setFixedHeight(36)
        toggle.setCursor(Qt.CursorShape.PointingHandCursor)
        toggle.setStyleSheet(
            f"border-radius: 10px; background: {cfg.COLOR_PANEL}; "
            f"border: 1px solid {cfg.COLOR_BORDER};"
        )
        toggle.clicked.connect(self.toggle)
        toggle.clicked.connect(lambda: get_sound_bus().play_click())
        self._toggle = toggle
        self._layout.addWidget(toggle)

        self._buttons: dict[str, SidebarButton] = {}
        self._width_anim = QPropertyAnimation(self, b"minimumWidth", self)
        self._width_anim.setDuration(220)
        self._width_anim.setEasingCurve(QEasingCurve.Type.InOutCubic)
        self._width_anim.valueChanged.connect(lambda v: self.setFixedWidth(int(v)))

    def set_items(self, items: list[tuple[str, str, QIcon | None]]) -> None:
        while self._nav_box.count():
            item = self._nav_box.takeAt(0)
            w = item.widget()
            if w:
                w.deleteLater()
        self._buttons.clear()
        for key, label, icon in items:
            btn = SidebarButton(key, label, icon, self)
            btn.clicked.connect(lambda checked=False, k=key: self._on_nav(k))
            self._buttons[key] = btn
            self._nav_box.addWidget(btn)

    def _on_nav(self, key: str) -> None:
        for k, btn in self._buttons.items():
            btn.setChecked(k == key)
        self.navigate.emit(key)

    def select(self, key: str) -> None:
        for k, btn in self._buttons.items():
            btn.setChecked(k == key)

    def toggle(self) -> None:
        self._expanded = not self._expanded
        start = self.width()
        end = self._expanded_width if self._expanded else self._collapsed_width
        self._width_anim.stop()
        self._width_anim.setStartValue(start)
        self._width_anim.setEndValue(end)
        self._width_anim.start()
        self._hint.setVisible(self._expanded)
        self._toggle.setText("☰ меню" if self._expanded else "☰")
        for btn in self._buttons.values():
            btn.setText(btn._full_text if self._expanded else "")
