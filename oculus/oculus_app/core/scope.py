"""Whitelist of authorized targets."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from typing import Iterable
from urllib.parse import urlparse

from ..config import SCOPE_PATH, ensure_data_dirs

_HOST_RE = re.compile(
    r"^(?=.{1,253}$)(?!-)[A-Za-z0-9-]{1,63}(?<!-)(\.(?!-)[A-Za-z0-9-]{1,63}(?<!-))*$"
)
_IP_RE = re.compile(
    r"^(?:\d{1,3}\.){3}\d{1,3}$"
)


@dataclass
class Scope:
    hosts: list[str] = field(default_factory=list)

    @classmethod
    def load(cls) -> "Scope":
        ensure_data_dirs()
        if not SCOPE_PATH.exists():
            # Sensible local defaults for first-run demos
            scope = cls(hosts=["localhost", "127.0.0.1"])
            scope.save()
            return scope
        try:
            data = json.loads(SCOPE_PATH.read_text(encoding="utf-8"))
            hosts = [h.strip().lower() for h in data.get("hosts", []) if h.strip()]
            return cls(hosts=hosts or ["localhost", "127.0.0.1"])
        except (OSError, json.JSONDecodeError):
            return cls(hosts=["localhost", "127.0.0.1"])

    def save(self) -> None:
        ensure_data_dirs()
        SCOPE_PATH.write_text(
            json.dumps({"hosts": self.hosts}, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    def add(self, host: str) -> None:
        h = normalize_host(host)
        if h and h not in self.hosts:
            self.hosts.append(h)
            self.save()

    def remove(self, host: str) -> None:
        h = normalize_host(host)
        self.hosts = [x for x in self.hosts if x != h]
        self.save()

    def allows(self, target: str) -> bool:
        host = normalize_host(target)
        if not host:
            return False
        if host in self.hosts:
            return True
        # Allow subdomains of whitelisted parents: a.b.example.com under example.com
        for allowed in self.hosts:
            if host == allowed or host.endswith("." + allowed):
                return True
        return False

    def require(self, target: str) -> str:
        host = normalize_host(target)
        if not self.allows(host):
            raise PermissionError(
                f"Цель «{host or target}» вне whitelist. Добавьте её в scope."
            )
        return host


def normalize_host(value: str) -> str:
    raw = (value or "").strip().lower()
    if not raw:
        return ""
    if "://" in raw:
        parsed = urlparse(raw)
        raw = parsed.hostname or ""
    else:
        raw = raw.split("/")[0].split(":")[0]
    raw = raw.strip(".")
    if raw in {"localhost"} or _IP_RE.match(raw) or _HOST_RE.match(raw):
        return raw
    return raw  # still return; allows() will decide


def format_hosts(hosts: Iterable[str]) -> str:
    return ", ".join(hosts)
