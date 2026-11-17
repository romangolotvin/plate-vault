"""Report generation (HTML + optional PDF)."""

from __future__ import annotations

import html
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

from ..config import REPORTS_DIR, ensure_data_dirs
from ..core.results import ModuleResult


def _escape(value: str) -> str:
    return html.escape(value or "", quote=True)


def result_to_html(result: ModuleResult | dict[str, Any]) -> str:
    data = result.to_dict() if isinstance(result, ModuleResult) else result
    rows = []
    for f in data.get("findings", []):
        rows.append(
            "<tr>"
            f"<td>{_escape(f.get('severity', ''))}</td>"
            f"<td>{_escape(f.get('title', ''))}</td>"
            f"<td>{_escape(f.get('detail', ''))}</td>"
            f"<td><code>{_escape(f.get('evidence', ''))}</code></td>"
            "</tr>"
        )
    return f"""<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8"/>
  <title>Oculus report — {_escape(data.get('module', ''))}</title>
  <style>
    body {{ font-family: Segoe UI, sans-serif; background:#0B1A33; color:#E8F0FF; padding:24px; }}
    h1 {{ color:#3D7EFF; }}
    table {{ border-collapse: collapse; width:100%; }}
    th, td {{ border:1px solid #2A4570; padding:8px 10px; text-align:left; }}
    th {{ background:#122445; }}
    code {{ color:#9BB0D0; }}
  </style>
</head>
<body>
  <h1>Oculus</h1>
  <p>Модуль: <b>{_escape(data.get('module', ''))}</b> · Цель: <b>{_escape(data.get('target', ''))}</b></p>
  <p>{_escape(data.get('summary', ''))}</p>
  <p>Старт: {_escape(data.get('started_at', ''))}<br/>Финиш: {_escape(data.get('finished_at', ''))}</p>
  <table>
    <thead><tr><th>Severity</th><th>Title</th><th>Detail</th><th>Evidence</th></tr></thead>
    <tbody>
      {''.join(rows) or '<tr><td colspan="4">Нет findings</td></tr>'}
    </tbody>
  </table>
</body>
</html>
"""


def save_report(
    result: ModuleResult,
    *,
    log: Callable[[str], None] | None = None,
    progress: Callable[[int], None] | None = None,
    should_cancel: Callable[[], bool] | None = None,
    also_pdf: bool = True,
) -> dict[str, str]:
    ensure_data_dirs()
    if progress:
        progress(20)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    base = f"{result.module}_{result.target.replace(':', '_').replace('/', '_')}_{stamp}"
    html_path = REPORTS_DIR / f"{base}.html"
    json_path = REPORTS_DIR / f"{base}.json"
    html_path.write_text(result_to_html(result), encoding="utf-8")
    json_path.write_text(json.dumps(result.to_dict(), ensure_ascii=False, indent=2), encoding="utf-8")
    if log:
        log(f"HTML: {html_path}")
        log(f"JSON: {json_path}")
    paths = {"html": str(html_path), "json": str(json_path)}
    if progress:
        progress(70)

    if also_pdf:
        pdf_path = REPORTS_DIR / f"{base}.pdf"
        try:
            from reportlab.lib.pagesizes import A4
            from reportlab.pdfgen import canvas

            c = canvas.Canvas(str(pdf_path), pagesize=A4)
            width, height = A4
            y = height - 50
            c.setTitle(f"Oculus — {result.module}")
            c.drawString(40, y, f"Oculus report: {result.module} / {result.target}")
            y -= 24
            c.drawString(40, y, result.summary[:100])
            y -= 24
            for finding in result.findings[:25]:
                line = f"[{finding.severity}] {finding.title}: {finding.detail}"[:110]
                c.drawString(40, y, line)
                y -= 16
                if y < 60:
                    c.showPage()
                    y = height - 50
            c.save()
            paths["pdf"] = str(pdf_path)
            if log:
                log(f"PDF: {pdf_path}")
        except Exception as exc:  # noqa: BLE001
            if log:
                log(f"PDF пропущен: {exc}")
    if progress:
        progress(100)
    return paths


def list_reports() -> list[Path]:
    ensure_data_dirs()
    return sorted(REPORTS_DIR.glob("*.html"), key=lambda p: p.stat().st_mtime, reverse=True)
