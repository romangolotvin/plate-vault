from __future__ import annotations

from ...modules import sslcheck as ssl_mod
from .base import SectionPage


class SslPage(SectionPage):
    def __init__(self, parent=None) -> None:
        super().__init__(
            "SSL/TLS",
            "Протокол, cipher, срок и издатель сертификата.",
            parent,
        )
        self.target_edit.setText("example.com")
        self.add_action(0, 0, "SSL/TLS-аудит", "Handshake и сертификат", ssl_mod.run_ssl_audit)
