"""SSL/TLS configuration checks."""

from __future__ import annotations

import socket
import ssl
from datetime import datetime, timezone
from typing import Callable

from ..core.results import ModuleResult
from ..core.scope import Scope


def run_ssl_audit(
    target: str,
    *,
    log: Callable[[str], None],
    progress: Callable[[int], None],
    should_cancel: Callable[[], bool],
    port: int = 443,
) -> ModuleResult:
    scope = Scope.load()
    host = scope.require(target)
    result = ModuleResult(module="ssl", target=host)
    progress(15)
    log(f"TLS handshake → {host}:{port}")

    context = ssl.create_default_context()
    try:
        with socket.create_connection((host, port), timeout=8) as sock:
            progress(40)
            if should_cancel():
                return result.finish("Отменено")
            with context.wrap_socket(sock, server_hostname=host) as ssock:
                progress(70)
                cert = ssock.getpeercert()
                version = ssock.version()
                cipher = ssock.cipher()
                log(f"Протокол: {version}")
                log(f"Cipher: {cipher}")
                result.add("info", "TLS version", str(version))
                result.add("info", "Cipher suite", str(cipher))

                if version in {"TLSv1", "TLSv1.1", "SSLv3", "SSLv2"}:
                    result.add("high", "Устаревший протокол", str(version))

                not_after = cert.get("notAfter")
                if not_after:
                    # Example: 'Nov 18 12:00:00 2026 GMT'
                    expires = datetime.strptime(not_after, "%b %d %H:%M:%S %Y %Z").replace(
                        tzinfo=timezone.utc
                    )
                    days = (expires - datetime.now(timezone.utc)).days
                    log(f"Сертификат до: {not_after} ({days} дн.)")
                    sev = "high" if days < 14 else ("medium" if days < 45 else "info")
                    result.add(sev, "Срок сертификата", f"{not_after} ({days} дней)")

                subject = dict(x[0] for x in cert.get("subject", ()))
                issuer = dict(x[0] for x in cert.get("issuer", ()))
                result.add("info", "Subject CN", subject.get("commonName", "?"))
                result.add("info", "Issuer", issuer.get("commonName", "?"))
                result.raw = {
                    "version": version,
                    "cipher": cipher,
                    "notAfter": not_after,
                    "subject": subject,
                    "issuer": issuer,
                }
    except ssl.SSLError as exc:
        result.add("high", "SSL ошибка", str(exc))
        log(f"SSLError: {exc}")
    except OSError as exc:
        raise RuntimeError(f"Не удалось подключиться к {host}:{port}: {exc}") from exc

    progress(100)
    return result.finish(f"SSL/TLS аудит {host}:{port}")
