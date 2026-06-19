"""
gui/app.py
----------
Main Tkinter application window.
Wires together the GUI, ConversationSession, and ConversationStorage.
"""

import json
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from typing import List, Dict

from automation.session import ConversationSession
from data.storage import ConversationStorage
from gui.widgets import (
    ConversationEditor,
    StatusBar,
    CountdownLabel,
    ProgressRow,
    SettingsPanel,
)


class ChatSimulatorApp(tk.Tk):
    """Root application window."""

    APP_TITLE   = "Chat Conversation Simulator"
    MIN_WIDTH   = 860
    MIN_HEIGHT  = 640

    # ── default sample data ──────────────────────────────────────────────
    SAMPLE_CONVERSATIONS: List[Dict[str, str]] = [
        {"message": "Hey, how are you?",               "reply": "I'm good, thanks! How about you?"},
        {"message": "Are you online?",                  "reply": "Yes, I'm here. What's up?"},
        {"message": "Busy ho?",                         "reply": "Thoda busy hoon, bolo kya kaam hai?"},
        {"message": "Can we talk for a minute?",        "reply": "Sure, go ahead!"},
        {"message": "Did you check the file I sent?",   "reply": "Yes, just checked it. Looks good!"},
    ]

    def __init__(self):
        super().__init__()
        self.title(self.APP_TITLE)
        self.minsize(self.MIN_WIDTH, self.MIN_HEIGHT)
        self.configure(bg="#1a1a2e")

        self._session: ConversationSession | None = None
        self._build_ui()
        self._populate_sample()

    # ── UI construction ───────────────────────────────────────────────────

    def _build_ui(self):
        # ── top header ──────────────────────────────────────────────────
        header = tk.Frame(self, bg="#16213e", pady=12)
        header.pack(fill="x")

        tk.Label(
            header,
            text="💬  Chat Conversation Simulator",
            font=("Segoe UI", 18, "bold"),
            fg="#e94560",
            bg="#16213e",
        ).pack()
        tk.Label(
            header,
            text="Educational & Testing Tool  •  Human-like Typing Automation",
            font=("Segoe UI", 9),
            fg="#8892b0",
            bg="#16213e",
        ).pack()

        # ── main body (left editor + right settings) ────────────────────
        body = tk.Frame(self, bg="#1a1a2e")
        body.pack(fill="both", expand=True, padx=14, pady=10)

        # left: conversation editor
        left = tk.Frame(body, bg="#1a1a2e")
        left.pack(side="left", fill="both", expand=True)

        tk.Label(
            left,
            text="Conversation Pairs (JSON)",
            font=("Segoe UI", 10, "bold"),
            fg="#ccd6f6",
            bg="#1a1a2e",
        ).pack(anchor="w")

        self.editor = ConversationEditor(left)
        self.editor.pack(fill="both", expand=True, pady=(4, 0))

        # right: settings + controls
        right = tk.Frame(body, bg="#1a1a2e", width=230)
        right.pack(side="right", fill="y", padx=(12, 0))
        right.pack_propagate(False)

        self.settings = SettingsPanel(right)
        self.settings.pack(fill="x")

        self._build_buttons(right)

        # ── progress row ────────────────────────────────────────────────
        self.progress_row = ProgressRow(self)
        self.progress_row.pack(fill="x", padx=14, pady=(0, 4))

        # ── countdown label ─────────────────────────────────────────────
        self.countdown_lbl = CountdownLabel(self)
        self.countdown_lbl.pack()

        # ── status bar ──────────────────────────────────────────────────
        self.status_bar = StatusBar(self)
        self.status_bar.pack(fill="x", side="bottom")

    def _build_buttons(self, parent: tk.Frame):
        btn_frame = tk.Frame(parent, bg="#1a1a2e")
        btn_frame.pack(fill="x", pady=(16, 0))

        style_green  = {"bg": "#00b894", "fg": "white", "activebackground": "#00cec9"}
        style_red    = {"bg": "#e17055", "fg": "white", "activebackground": "#d63031"}
        style_blue   = {"bg": "#0984e3", "fg": "white", "activebackground": "#74b9ff"}
        style_purple = {"bg": "#6c5ce7", "fg": "white", "activebackground": "#a29bfe"}
        common       = {"font": ("Segoe UI", 10, "bold"), "relief": "flat",
                        "cursor": "hand2", "pady": 8, "bd": 0}

        buttons = [
            ("▶  Start",         {**style_green,  **common}, self._on_start),
            ("■  Stop",          {**style_red,    **common}, self._on_stop),
            ("💾  Save JSON",    {**style_blue,   **common}, self._on_save),
            ("📂  Load JSON",    {**style_purple, **common}, self._on_load),
            ("🔄  Reset Sample", {"bg":"#636e72","fg":"white","activebackground":"#b2bec3",
                                  **common},                 self._populate_sample),
        ]

        for text, style, cmd in buttons:
            btn = tk.Button(btn_frame, text=text, command=cmd, **style)
            btn.pack(fill="x", pady=3)

    # ── event handlers ────────────────────────────────────────────────────

    def _on_start(self):
        if self._session and self._session.is_running():
            messagebox.showwarning("Already Running", "A session is already in progress.")
            return

        convs = self._parse_editor()
        if convs is None:
            return
        if not convs:
            messagebox.showwarning("Empty", "Please add at least one conversation pair.")
            return

        settings = self.settings.get_values()

        self._session = ConversationSession(
            conversations  = convs,
            enable_typos   = settings["enable_typos"],
            start_delay    = settings["start_delay"],
            min_msg_delay  = settings["min_delay"],
            max_msg_delay  = settings["max_delay"],
            on_status      = self._cb_status,
            on_progress    = self._cb_progress,
            on_countdown   = self._cb_countdown,
            on_finished    = self._cb_finished,
        )
        self._session.start()
        self.status_bar.set("🚀 Session started. Switch to your chat window now!", color="#00b894")

    def _on_stop(self):
        if self._session:
            self._session.stop()
        self.status_bar.set("🛑 Stop requested…", color="#e17055")

    def _on_save(self):
        convs = self._parse_editor()
        if convs is None:
            return
        path = filedialog.asksaveasfilename(
            defaultextension=".json",
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")],
            title="Save Conversations",
        )
        if not path:
            return
        try:
            ConversationStorage.save(convs, path)
            self.status_bar.set(f"💾 Saved to {path}", color="#00b894")
        except Exception as exc:
            messagebox.showerror("Save Error", str(exc))

    def _on_load(self):
        path = filedialog.askopenfilename(
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")],
            title="Load Conversations",
        )
        if not path:
            return
        try:
            convs = ConversationStorage.load(path)
            self.editor.set_json(convs)
            self.status_bar.set(f"📂 Loaded {len(convs)} pairs from {path}", color="#6c5ce7")
        except Exception as exc:
            messagebox.showerror("Load Error", str(exc))

    def _populate_sample(self):
        self.editor.set_json(self.SAMPLE_CONVERSATIONS)
        self.status_bar.set("🔄 Sample conversations loaded.", color="#0984e3")

    # ── session callbacks (called on worker thread → must use `after`) ────

    def _cb_status(self, msg: str):
        self.after(0, lambda: self.status_bar.set(msg))

    def _cb_progress(self, current: int, total: int):
        self.after(0, lambda: self.progress_row.update(current, total))

    def _cb_countdown(self, seconds: int):
        self.after(0, lambda: self.countdown_lbl.set(seconds))

    def _cb_finished(self, success: bool):
        self.after(0, lambda: self.countdown_lbl.clear())
        self.after(0, lambda: self.progress_row.reset())

    # ── helpers ───────────────────────────────────────────────────────────

    def _parse_editor(self) -> List[Dict[str, str]] | None:
        """Parse the JSON editor; show error and return None on failure."""
        raw = self.editor.get_json_text()
        try:
            data = json.loads(raw)
            ConversationStorage._validate(data)   # type: ignore[attr-defined]
            return data
        except (json.JSONDecodeError, ValueError) as exc:
            messagebox.showerror("Invalid JSON", f"Please fix the conversation data:\n\n{exc}")
            return None
