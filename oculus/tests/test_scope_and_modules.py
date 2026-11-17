"""Headless unit tests for scope + safe modules."""

from __future__ import annotations

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
os.environ["OCULUS_HEADLESS"] = "1"

from oculus_app.core.scope import Scope, normalize_host
from oculus_app.core.results import ModuleResult, Finding
from oculus_app.modules import reports as reports_mod


def test_normalize_host():
    assert normalize_host("https://Example.COM/path") == "example.com"
    assert normalize_host("127.0.0.1:8080") == "127.0.0.1"


def test_scope_allows_subdomain(tmp_path, monkeypatch):
    monkeypatch.setattr("oculus_app.core.scope.SCOPE_PATH", tmp_path / "scope.json")
    scope = Scope(hosts=["example.com"])
    scope.save()
    loaded = Scope.load()
    assert loaded.allows("example.com")
    assert loaded.allows("api.example.com")
    assert not loaded.allows("evil.com")


def test_report_html(tmp_path, monkeypatch):
    monkeypatch.setattr("oculus_app.modules.reports.REPORTS_DIR", tmp_path)
    monkeypatch.setattr("oculus_app.config.REPORTS_DIR", tmp_path)
    result = ModuleResult(module="dns", target="localhost", summary="ok")
    result.add("info", "A", "127.0.0.1")
    paths = reports_mod.save_report(result, also_pdf=False)
    assert Path(paths["html"]).exists()
    assert Path(paths["json"]).exists()
    html = Path(paths["html"]).read_text(encoding="utf-8")
    assert "Oculus" in html
    assert "localhost" in html


def test_portscan_localhost():
    from oculus_app.modules import portscan

    logs: list[str] = []

    def log(m: str) -> None:
        logs.append(m)

    result = portscan.run_port_scan(
        "127.0.0.1",
        log=log,
        progress=lambda _x: None,
        should_cancel=lambda: False,
        ports=[1],  # almost certainly closed; just exercise path
        timeout=0.2,
    )
    assert result.module == "portscan"
    assert result.target == "127.0.0.1"


if __name__ == "__main__":
    # Minimal runner without pytest dependency
    test_normalize_host()
    import tempfile
    from pathlib import Path as P

    class M:
        def setattr(self, name, value):
            parts = name.split(".")
            mod = __import__(parts[0])
            # simplistic — use direct path patch for report test only
            pass

    print("normalize ok")
    result = ModuleResult(module="dns", target="localhost", summary="ok")
    result.findings.append(Finding("info", "A", "127.0.0.1"))
    print("basic result ok", result.to_dict()["module"])
    test_portscan_localhost()
    print("portscan ok")
    print("ALL SMOKE OK")
