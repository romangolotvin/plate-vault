"""Web checks: crawl, headers, cookies, safe SQLi/XSS detection (no exploits)."""

from __future__ import annotations

import re
from html.parser import HTMLParser
from typing import Callable
from urllib.parse import parse_qsl, urlencode, urljoin, urlparse, urlunparse

import requests

from ..core.results import ModuleResult
from ..core.scope import Scope

SECURITY_HEADERS = [
    "content-security-policy",
    "strict-transport-security",
    "x-frame-options",
    "x-content-type-options",
    "referrer-policy",
    "permissions-policy",
]

SQL_ERROR_HINTS = [
    "sql syntax",
    "mysql",
    "postgresql",
    "sqlite",
    "ora-",
    "odbc",
    "unclosed quotation",
    "you have an error in your sql",
]

# Benign reflection canary — NOT an executable XSS payload
XSS_CANARY = "oculusCanary7f3a9c"


class _LinkParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.links: list[str] = []

    def handle_starttag(self, tag: str, attrs) -> None:  # noqa: ANN001
        if tag != "a":
            return
        href = dict(attrs).get("href")
        if href:
            self.links.append(href)


def _session() -> requests.Session:
    s = requests.Session()
    s.headers.update({"User-Agent": "Oculus/0.1 (authorized web checks)"})
    s.max_redirects = 5
    return s


def _ensure_url(target: str) -> str:
    t = target.strip()
    if not t.startswith(("http://", "https://")):
        t = "https://" + t
    return t


def run_crawl(
    target: str,
    *,
    log: Callable[[str], None],
    progress: Callable[[int], None],
    should_cancel: Callable[[], bool],
) -> ModuleResult:
    scope = Scope.load()
    url = _ensure_url(target)
    host = scope.require(url)
    result = ModuleResult(module="crawl", target=host)
    session = _session()
    progress(20)
    log(f"Краул: {url}")
    try:
        resp = session.get(url, timeout=10, verify=True)
    except requests.RequestException as exc:
        raise RuntimeError(f"HTTP ошибка: {exc}") from exc

    parser = _LinkParser()
    parser.feed(resp.text)
    same_host = []
    for link in parser.links:
        if should_cancel():
            break
        abs_url = urljoin(url, link)
        if urlparse(abs_url).hostname and scope.allows(abs_url):
            same_host.append(abs_url)

    unique = sorted(set(same_host))[:80]
    for u in unique:
        log(f"  {u}")
        result.add("info", "URL", u)
    result.raw = {"status": resp.status_code, "urls": unique, "count": len(unique)}
    progress(100)
    return result.finish(f"Найдено ссылок в scope: {len(unique)}")


def run_security_headers(
    target: str,
    *,
    log: Callable[[str], None],
    progress: Callable[[int], None],
    should_cancel: Callable[[], bool],
) -> ModuleResult:
    scope = Scope.load()
    url = _ensure_url(target)
    host = scope.require(url)
    result = ModuleResult(module="headers", target=host)
    session = _session()
    progress(30)
    resp = session.get(url, timeout=10)
    headers = {k.lower(): v for k, v in resp.headers.items()}
    missing = []
    for h in SECURITY_HEADERS:
        if should_cancel():
            break
        if h in headers:
            log(f"OK {h}: {headers[h][:80]}")
            result.add("info", f"Заголовок {h}", headers[h][:200])
        else:
            missing.append(h)
            log(f"Нет {h}")
            result.add("medium", f"Нет заголовка {h}", "Рекомендуется настроить")
    # Cookies
    for cookie in resp.cookies:
        flags = []
        if cookie.secure:
            flags.append("Secure")
        # requests Cookie lacks httponly attr reliably across versions
        result.add(
            "info",
            f"Cookie {cookie.name}",
            f"domain={cookie.domain}; flags≈{','.join(flags) or 'проверить HttpOnly/SameSite вручную'}",
        )
        log(f"Cookie: {cookie.name}")
    result.raw = {"missing": missing, "status": resp.status_code}
    progress(100)
    return result.finish(f"Отсутствует заголовков: {len(missing)}")


def run_sqli_detect(
    target: str,
    *,
    log: Callable[[str], None],
    progress: Callable[[int], None],
    should_cancel: Callable[[], bool],
) -> ModuleResult:
    """Safe SQLi *detection*: mild quote probe + error-string heuristics. No exploit payloads."""
    scope = Scope.load()
    url = _ensure_url(target)
    host = scope.require(url)
    result = ModuleResult(module="sqli_detect", target=host)
    session = _session()
    parsed = urlparse(url)
    qs = parse_qsl(parsed.query, keep_blank_values=True)
    progress(20)

    if not qs:
        log("Нет query-параметров — пассивная проверка недоступна")
        result.add(
            "info",
            "SQLi detect",
            "URL без параметров. Укажите URL вида https://host/path?id=1",
        )
        progress(100)
        return result.finish("Нет параметров для проверки")

    base_resp = session.get(url, timeout=10)
    base_body = base_resp.text.lower()
    progress(50)

    # Mild probe: append a single quote to first param value (detection only)
    probed = []
    for i, (k, v) in enumerate(qs):
        if i == 0:
            probed.append((k, f"{v}'"))
        else:
            probed.append((k, v))
    probe_url = urlunparse(parsed._replace(query=urlencode(probed)))
    if should_cancel():
        return result.finish("Отменено")

    log(f"Безопасный probe (кавычка в параметре): {probe_url}")
    try:
        probe_resp = session.get(probe_url, timeout=10)
        body = probe_resp.text.lower()
        hits = [h for h in SQL_ERROR_HINTS if h in body and h not in base_body]
        if hits:
            result.add(
                "high",
                "Возможный SQL error reflection",
                "Ответ содержит SQL-подобные сообщения после мягкого probe",
                evidence=", ".join(hits),
            )
            log(f"Сигналы: {', '.join(hits)}")
        else:
            result.add("info", "SQLi detect", "Явных SQL error-строк не найдено")
            log("Явных SQL error-строк нет")
        result.raw = {
            "status": probe_resp.status_code,
            "hits": hits,
            "note": "detection-only; no exploit payload",
        }
    except requests.RequestException as exc:
        result.add("low", "SQLi detect", f"Ошибка запроса: {exc}")

    progress(100)
    return result.finish("SQLi detection завершён")


def run_xss_detect(
    target: str,
    *,
    log: Callable[[str], None],
    progress: Callable[[int], None],
    should_cancel: Callable[[], bool],
) -> ModuleResult:
    """Safe XSS *detection*: reflect unique canary, check raw HTML. No <script> payloads."""
    scope = Scope.load()
    url = _ensure_url(target)
    host = scope.require(url)
    result = ModuleResult(module="xss_detect", target=host)
    session = _session()
    parsed = urlparse(url)
    qs = parse_qsl(parsed.query, keep_blank_values=True)
    progress(20)

    if not qs:
        # Also try path reflection via a harmless query
        qs = [("q", "1")]
        parsed = parsed._replace(query="q=1")

    probed = [(k, XSS_CANARY if i == 0 else v) for i, (k, v) in enumerate(qs)]
    probe_url = urlunparse(parsed._replace(query=urlencode(probed)))
    if should_cancel():
        return result.finish("Отменено")

    log(f"Canary reflection check: {XSS_CANARY}")
    resp = session.get(probe_url, timeout=10)
    progress(70)
    body = resp.text
    if XSS_CANARY in body:
        # Unescaped in HTML context?
        dangerous = bool(re.search(rf">[^<]*{re.escape(XSS_CANARY)}", body)) or (
            XSS_CANARY in body and "&lt;" not in body[max(0, body.find(XSS_CANARY) - 5) : body.find(XSS_CANARY)]
        )
        if dangerous:
            result.add(
                "high",
                "Возможная XSS-рефлексия",
                "Уникальный canary отразился в ответе без очевидного экранирования",
                evidence=XSS_CANARY,
            )
            log("Canary отражён — риск отражения входных данных")
        else:
            result.add("medium", "Canary найден в ответе", "Проверьте контекст экранирования")
            log("Canary найден")
    else:
        result.add("info", "XSS detect", "Canary не отразился")
        log("Canary не отразился")

    result.raw = {"canary": XSS_CANARY, "reflected": XSS_CANARY in body, "note": "no exploit payload"}
    progress(100)
    return result.finish("XSS detection завершён")
