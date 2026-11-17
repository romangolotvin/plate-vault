"""Recon: DNS, WHOIS (public), subdomain wordlist."""

from __future__ import annotations

import socket
from typing import Callable
from urllib.request import Request, urlopen

import dns.resolver

from ..core.results import ModuleResult
from ..core.scope import Scope

COMMON_SUBS = [
    "www",
    "mail",
    "ftp",
    "api",
    "dev",
    "staging",
    "test",
    "admin",
    "cdn",
    "vpn",
    "ns1",
    "ns2",
    "blog",
    "shop",
    "portal",
]


def _resolver() -> dns.resolver.Resolver:
    r = dns.resolver.Resolver()
    r.lifetime = 3.0
    r.timeout = 2.0
    return r


def run_dns(
    target: str,
    *,
    log: Callable[[str], None],
    progress: Callable[[int], None],
    should_cancel: Callable[[], bool],
) -> ModuleResult:
    scope = Scope.load()
    host = scope.require(target)
    result = ModuleResult(module="dns", target=host)
    res = _resolver()
    record_types = ["A", "AAAA", "MX", "NS", "TXT", "CNAME"]
    collected: dict[str, list[str]] = {}

    for i, rtype in enumerate(record_types):
        if should_cancel():
            break
        progress(int((i / len(record_types)) * 90))
        try:
            answers = res.resolve(host, rtype)
            values = [rdata.to_text() for rdata in answers]
            collected[rtype] = values
            log(f"{rtype}: {', '.join(values)}")
            result.add("info", f"DNS {rtype}", ", ".join(values))
        except Exception as exc:  # noqa: BLE001
            log(f"{rtype}: нет записей ({exc.__class__.__name__})")
            collected[rtype] = []

    try:
        ptr_ip = socket.gethostbyname(host)
        try:
            ptr = socket.gethostbyaddr(ptr_ip)[0]
            collected["PTR"] = [ptr]
            log(f"PTR ({ptr_ip}): {ptr}")
            result.add("info", "Reverse DNS", f"{ptr_ip} → {ptr}")
        except socket.herror:
            log(f"PTR ({ptr_ip}): нет")
    except OSError as exc:
        log(f"A/resolve error: {exc}")

    result.raw = collected
    progress(100)
    return result.finish(f"DNS для {host}: {sum(len(v) for v in collected.values())} записей")


def run_whois(
    target: str,
    *,
    log: Callable[[str], None],
    progress: Callable[[int], None],
    should_cancel: Callable[[], bool],
) -> ModuleResult:
    """Lightweight public RDAP/WHOIS-ish lookup via rdap.org JSON."""
    scope = Scope.load()
    host = scope.require(target)
    result = ModuleResult(module="whois", target=host)
    progress(10)
    if should_cancel():
        return result.finish("Отменено")

    url = f"https://rdap.org/domain/{host}"
    log(f"RDAP запрос: {url}")
    try:
        req = Request(url, headers={"User-Agent": "Oculus/0.1 (authorized recon)"})
        with urlopen(req, timeout=8) as resp:  # noqa: S310 — explicit https RDAP
            progress(70)
            raw = resp.read().decode("utf-8", errors="replace")
            result.raw["rdap_snippet"] = raw[:4000]
            # Extract a few human fields without full JSON dependency edge-cases
            for key in ("handle", "ldhName", "status", "port43"):
                if key in raw:
                    result.add("info", f"RDAP {key}", "поле присутствует в ответе")
            log("RDAP ответ получен")
            result.add("info", "WHOIS/RDAP", "Публичные данные получены через rdap.org")
    except Exception as exc:  # noqa: BLE001
        log(f"WHOIS/RDAP недоступен: {exc}")
        result.add("low", "WHOIS", f"Не удалось получить RDAP: {exc}")

    progress(100)
    return result.finish(f"WHOIS/RDAP для {host}")


def run_subdomains(
    target: str,
    *,
    log: Callable[[str], None],
    progress: Callable[[int], None],
    should_cancel: Callable[[], bool],
    wordlist: list[str] | None = None,
) -> ModuleResult:
    scope = Scope.load()
    host = scope.require(target)
    result = ModuleResult(module="subdomains", target=host)
    words = wordlist or COMMON_SUBS
    found: list[str] = []
    res = _resolver()

    for i, prefix in enumerate(words):
        if should_cancel():
            break
        progress(int((i / max(len(words), 1)) * 100))
        candidate = f"{prefix}.{host}"
        # Candidate must still be in scope (subdomain of whitelisted parent)
        if not scope.allows(candidate):
            continue
        try:
            answers = res.resolve(candidate, "A")
            ips = [a.to_text() for a in answers]
            found.append(candidate)
            log(f"Найден: {candidate} → {', '.join(ips)}")
            result.add("info", "Поддомен", candidate, evidence=", ".join(ips))
        except Exception:
            continue

    result.raw["found"] = found
    return result.finish(f"Найдено поддоменов: {len(found)}")
