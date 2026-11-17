from __future__ import annotations

from ...modules import webscan as web_mod
from .base import SectionPage


class WebChecksPage(SectionPage):
    def __init__(self, parent=None) -> None:
        super().__init__(
            "Веб-проверки",
            "Краул, заголовки и безопасное обнаружение SQLi/XSS без эксплойт-payload.",
            parent,
        )
        self.target_edit.setText("https://example.com")
        self.add_action(0, 0, "Краулер", "Карта ссылок в scope", web_mod.run_crawl)
        self.add_action(0, 1, "Заголовки и cookies", "CSP, HSTS, XFO…", web_mod.run_security_headers)
        self.add_action(
            1,
            0,
            "SQLi detect",
            "Мягкий probe + SQL error heuristics",
            web_mod.run_sqli_detect,
        )
        self.add_action(
            1,
            1,
            "XSS detect",
            "Рефлексия canary без script-payload",
            web_mod.run_xss_detect,
        )
