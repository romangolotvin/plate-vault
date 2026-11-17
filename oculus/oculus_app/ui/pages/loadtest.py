from __future__ import annotations

from PySide6.QtWidgets import QHBoxLayout, QLabel, QSpinBox

from ... import config as cfg
from ...modules import loadtest as load_mod
from .base import SectionPage


class LoadTestPage(SectionPage):
    def __init__(self, parent=None) -> None:
        super().__init__(
            "Нагрузочный тест",
            "Контролируемый поток к своим сайтам: RPS, latency, точка отказа. Не DDoS.",
            parent,
        )
        self.target_edit.setText("https://127.0.0.1")

        row = QHBoxLayout()
        row.addWidget(QLabel("RPS"))
        self.rps = QSpinBox()
        self.rps.setRange(1, cfg.LOAD_MAX_RPS)
        self.rps.setValue(5)
        row.addWidget(self.rps)
        row.addWidget(QLabel("Concurrency"))
        self.conc = QSpinBox()
        self.conc.setRange(1, cfg.LOAD_MAX_CONCURRENCY)
        self.conc.setValue(4)
        row.addWidget(self.conc)
        row.addWidget(QLabel("Сек"))
        self.dur = QSpinBox()
        self.dur.setRange(1, cfg.LOAD_MAX_DURATION_SEC)
        self.dur.setValue(8)
        row.addWidget(self.dur)
        row.addStretch(1)
        # Insert controls under target
        self.layout().insertLayout(2, row)

        self.add_action(
            0,
            0,
            "Запустить нагрузку",
            f"Caps: {cfg.LOAD_MAX_RPS} RPS / {cfg.LOAD_MAX_CONCURRENCY} conc",
            self._run,
        )

    def _run(self, target: str, **hooks):
        return load_mod.run_load_test(
            target,
            rps=self.rps.value(),
            concurrency=self.conc.value(),
            duration_sec=self.dur.value(),
            **hooks,
        )
