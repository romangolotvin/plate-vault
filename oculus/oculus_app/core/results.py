"""Shared result containers."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from typing import Any


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


@dataclass
class Finding:
    severity: str  # info | low | medium | high
    title: str
    detail: str
    evidence: str = ""

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class ModuleResult:
    module: str
    target: str
    started_at: str = field(default_factory=utc_now)
    finished_at: str = ""
    findings: list[Finding] = field(default_factory=list)
    raw: dict[str, Any] = field(default_factory=dict)
    summary: str = ""

    def finish(self, summary: str = "") -> "ModuleResult":
        self.finished_at = utc_now()
        if summary:
            self.summary = summary
        return self

    def add(
        self,
        severity: str,
        title: str,
        detail: str,
        evidence: str = "",
    ) -> None:
        self.findings.append(Finding(severity, title, detail, evidence))

    def to_dict(self) -> dict[str, Any]:
        return {
            "module": self.module,
            "target": self.target,
            "started_at": self.started_at,
            "finished_at": self.finished_at,
            "summary": self.summary,
            "findings": [f.to_dict() for f in self.findings],
            "raw": self.raw,
        }
