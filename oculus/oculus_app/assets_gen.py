"""Generate decorative PNGs and ensure sound exists."""

from __future__ import annotations

import math

from PIL import Image, ImageDraw

from . import config as cfg
from .audio import ensure_bubble_sound


def _hero_eye(path) -> None:
    w, h = 960, 220
    img = Image.new("RGB", (w, h), (11, 26, 51))
    draw = ImageDraw.Draw(img)
    # Gradient-ish bands
    for y in range(h):
        t = y / h
        r = int(11 + 20 * t)
        g = int(26 + 30 * t)
        b = int(51 + 40 * t)
        draw.line([(0, y), (w, y)], fill=(r, g, b))
    # Soft circles / “iris”
    cx, cy = w // 2, h // 2
    for radius, color in [
        (90, (30, 70, 140)),
        (60, (61, 126, 255)),
        (28, (10, 18, 36)),
        (10, (232, 240, 255)),
    ]:
        draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=color)
    # Orbit dots
    for i in range(12):
        ang = i / 12 * math.tau
        x = cx + int(math.cos(ang) * 150)
        y = cy + int(math.sin(ang) * 55)
        draw.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(91, 147, 255))
    img.save(path)


def generate_all() -> None:
    cfg.ensure_data_dirs()
    ensure_bubble_sound()
    hero = cfg.IMAGES_DIR / "hero_eye.png"
    if not hero.exists():
        _hero_eye(hero)
