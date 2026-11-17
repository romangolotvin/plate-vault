"""Rounded buttons with press animation."""

from __future__ import annotations

from PySide6.QtCore import QEasingCurve, QPropertyAnimation, Qt, Signal
from PySide6.QtGui import QFont
from PySide6.QtWidgets import (
    QGraphicsDropShadowEffect,
    QLabel,
    QPushButton,
    QSizePolicy,
    QVBoxLayout,
    QWidget,
)

from .. import config as cfg
from ..audio import get_sound_bus
from ..config import load_settings


class RoundedButton(QPushButton):
    """Primary action button: rounded corners, press glow animation, click sound."""

    def __init__(
        self,
        text: str,
        *,
        subtitle: str = "",
        parent=None,
        accent: bool = True,
    ) -> None:
        label = text if not subtitle else f"{text}\n{subtitle}"
        super().__init__(label, parent)
        self._accent = accent
        self.setCursor(Qt.CursorShape.PointingHandCursor)
        self.setMinimumHeight(64 if subtitle else 46)
        self.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
        font = QFont()
        font.setPointSize(12)
        font.setBold(True)
        self.setFont(font)

        self._shadow = QGraphicsDropShadowEffect(self)
        self._shadow.setBlurRadius(8)
        self._shadow.setOffset(0, 2)
        self._shadow.setColor(Qt.GlobalColor.black)
        self.setGraphicsEffect(self._shadow)

        self._glow = QPropertyAnimation(self._shadow, b"blurRadius", self)
        self._glow.setDuration(160)
        self._glow.setEasingCurve(QEasingCurve.Type.OutCubic)

        self.pressed.connect(self._on_press)
        self.released.connect(self._on_release)
        self.clicked.connect(self._on_click_sound)
        self._apply_style()

    def _apply_style(self) -> None:
        bg = cfg.COLOR_ACCENT if self._accent else cfg.COLOR_PANEL
        hover = cfg.COLOR_ACCENT_HOVER if self._accent else cfg.COLOR_BG_ELEVATED
        press = cfg.COLOR_ACCENT_PRESS if self._accent else cfg.COLOR_BORDER
        self.setStyleSheet(
            f"""
            QPushButton {{
                background-color: {bg};
                color: {cfg.COLOR_TEXT};
                border: 1px solid {cfg.COLOR_BORDER};
                border-radius: 16px;
                padding: 12px 16px;
                text-align: center;
            }}
            QPushButton:hover {{
                background-color: {hover};
            }}
            QPushButton:pressed {{
                background-color: {press};
                padding-top: 14px;
                padding-bottom: 10px;
            }}
            QPushButton:disabled {{
                background-color: #1a2a44;
                color: #6a7a96;
            }}
            """
        )

    def _on_press(self) -> None:
        if not load_settings().get("animations_enabled", True):
            return
        self._glow.stop()
        self._glow.setStartValue(self._shadow.blurRadius())
        self._glow.setEndValue(28)
        self._glow.start()

    def _on_release(self) -> None:
        if not load_settings().get("animations_enabled", True):
            self._shadow.setBlurRadius(8)
            return
        self._glow.stop()
        self._glow.setStartValue(self._shadow.blurRadius())
        self._glow.setEndValue(8)
        self._glow.start()

    def _on_click_sound(self) -> None:
        get_sound_bus().play_click()


class ModuleCardButton(QWidget):
    """Big rounded card-button with title + description."""

    clicked = Signal()

    def __init__(self, title: str, description: str, parent=None) -> None:
        super().__init__(parent)
        self.btn = RoundedButton(title, subtitle=description, parent=self)
        self.btn.clicked.connect(self.clicked.emit)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.addWidget(self.btn)

    def setEnabled(self, enabled: bool) -> None:  # noqa: N802
        super().setEnabled(enabled)
        self.btn.setEnabled(enabled)


class HeroBanner(QWidget):
    """Title + subtitle strip for pages."""

    def __init__(self, title: str, subtitle: str, parent=None) -> None:
        super().__init__(parent)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 8)
        t = QLabel(title)
        t.setObjectName("TitleLabel")
        s = QLabel(subtitle)
        s.setObjectName("SubtitleLabel")
        s.setWordWrap(True)
        layout.addWidget(t)
        layout.addWidget(s)
