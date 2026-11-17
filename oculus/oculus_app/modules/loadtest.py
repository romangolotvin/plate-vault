"""Controlled load test for own / whitelisted sites only."""

from __future__ import annotations

import statistics
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Callable

import requests

from .. import config as cfg
from ..core.results import ModuleResult
from ..core.scope import Scope


def run_load_test(
    target: str,
    *,
    log: Callable[[str], None],
    progress: Callable[[int], None],
    should_cancel: Callable[[], bool],
    rps: int = 5,
    concurrency: int = 4,
    duration_sec: int = 10,
) -> ModuleResult:
    scope = Scope.load()
    url = target.strip()
    if not url.startswith(("http://", "https://")):
        url = "https://" + url
    host = scope.require(url)
    result = ModuleResult(module="loadtest", target=host)

    rps = max(1, min(int(rps), cfg.LOAD_MAX_RPS))
    concurrency = max(1, min(int(concurrency), cfg.LOAD_MAX_CONCURRENCY))
    duration_sec = max(1, min(int(duration_sec), cfg.LOAD_MAX_DURATION_SEC))

    log(
        f"Нагрузка (свои/whitelist): {rps} RPS, concurrency={concurrency}, "
        f"{duration_sec}s → {url}"
    )
    log("Это НЕ DDoS: жёсткие caps + kill-switch")

    session = requests.Session()
    session.headers["User-Agent"] = "Oculus/0.1 (authorized load test)"

    latencies: list[float] = []
    errors = 0
    ok = 0
    status_counts: dict[int, int] = {}
    start = time.monotonic()
    interval = 1.0 / rps
    total_planned = rps * duration_sec
    sent = 0

    def one_request() -> tuple[float, int | None, str | None]:
        t0 = time.monotonic()
        try:
            resp = session.get(url, timeout=5)
            return (time.monotonic() - t0) * 1000.0, resp.status_code, None
        except requests.RequestException as exc:
            return (time.monotonic() - t0) * 1000.0, None, str(exc)

    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        futures = []
        next_at = start
        while time.monotonic() - start < duration_sec:
            if should_cancel():
                log("Kill-switch: остановка")
                break
            now = time.monotonic()
            if now < next_at:
                time.sleep(min(0.01, next_at - now))
                continue
            futures.append(pool.submit(one_request))
            sent += 1
            next_at += interval
            progress(int(min(99, (sent / max(total_planned, 1)) * 100)))

            # Drain completed
            done = [f for f in futures if f.done()]
            for f in done:
                futures.remove(f)
                latency, code, err = f.result()
                latencies.append(latency)
                if err or code is None or code >= 500:
                    errors += 1
                    if err:
                        log(f"err: {err}")
                else:
                    ok += 1
                if code is not None:
                    status_counts[code] = status_counts.get(code, 0) + 1

        for f in as_completed(futures):
            latency, code, err = f.result()
            latencies.append(latency)
            if err or code is None or code >= 500:
                errors += 1
            else:
                ok += 1
            if code is not None:
                status_counts[code] = status_counts.get(code, 0) + 1

    if latencies:
        p50 = statistics.median(latencies)
        p95 = sorted(latencies)[max(0, int(len(latencies) * 0.95) - 1)]
        avg = statistics.mean(latencies)
        log(f"Отправлено: {len(latencies)}; OK={ok}; errors={errors}")
        log(f"latency ms: avg={avg:.1f} p50={p50:.1f} p95={p95:.1f}")
        result.add("info", "Запросов", str(len(latencies)))
        result.add("info", "Ошибки", str(errors))
        result.add("info", "Latency avg/p50/p95 (ms)", f"{avg:.1f} / {p50:.1f} / {p95:.1f}")
        if errors / max(len(latencies), 1) > 0.1:
            result.add("high", "Точка отказа", "Доля ошибок > 10% при заданной нагрузке")
        result.raw = {
            "rps": rps,
            "concurrency": concurrency,
            "duration_sec": duration_sec,
            "ok": ok,
            "errors": errors,
            "status_counts": status_counts,
            "latency_avg_ms": avg,
            "latency_p50_ms": p50,
            "latency_p95_ms": p95,
        }
    else:
        result.add("low", "Нагрузка", "Запросы не отправлены")

    progress(100)
    return result.finish("Нагрузочный тест завершён")
