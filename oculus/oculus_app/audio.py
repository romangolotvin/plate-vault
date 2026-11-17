"""Click / bubble sound playback for Oculus buttons."""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

from . import config as cfg
from .config import load_settings


def ensure_bubble_sound() -> Path:
    """Generate a short 'bubble pop' WAV if missing."""
    cfg.ensure_data_dirs()
    path = cfg.SOUNDS_DIR / "bubble_pop.wav"
    if path.exists() and path.stat().st_size > 44:
        return path

    sample_rate = 22050
    duration = 0.09
    frequency = 880.0
    n_samples = int(sample_rate * duration)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        frames = bytearray()
        for i in range(n_samples):
            t = i / sample_rate
            env = math.exp(-t * 38)
            freq = frequency * (1.0 - 0.35 * t / duration)
            sample = env * math.sin(2 * math.pi * freq * t)
            if i < 40:
                sample += (1 - i / 40) * 0.35 * math.sin(2 * math.pi * 2200 * t)
            value = max(-1.0, min(1.0, sample * 0.55))
            frames += struct.pack("<h", int(value * 32767))
        wf.writeframes(frames)
    return path


class SoundBus:
    """Lightweight click sound helper (safe if multimedia unavailable)."""

    def __init__(self) -> None:
        self._effect = None
        self._ready = False
        try:
            from PySide6.QtCore import QUrl
            from PySide6.QtMultimedia import QSoundEffect

            path = ensure_bubble_sound()
            effect = QSoundEffect()
            effect.setSource(QUrl.fromLocalFile(str(path)))
            effect.setVolume(0.45)
            self._effect = effect
            self._ready = True
        except Exception:
            self._effect = None
            self._ready = False

    def play_click(self) -> None:
        settings = load_settings()
        if not settings.get("sound_enabled", True):
            return
        if self._ready and self._effect is not None:
            self._effect.play()


_bus: SoundBus | None = None


def get_sound_bus() -> SoundBus:
    global _bus
    if _bus is None:
        _bus = SoundBus()
    return _bus
