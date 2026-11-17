from __future__ import annotations

from ...modules import bruteforce as brute_mod
from .base import SectionPage


class BruteforcePage(SectionPage):
    def __init__(self, parent=None) -> None:
        super().__init__(
            "Брутфорс",
            "Словарная проверка HTTP Basic Auth с rate-limit и stop-on-success.",
            parent,
        )
        self.target_edit.setText("https://127.0.0.1")
        self.add_action(
            0,
            0,
            "Словарь Basic Auth",
            "Малый словарь, задержка, лимит попыток",
            brute_mod.run_dict_bruteforce,
        )
