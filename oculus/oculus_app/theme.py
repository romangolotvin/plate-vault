"""Dark-blue Qt stylesheet for Oculus."""

from __future__ import annotations

from . import config as cfg


def build_stylesheet() -> str:
    return f"""
    QWidget {{
        background-color: {cfg.COLOR_BG};
        color: {cfg.COLOR_TEXT};
        font-family: "Segoe UI", "Ubuntu", "Noto Sans", sans-serif;
        font-size: 14px;
    }}
    QMainWindow, QDialog {{
        background-color: {cfg.COLOR_BG};
    }}
    QLabel#TitleLabel {{
        font-size: 28px;
        font-weight: 700;
        color: {cfg.COLOR_TEXT};
    }}
    QLabel#SubtitleLabel {{
        font-size: 15px;
        color: {cfg.COLOR_TEXT_MUTED};
    }}
    QLabel#SectionHint {{
        color: {cfg.COLOR_TEXT_MUTED};
        font-size: 13px;
    }}
    QFrame#Sidebar {{
        background-color: {cfg.COLOR_BG_ELEVATED};
        border-right: 1px solid {cfg.COLOR_BORDER};
    }}
    QFrame#ContentCard {{
        background-color: {cfg.COLOR_PANEL};
        border: 1px solid {cfg.COLOR_BORDER};
        border-radius: 16px;
    }}
    QLineEdit, QPlainTextEdit, QSpinBox, QComboBox {{
        background-color: {cfg.COLOR_BG_ELEVATED};
        border: 1px solid {cfg.COLOR_BORDER};
        border-radius: 10px;
        padding: 8px 12px;
        selection-background-color: {cfg.COLOR_ACCENT};
    }}
    QLineEdit:focus, QPlainTextEdit:focus, QSpinBox:focus {{
        border: 1px solid {cfg.COLOR_ACCENT};
    }}
    QPlainTextEdit#LogView {{
        font-family: "Cascadia Code", "Consolas", "Ubuntu Mono", monospace;
        font-size: 12px;
        background-color: #071225;
        border-radius: 12px;
    }}
    QScrollArea {{
        border: none;
        background: transparent;
    }}
    QScrollBar:vertical {{
        background: {cfg.COLOR_BG};
        width: 10px;
        margin: 0;
    }}
    QScrollBar::handle:vertical {{
        background: {cfg.COLOR_BORDER};
        border-radius: 5px;
        min-height: 24px;
    }}
    QProgressBar {{
        background: {cfg.COLOR_BG_ELEVATED};
        border: 1px solid {cfg.COLOR_BORDER};
        border-radius: 8px;
        text-align: center;
        height: 18px;
    }}
    QProgressBar::chunk {{
        background: {cfg.COLOR_ACCENT};
        border-radius: 7px;
    }}
    QCheckBox {{
        spacing: 8px;
    }}
    QCheckBox::indicator {{
        width: 18px;
        height: 18px;
        border-radius: 5px;
        border: 1px solid {cfg.COLOR_BORDER};
        background: {cfg.COLOR_BG_ELEVATED};
    }}
    QCheckBox::indicator:checked {{
        background: {cfg.COLOR_ACCENT};
        border-color: {cfg.COLOR_ACCENT};
    }}
    """
