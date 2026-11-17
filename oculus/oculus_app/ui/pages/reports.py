from __future__ import annotations

import webbrowser

from PySide6.QtWidgets import QHBoxLayout, QLabel, QLineEdit, QListWidget, QVBoxLayout, QWidget

from ...core.scope import Scope
from ...modules import reports as reports_mod
from ..widgets import HeroBanner, RoundedButton


class ReportsPage(QWidget):
    def __init__(self, parent=None) -> None:
        super().__init__(parent)
        self._enabled = False
        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 16, 20, 16)
        layout.addWidget(
            HeroBanner("Отчёты", "Сохранённые HTML/JSON/PDF и менеджер whitelist.")
        )

        layout.addWidget(QLabel("Whitelist (scope)"))
        self.scope_list = QListWidget()
        layout.addWidget(self.scope_list)

        add_row = QHBoxLayout()
        self.scope_edit = QLineEdit()
        self.scope_edit.setPlaceholderText("добавить хост, напр. example.com")
        self.add_scope_btn = RoundedButton("Добавить в whitelist")
        self.add_scope_btn.clicked.connect(self.add_scope_host)
        add_row.addWidget(self.scope_edit, 1)
        add_row.addWidget(self.add_scope_btn)
        layout.addLayout(add_row)

        self.refresh_scope_btn = RoundedButton("Обновить scope", accent=False)
        self.refresh_scope_btn.clicked.connect(self.refresh_scope)
        layout.addWidget(self.refresh_scope_btn)

        layout.addWidget(QLabel("Файлы отчётов"))
        self.report_list = QListWidget()
        layout.addWidget(self.report_list, 1)

        self.refresh_btn = RoundedButton("Обновить список отчётов")
        self.refresh_btn.clicked.connect(self.refresh_reports)
        self.open_btn = RoundedButton("Открыть выбранный HTML", accent=False)
        self.open_btn.clicked.connect(self.open_selected)
        layout.addWidget(self.refresh_btn)
        layout.addWidget(self.open_btn)

        self.refresh_scope()
        self.refresh_reports()

    def set_modules_enabled(self, enabled: bool) -> None:
        self._enabled = enabled
        self.refresh_btn.setEnabled(enabled)
        self.open_btn.setEnabled(enabled)
        self.refresh_scope_btn.setEnabled(enabled)
        self.add_scope_btn.setEnabled(enabled)

    def refresh_scope(self) -> None:
        self.scope_list.clear()
        for host in Scope.load().hosts:
            self.scope_list.addItem(host)

    def add_scope_host(self) -> None:
        host = self.scope_edit.text().strip()
        if not host:
            return
        scope = Scope.load()
        scope.add(host)
        self.scope_edit.clear()
        self.refresh_scope()

    def refresh_reports(self) -> None:
        self.report_list.clear()
        for path in reports_mod.list_reports():
            self.report_list.addItem(str(path))

    def open_selected(self) -> None:
        item = self.report_list.currentItem()
        if item:
            webbrowser.open(item.text())
