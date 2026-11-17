from __future__ import annotations

from ...modules import recon as recon_mod
from .base import SectionPage


class ReconPage(SectionPage):
    def __init__(self, parent=None) -> None:
        super().__init__(
            "Разведка",
            "Сбор публичной информации об инфраструктуре в рамках whitelist.",
            parent,
        )
        self.target_edit.setText("localhost")
        self.add_action(0, 0, "DNS-lookup", "A/AAAA/MX/NS/TXT/CNAME + PTR", recon_mod.run_dns)
        self.add_action(0, 1, "WHOIS / RDAP", "Публичные данные домена", recon_mod.run_whois)
        self.add_action(1, 0, "Поддомены", "Перечисление по короткому словарю", recon_mod.run_subdomains)
