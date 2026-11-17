"""First-run permission gate for Oculus."""

from __future__ import annotations

from typing import Callable

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (
    QCheckBox,
    QDialog,
    QDialogButtonBox,
    QLabel,
    QVBoxLayout,
)

from . import config as cfg
from .config import load_settings, save_settings


class PermissionsDialog(QDialog):
    """Shown on first launch; modules stay disabled until accepted."""

    def __init__(self, parent=None) -> None:
        super().__init__(parent)
        self.setWindowTitle(f"{cfg.APP_NAME} — разрешения")
        self.setModal(True)
        self.setMinimumWidth(460)

        title = QLabel("Добро пожаловать в Oculus")
        title.setObjectName("TitleLabel")
        body = QLabel(
            "Перед работой нужно явное согласие на доступ к сети и запись "
            "отчётов. Используйте приложение только на целях из whitelist "
            "(свои сайты / письменное разрешение)."
        )
        body.setWordWrap(True)
        body.setObjectName("SubtitleLabel")

        self.cb_network = QCheckBox("Разрешить сетевые проверки (DNS, HTTP, TLS, сканы)")
        self.cb_reports = QCheckBox("Разрешить сохранение отчётов на диск")
        self.cb_sound = QCheckBox("Включить звуки кнопок")
        self.cb_sound.setChecked(True)
        self.cb_legal = QCheckBox(
            "Подтверждаю: буду тестировать только авторизованные цели"
        )

        buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok)
        self.ok_btn = buttons.button(QDialogButtonBox.StandardButton.Ok)
        self.ok_btn.setText("Продолжить")
        self.ok_btn.setEnabled(False)
        buttons.accepted.connect(self._accept)

        for box in (self.cb_network, self.cb_reports, self.cb_legal):
            box.stateChanged.connect(self._sync_ok)

        layout = QVBoxLayout(self)
        layout.setSpacing(14)
        layout.addWidget(title)
        layout.addWidget(body)
        layout.addWidget(self.cb_network)
        layout.addWidget(self.cb_reports)
        layout.addWidget(self.cb_sound)
        layout.addWidget(self.cb_legal)
        layout.addWidget(buttons)

    def _sync_ok(self) -> None:
        self.ok_btn.setEnabled(
            self.cb_network.isChecked()
            and self.cb_reports.isChecked()
            and self.cb_legal.isChecked()
        )

    def _accept(self) -> None:
        data = load_settings()
        data.update(
            {
                "permissions_accepted": True,
                "network_allowed": True,
                "reports_write_allowed": True,
                "sound_enabled": self.cb_sound.isChecked(),
                "animations_enabled": True,
            }
        )
        save_settings(data)
        self.accept()


def permissions_granted() -> bool:
    s = load_settings()
    return bool(
        s.get("permissions_accepted")
        and s.get("network_allowed")
        and s.get("reports_write_allowed")
    )


def ensure_permissions(parent=None, on_granted: Callable[[], None] | None = None) -> bool:
    if permissions_granted():
        if on_granted:
            on_granted()
        return True
    dlg = PermissionsDialog(parent)
    if dlg.exec() == QDialog.DialogCode.Accepted:
        if on_granted:
            on_granted()
        return True
    return False
