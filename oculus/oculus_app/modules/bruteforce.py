"""Dictionary credential check with rate limits (authorized targets only)."""

from __future__ import annotations

import time
from typing import Callable

import requests

from .. import config as cfg
from ..core.results import ModuleResult
from ..core.scope import Scope

DEFAULT_USERNAMES = ["admin", "user", "test"]
DEFAULT_PASSWORDS = ["admin", "password", "123456", "test", "changeme"]


def run_dict_bruteforce(
    target: str,
    *,
    log: Callable[[str], None],
    progress: Callable[[int], None],
    should_cancel: Callable[[], bool],
    usernames: list[str] | None = None,
    passwords: list[str] | None = None,
    delay_ms: int = cfg.BRUTE_DEFAULT_DELAY_MS,
) -> ModuleResult:
    """
    Attempts HTTP Basic Auth against the target URL using a small dictionary.
    Stops on first success; respects delay and attempt cap.
    """
    scope = Scope.load()
    url = target.strip()
    if not url.startswith(("http://", "https://")):
        url = "https://" + url
    host = scope.require(url)
    result = ModuleResult(module="bruteforce", target=host)

    users = usernames or DEFAULT_USERNAMES
    pwds = passwords or DEFAULT_PASSWORDS
    pairs = [(u, p) for u in users for p in pwds]
    max_attempts = min(len(pairs), cfg.BRUTE_MAX_ATTEMPTS_PER_MIN)
    pairs = pairs[:max_attempts]

    log(f"Словарь: {len(users)} users × {len(pwds)} passwords → до {max_attempts} попыток")
    log(f"Задержка между попытками: {delay_ms} мс")
    session = requests.Session()
    session.headers["User-Agent"] = "Oculus/0.1 (authorized auth check)"

    try:
        bare = session.get(url, timeout=8)
        log(f"Без auth: HTTP {bare.status_code}")
        if bare.status_code not in (401, 403):
            result.add(
                "info",
                "Basic Auth",
                "Цель не отвечает 401/403 без учётных данных — словарь Basic Auth может быть неприменим",
            )
    except requests.RequestException as exc:
        raise RuntimeError(f"Недоступна цель: {exc}") from exc

    found_user = None
    for i, (user, password) in enumerate(pairs):
        if should_cancel():
            break
        progress(int((i / max(len(pairs), 1)) * 100))
        try:
            resp = session.get(url, auth=(user, password), timeout=8)
            log(f"Попытка {i + 1}/{len(pairs)}: {user} / *** → HTTP {resp.status_code}")
            if resp.status_code == 200 and bare.status_code in (401, 403):
                found_user = user
                result.add(
                    "high",
                    "Слабые учётные данные",
                    f"Успешный вход: пользователь «{user}»",
                    evidence=f"HTTP {resp.status_code}",
                )
                log(f"Успех: {user} (пароль скрыт в отчёте)")
                break
            if resp.status_code == 429:
                result.add("medium", "Lockout / rate limit", "Сервер вернул 429 — останавливаемся")
                log("HTTP 429 — возможная защита от перебора")
                break
        except requests.RequestException as exc:
            log(f"Ошибка: {exc}")
            result.add("low", "Ошибка запроса", str(exc))
            break
        time.sleep(max(delay_ms, 50) / 1000.0)

    if not found_user:
        result.add("info", "Брутфорс", "Совпадений в словаре не найдено")
        log("Совпадений нет")

    result.raw = {"attempts": max_attempts, "found": bool(found_user)}
    progress(100)
    return result.finish("Проверка словаря завершена")
