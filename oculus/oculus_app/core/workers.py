"""Base QThread worker for long-running module jobs."""

from __future__ import annotations

from typing import Any, Callable

from PySide6.QtCore import QThread, Signal


class ModuleWorker(QThread):
    log = Signal(str)
    progress = Signal(int)
    finished_ok = Signal(object)
    failed = Signal(str)

    def __init__(self, fn: Callable[..., Any], *args: Any, **kwargs: Any) -> None:
        super().__init__()
        self._fn = fn
        self._args = args
        self._kwargs = kwargs
        self._cancel = False

    def cancel(self) -> None:
        self._cancel = True

    @property
    def cancelled(self) -> bool:
        return self._cancel

    def run(self) -> None:
        try:
            def _log(msg: str) -> None:
                self.log.emit(msg)

            def _progress(value: int) -> None:
                self.progress.emit(max(0, min(100, int(value))))

            def _should_cancel() -> bool:
                return self._cancel

            result = self._fn(
                *self._args,
                log=_log,
                progress=_progress,
                should_cancel=_should_cancel,
                **self._kwargs,
            )
            if self._cancel:
                self.failed.emit("Отменено пользователем")
            else:
                self.finished_ok.emit(result)
        except Exception as exc:  # noqa: BLE001 — surface to UI
            self.failed.emit(str(exc))
