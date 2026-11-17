"""Shared page chrome: target field, log, progress, worker wiring."""

from __future__ import annotations

from typing import Any, Callable

from PySide6.QtWidgets import (
    QGridLayout,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QPlainTextEdit,
    QProgressBar,
    QScrollArea,
    QVBoxLayout,
    QWidget,
)

from ...core.results import ModuleResult
from ...core.workers import ModuleWorker
from ...modules import reports as reports_mod
from ..widgets import HeroBanner, ModuleCardButton, RoundedButton


class SectionPage(QWidget):
    def __init__(self, title: str, subtitle: str, parent=None) -> None:
        super().__init__(parent)
        self._worker: ModuleWorker | None = None
        self._last_result: ModuleResult | None = None
        self._modules_enabled = False

        root = QVBoxLayout(self)
        root.setContentsMargins(20, 16, 20, 16)
        root.setSpacing(12)
        root.addWidget(HeroBanner(title, subtitle))

        target_row = QHBoxLayout()
        target_row.addWidget(QLabel("Цель (whitelist):"))
        self.target_edit = QLineEdit()
        self.target_edit.setPlaceholderText("example.com или https://example.com/path?id=1")
        target_row.addWidget(self.target_edit, 1)
        root.addLayout(target_row)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        holder = QWidget()
        self.actions_grid = QGridLayout(holder)
        self.actions_grid.setSpacing(12)
        scroll.setWidget(holder)
        root.addWidget(scroll, 2)

        self.progress = QProgressBar()
        self.progress.setValue(0)
        root.addWidget(self.progress)

        self.log = QPlainTextEdit()
        self.log.setObjectName("LogView")
        self.log.setReadOnly(True)
        self.log.setMinimumHeight(160)
        root.addWidget(self.log, 2)

        controls = QHBoxLayout()
        self.stop_btn = RoundedButton("Стоп", accent=False)
        self.stop_btn.clicked.connect(self.stop_worker)
        self.save_btn = RoundedButton("Сохранить отчёт", accent=False)
        self.save_btn.clicked.connect(self.save_last_report)
        controls.addWidget(self.stop_btn)
        controls.addWidget(self.save_btn)
        controls.addStretch(1)
        root.addLayout(controls)

        self._action_buttons: list[ModuleCardButton] = []

    def add_action(
        self,
        row: int,
        col: int,
        title: str,
        description: str,
        runner: Callable[..., ModuleResult],
        **kwargs: Any,
    ) -> ModuleCardButton:
        card = ModuleCardButton(title, description)
        card.clicked.connect(lambda: self.start_job(runner, **kwargs))
        self.actions_grid.addWidget(card, row, col)
        self._action_buttons.append(card)
        card.setEnabled(self._modules_enabled)
        return card

    def set_modules_enabled(self, enabled: bool) -> None:
        self._modules_enabled = enabled
        for btn in self._action_buttons:
            btn.setEnabled(enabled)
        self.save_btn.setEnabled(enabled)

    def append_log(self, message: str) -> None:
        self.log.appendPlainText(message)

    def start_job(self, runner: Callable[..., ModuleResult], **kwargs: Any) -> None:
        if not self._modules_enabled:
            self.append_log("Сначала выдайте разрешения при запуске.")
            return
        if self._worker and self._worker.isRunning():
            self.append_log("Уже выполняется задача — нажмите Стоп или дождитесь конца.")
            return
        target = self.target_edit.text().strip()
        if not target:
            self.append_log("Укажите цель.")
            return
        self.progress.setValue(0)
        self.append_log(f"——— старт: {runner.__name__} → {target} ———")
        self._worker = ModuleWorker(runner, target, **kwargs)
        self._worker.log.connect(self.append_log)
        self._worker.progress.connect(self.progress.setValue)
        self._worker.finished_ok.connect(self._on_ok)
        self._worker.failed.connect(self._on_fail)
        self._worker.start()

    def stop_worker(self) -> None:
        if self._worker and self._worker.isRunning():
            self._worker.cancel()
            self.append_log("Запрошена остановка…")

    def _on_ok(self, result: object) -> None:
        if isinstance(result, ModuleResult):
            self._last_result = result
            self.append_log(f"Готово: {result.summary}")
            for f in result.findings:
                self.append_log(f"  [{f.severity}] {f.title}: {f.detail}")
        else:
            self.append_log(f"Готово: {result}")
        self.progress.setValue(100)

    def _on_fail(self, message: str) -> None:
        self.append_log(f"Ошибка: {message}")

    def save_last_report(self) -> None:
        if not self._last_result:
            self.append_log("Нет результата для отчёта.")
            return
        paths = reports_mod.save_report(self._last_result, log=self.append_log)
        self.append_log(f"Отчёт сохранён: {paths.get('html')}")
