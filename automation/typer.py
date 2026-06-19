"""
automation/typer.py
-------------------
Core automation engine: handles human-like typing, random delays,
optional typo simulation, and thread-safe stop control.
"""

import time
import random
import threading
import pyautogui

# ── PyAutoGUI safety ──────────────────────────────────────────────────────────
pyautogui.FAILSAFE = True          # move mouse to top-left corner to abort
pyautogui.PAUSE    = 0.0           # we manage our own pauses


class TypingEngine:
    """
    Simulates human-like typing with:
      - random character-level delay
      - optional typo injection + correction
      - random inter-message delay
      - thread-safe stop flag
    """

    # ── tuneable constants ────────────────────────────────────────────────
    MIN_CHAR_DELAY   = 0.04   # seconds between keystrokes (fastest)
    MAX_CHAR_DELAY   = 0.14   # seconds between keystrokes (slowest)
    TYPO_PROBABILITY = 0.04   # 4% chance of a typo per character
    BACKSPACE_DELAY  = 0.08   # delay before correcting typo

    def __init__(self):
        self._stop_event = threading.Event()

    # ── public interface ──────────────────────────────────────────────────

    def stop(self):
        """Signal the engine to abort as soon as possible."""
        self._stop_event.set()

    def reset(self):
        """Clear the stop flag before starting a new session."""
        self._stop_event.clear()

    def is_stopped(self) -> bool:
        return self._stop_event.is_set()

    def type_message(self, text: str, enable_typos: bool = True) -> bool:
        """
        Type *text* one character at a time with human-like timing.

        Returns True on success, False if stopped early.
        """
        for char in text:
            if self._stop_event.is_set():
                return False

            # ── optional typo simulation ──────────────────────────────
            if enable_typos and self._should_make_typo(char):
                wrong_char = self._nearby_key(char)
                pyautogui.typewrite(wrong_char, interval=0)
                time.sleep(self.BACKSPACE_DELAY)
                if self._stop_event.is_set():
                    return False
                pyautogui.press('backspace')
                time.sleep(self.BACKSPACE_DELAY / 2)

            # ── type the correct character ────────────────────────────
            # typewrite can't handle non-ASCII; fall back to pyperclip approach
            try:
                pyautogui.typewrite(char, interval=0)
            except Exception:
                # For special / unicode chars, use clipboard paste
                import pyperclip
                pyperclip.copy(char)
                pyautogui.hotkey('ctrl', 'v')

            delay = random.uniform(self.MIN_CHAR_DELAY, self.MAX_CHAR_DELAY)
            time.sleep(delay)

        return True

    def send_message(self, text: str, enable_typos: bool = True) -> bool:
        """
        Type the message then press Enter to send.

        Returns True on success, False if stopped early.
        """
        success = self.type_message(text, enable_typos)
        if not success:
            return False
        time.sleep(random.uniform(0.3, 0.7))  # brief pause before hitting Enter
        pyautogui.press('enter')
        return True

    def random_delay(self, min_sec: float = 5.0, max_sec: float = 15.0) -> bool:
        """
        Sleep for a random duration, waking every 0.5 s to honour stop requests.

        Returns True if the full delay elapsed, False if stopped early.
        """
        target = time.time() + random.uniform(min_sec, max_sec)
        while time.time() < target:
            if self._stop_event.is_set():
                return False
            time.sleep(0.5)
        return True

    # ── private helpers ───────────────────────────────────────────────────

    @staticmethod
    def _should_make_typo(char: str) -> bool:
        """Only simulate typos for alphabetic characters."""
        return char.isalpha() and random.random() < TypingEngine.TYPO_PROBABILITY

    @staticmethod
    def _nearby_key(char: str) -> str:
        """Return a keyboard-adjacent key for a given character."""
        neighbours = {
            'a': 'sq', 'b': 'vn', 'c': 'xv', 'd': 'sf', 'e': 'wr',
            'f': 'dg', 'g': 'fh', 'h': 'gj', 'i': 'uo', 'j': 'hk',
            'k': 'jl', 'l': 'k',  'm': 'n',  'n': 'mb', 'o': 'ip',
            'p': 'o',  'q': 'w',  'r': 'et', 's': 'ad', 't': 'ry',
            'u': 'yi', 'v': 'cb', 'w': 'qe', 'x': 'zc', 'y': 'tu',
            'z': 'x',
        }
        lc = char.lower()
        pool = neighbours.get(lc, lc)
        wrong = random.choice(pool)
        return wrong.upper() if char.isupper() else wrong
