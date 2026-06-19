"""
main.py
-------
Entry point for the Chat Conversation Simulator.

Usage:
    python main.py
"""

import sys

# ── dependency check ─────────────────────────────────────────────────────────
REQUIRED = ["pyautogui", "pyperclip"]
missing  = []
for pkg in REQUIRED:
    try:
        __import__(pkg)
    except ImportError:
        missing.append(pkg)

if missing:
    print(
        f"[ERROR] Missing packages: {', '.join(missing)}\n"
        f"Run:  pip install {' '.join(missing)}"
    )
    sys.exit(1)

# ── launch ───────────────────────────────────────────────────────────────────
from gui.app import ChatSimulatorApp   # noqa: E402


def main():
    app = ChatSimulatorApp()
    app.mainloop()


if __name__ == "__main__":
    main()
