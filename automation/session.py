"""
automation/session.py
---------------------
Orchestrates the full conversation session:
  1. Countdown before start
  2. Iterates through (message, reply) pairs
  3. Calls TypingEngine for each turn
  4. Fires progress / status callbacks to the GUI layer
"""

import time
import threading
from typing import Callable, List, Dict

from automation.typer import TypingEngine


class ConversationSession:
    """
    Runs a conversation script in a background thread.

    Callbacks (all optional, called on the worker thread):
      on_status(msg: str)           – short status line
      on_progress(current, total)   – pair index progress
      on_countdown(seconds_left)    – countdown ticks
      on_finished(success: bool)    – session ended
    """

    def __init__(
        self,
        conversations: List[Dict[str, str]],
        enable_typos: bool = True,
        start_delay: int = 10,
        min_msg_delay: float = 5.0,
        max_msg_delay: float = 15.0,
        on_status:    Callable[[str], None]        = None,
        on_progress:  Callable[[int, int], None]   = None,
        on_countdown: Callable[[int], None]        = None,
        on_finished:  Callable[[bool], None]       = None,
    ):
        self.conversations  = conversations
        self.enable_typos   = enable_typos
        self.start_delay    = start_delay
        self.min_msg_delay  = min_msg_delay
        self.max_msg_delay  = max_msg_delay

        # callbacks
        self._on_status    = on_status    or (lambda m: None)
        self._on_progress  = on_progress  or (lambda c, t: None)
        self._on_countdown = on_countdown or (lambda s: None)
        self._on_finished  = on_finished  or (lambda ok: None)

        self._engine = TypingEngine()
        self._thread: threading.Thread | None = None

    # ── public API ────────────────────────────────────────────────────────

    def start(self):
        """Launch the session in a daemon background thread."""
        if self._thread and self._thread.is_alive():
            return  # already running

        self._engine.reset()
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def stop(self):
        """Request graceful abort."""
        self._engine.stop()

    def is_running(self) -> bool:
        return self._thread is not None and self._thread.is_alive()

    # ── internal session logic ────────────────────────────────────────────

    def _run(self):
        try:
            # ── Phase 1: countdown ────────────────────────────────────
            self._on_status(f"⏳ Starting in {self.start_delay} seconds… Click your chat window now!")
            for remaining in range(self.start_delay, 0, -1):
                if self._engine.is_stopped():
                    self._finish(False)
                    return
                self._on_countdown(remaining)
                time.sleep(1)

            if self._engine.is_stopped():
                self._finish(False)
                return

            total = len(self.conversations)

            # ── Phase 2: send pairs ───────────────────────────────────
            for idx, pair in enumerate(self.conversations):
                if self._engine.is_stopped():
                    self._finish(False)
                    return

                self._on_progress(idx + 1, total)

                # ── Send the "Message" side ───────────────────────────
                msg = pair.get("message", "").strip()
                if msg:
                    self._on_status(f"✉️  [{idx+1}/{total}] Typing message…")
                    ok = self._engine.send_message(msg, self.enable_typos)
                    if not ok:
                        self._finish(False)
                        return

                    # wait before reply
                    self._on_status(f"⏱️  [{idx+1}/{total}] Waiting before reply…")
                    ok = self._engine.random_delay(self.min_msg_delay, self.max_msg_delay)
                    if not ok:
                        self._finish(False)
                        return

                # ── Send the "Reply" side ─────────────────────────────
                reply = pair.get("reply", "").strip()
                if reply:
                    self._on_status(f"💬 [{idx+1}/{total}] Typing reply…")
                    ok = self._engine.send_message(reply, self.enable_typos)
                    if not ok:
                        self._finish(False)
                        return

                # wait before next pair (skip after last)
                if idx < total - 1:
                    self._on_status(f"⏱️  [{idx+1}/{total}] Waiting before next pair…")
                    ok = self._engine.random_delay(self.min_msg_delay, self.max_msg_delay)
                    if not ok:
                        self._finish(False)
                        return

            self._finish(True)

        except Exception as exc:
            self._on_status(f"❌ Error: {exc}")
            self._finish(False)

    def _finish(self, success: bool):
        if success:
            self._on_status("✅ All conversations completed successfully!")
        else:
            self._on_status("🛑 Session stopped.")
        self._on_finished(success)
