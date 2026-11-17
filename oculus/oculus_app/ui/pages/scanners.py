from __future__ import annotations

from ...modules import portscan as portscan_mod
from .base import SectionPage


class ScannersPage(SectionPage):
    def __init__(self, parent=None) -> None:
        super().__init__(
            "Сетевые сканеры",
            "Порты и баннеры только для целей из whitelist, с таймаутами.",
            parent,
        )
        self.target_edit.setText("127.0.0.1")
        self.add_action(
            0,
            0,
            "Порт-сканер",
            "Типовые TCP-порты + banner grab",
            portscan_mod.run_port_scan,
        )
