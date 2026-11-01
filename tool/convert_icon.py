from pathlib import Path

try:
    from PIL import Image
except ImportError:
    import subprocess
    import sys

    subprocess.check_call([sys.executable, "-m", "pip", "install", "pillow", "-q"])
    from PIL import Image

src = Path(r"E:\dev\plate-vault\assets\app_icon_source.jpg")
dst = Path(r"E:\dev\plate-vault\assets\app_icon.png")
img = Image.open(src).convert("RGB")
# Ensure square icon canvas
side = max(img.size)
canvas = Image.new("RGB", (side, side), (10, 6, 18))
ox = (side - img.size[0]) // 2
oy = (side - img.size[1]) // 2
canvas.paste(img, (ox, oy))
canvas = canvas.resize((1024, 1024), Image.Resampling.LANCZOS)
canvas.save(dst, "PNG")
print(f"OK {dst} {dst.stat().st_size}")
