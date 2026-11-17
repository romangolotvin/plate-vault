@echo off
REM Build Oculus Windows GUI exe (run on Windows with Python + PyInstaller)
python -m pip install -r requirements.txt pyinstaller
python -c "from oculus_app.assets_gen import generate_all; generate_all()"
pyinstaller --noconfirm --windowed --name Oculus --add-data "assets;assets" main.py
echo.
echo Dist: dist\Oculus\Oculus.exe
