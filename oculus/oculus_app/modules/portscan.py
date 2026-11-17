"""TCP port scanner with rate limiting (whitelist only)."""

from __future__ import annotations

import socket
from typing import Callable

from ..core.results import ModuleResult
from ..core.scope import Scope

DEFAULT_PORTS = [
    21,
    22,
    25,
    53,
    80,
    110,
    143,
    443,
    445,
    3306,
    3389,
    5432,
    5900,
    6379,
    8080,
    8443,
]

ADMIN_PORTS = {22: "SSH", 3389: "RDP", 5900: "VNC", 3306: "MySQL", 5432: "PostgreSQL"}


def run_port_scan(
    target: str,
    *,
    log: Callable[[str], None],
    progress: Callable[[int], None],
    should_cancel: Callable[[], bool],
    ports: list[int] | None = None,
    timeout: float = 0.6,
) -> ModuleResult:
    scope = Scope.load()
    host = scope.require(target)
    result = ModuleResult(module="portscan", target=host)
    port_list = ports or DEFAULT_PORTS
    open_ports: list[dict] = []

    try:
        ip = socket.gethostbyname(host)
    except OSError as exc:
        raise RuntimeError(f"Не удалось резолвить {host}: {exc}") from exc

    log(f"Сканирование {host} ({ip}), портов: {len(port_list)}")
    for i, port in enumerate(port_list):
        if should_cancel():
            break
        progress(int((i / max(len(port_list), 1)) * 100))
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        try:
            code = sock.connect_ex((ip, port))
            if code == 0:
                banner = ""
                try:
                    sock.settimeout(0.4)
                    # Best-effort banner grab (read-only)
                    data = sock.recv(128)
                    banner = data.decode("utf-8", errors="replace").strip()
                except OSError:
                    banner = ""
                service = ADMIN_PORTS.get(port, "unknown")
                open_ports.append({"port": port, "banner": banner, "service": service})
                log(f"Открыт {port}/tcp ({service})" + (f" — {banner[:60]}" if banner else ""))
                sev = "medium" if port in ADMIN_PORTS else "info"
                result.add(
                    sev,
                    f"Открытый порт {port}",
                    f"Сервис: {service}",
                    evidence=banner[:120],
                )
        finally:
            sock.close()

    result.raw = {"ip": ip, "open": open_ports}
    return result.finish(f"Открытых портов: {len(open_ports)}")
