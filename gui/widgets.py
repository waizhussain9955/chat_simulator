"""
gui/widgets.py
--------------
Reusable Tkinter widget components used by the main app window.
"""

import json
import tkinter as tk
from tkinter import ttk
from typing import List, Dict, Any


# ── colour palette ──────────────────────────────────────────────────────────
BG_DARK   = "#1a1a2e"
BG_PANEL  = "#16213e"
BG_INPUT  = "#0f3460"
FG_MAIN   = "#ccd6f6"
FG_DIM    = "#8892b0"
FG_ACCENT = "#e94560"
FG_GREEN  = "#00b894"
FG_BLUE   = "#0984e3"


# ────────────────────────────────────────────────────────────────────────────
class ConversationEditor(tk.Frame):
    """
    A text widget with JSON syntax editing for conversation pairs.
    Includes a scrollbar and a small toolbar (Format / Clear).
    """

    def __init__(self, parent, **kw):
        super().__init__(parent, bg=BG_DARK, **kw)
        self._build()

    def _build(self):
        # toolbar
        toolbar = tk.Frame(self, bg=BG_DARK)
        toolbar.pack(fill="x", pady=(0, 4))

        for label, cmd in [("✨ Format", self._format_json), ("🗑 Clear", self._clear)]:
            tk.Button(
                toolbar, text=label, command=cmd,
                bg=BG_PANEL, fg=FG_DIM, relief="flat",
                font=("Segoe UI", 8), cursor="hand2", padx=8, pady=2,
            ).pack(side="left", padx=(0, 4))

        tk.Label(
            toolbar,
            text='[{"message": "...", "reply": "..."}, …]',
            font=("Consolas", 8),
            fg=FG_DIM, bg=BG_DARK,
        ).pack(side="left")

        # text area + scrollbar
        container = tk.Frame(self, bg=BG_INPUT, bd=1, relief="sunken")
        container.pack(fill="both", expand=True)

        scrollbar = tk.Scrollbar(container, bg=BG_PANEL, troughcolor=BG_DARK)
        scrollbar.pack(side="right", fill="y")

        self._text = tk.Text(
            container,
            yscrollcommand=scrollbar.set,
            bg=BG_INPUT, fg=FG_MAIN,
            insertbackground=FG_ACCENT,
            selectbackground=FG_ACCENT,
            font=("Consolas", 10),
            relief="flat", bd=8, wrap="none",
            undo=True,
        )
        self._text.pack(fill="both", expand=True)
        scrollbar.config(command=self._text.yview)

    # public API
    def get_json_text(self) -> str:
        return self._text.get("1.0", "end-1c").strip()

    def set_json(self, data: Any):
        pretty = json.dumps(data, ensure_ascii=False, indent=2)
        self._text.delete("1.0", "end")
        self._text.insert("1.0", pretty)

    # private
    def _format_json(self):
        raw = self.get_json_text()
        try:
            data = json.loads(raw)
            self.set_json(data)
        except json.JSONDecodeError:
            pass  # leave it alone if invalid

    def _clear(self):
        self._text.delete("1.0", "end")


# ────────────────────────────────────────────────────────────────────────────
class SettingsPanel(tk.LabelFrame):
    """Settings controls: delays, typo toggle, start delay."""

    def __init__(self, parent, **kw):
        super().__init__(
            parent, text=" ⚙  Settings ",
            bg=BG_DARK, fg=FG_ACCENT,
            font=("Segoe UI", 9, "bold"),
            relief="groove", bd=1,
            **kw,
        )
        self._build()

    def _build(self):
        pad = {"padx": 8, "pady": 4}

        # start delay
        self._add_label("Countdown (seconds):", **pad)
        self._start_delay_var = tk.IntVar(value=10)
        self._add_spinbox(self._start_delay_var, 5, 60, **pad)

        # min delay
        self._add_label("Min message delay (s):", **pad)
        self._min_delay_var = tk.DoubleVar(value=5.0)
        self._add_spinbox(self._min_delay_var, 1, 60, **pad)

        # max delay
        self._add_label("Max message delay (s):", **pad)
        self._max_delay_var = tk.DoubleVar(value=15.0)
        self._add_spinbox(self._max_delay_var, 2, 120, **pad)

        # typo toggle
        self._enable_typos_var = tk.BooleanVar(value=True)
        chk = tk.Checkbutton(
            self,
            text="Enable typo simulation",
            variable=self._enable_typos_var,
            bg=BG_DARK, fg=FG_MAIN,
            selectcolor=BG_PANEL,
            activebackground=BG_DARK,
            font=("Segoe UI", 9),
        )
        chk.pack(anchor="w", **pad)

        # divider
        ttk.Separator(self, orient="horizontal").pack(fill="x", padx=8, pady=6)

        # failsafe reminder
        tk.Label(
            self,
            text="⚡ FAILSAFE: Move mouse\nto top-left corner to abort",
            font=("Segoe UI", 8),
            fg="#fdcb6e", bg=BG_DARK,
            justify="left",
        ).pack(anchor="w", padx=8, pady=(0, 6))

    def _add_label(self, text: str, **kw):
        tk.Label(
            self, text=text,
            font=("Segoe UI", 9), fg=FG_DIM, bg=BG_DARK,
        ).pack(anchor="w", **kw)

    def _add_spinbox(self, var, from_: float, to: float, **kw):
        sb = tk.Spinbox(
            self, from_=from_, to=to, textvariable=var,
            bg=BG_INPUT, fg=FG_MAIN, insertbackground=FG_MAIN,
            buttonbackground=BG_PANEL, relief="flat",
            font=("Segoe UI", 9), width=8,
        )
        sb.pack(anchor="w", **kw)

    def get_values(self) -> Dict[str, Any]:
        return {
            "start_delay":   int(self._start_delay_var.get()),
            "min_delay":     float(self._min_delay_var.get()),
            "max_delay":     float(self._max_delay_var.get()),
            "enable_typos":  self._enable_typos_var.get(),
        }


# ────────────────────────────────────────────────────────────────────────────
class ProgressRow(tk.Frame):
    """Progress bar + label showing current / total pairs."""

    def __init__(self, parent, **kw):
        super().__init__(parent, bg=BG_DARK, **kw)
        self._build()

    def _build(self):
        self._label = tk.Label(
            self, text="Pair: — / —",
            font=("Segoe UI", 9), fg=FG_DIM, bg=BG_DARK,
        )
        self._label.pack(side="left", padx=(0, 8))

        style = ttk.Style()
        style.theme_use("default")
        style.configure(
            "Sim.Horizontal.TProgressbar",
            troughcolor=BG_PANEL,
            background=FG_GREEN,
            thickness=12,
        )
        self._bar = ttk.Progressbar(
            self, style="Sim.Horizontal.TProgressbar",
            orient="horizontal", mode="determinate",
        )
        self._bar.pack(side="left", fill="x", expand=True)

    def update(self, current: int, total: int):
        self._label.config(text=f"Pair: {current} / {total}")
        self._bar["maximum"] = total
        self._bar["value"]   = current

    def reset(self):
        self._label.config(text="Pair: — / —")
        self._bar["value"] = 0


# ────────────────────────────────────────────────────────────────────────────
class CountdownLabel(tk.Label):
    """Large countdown display shown during the pre-start delay."""

    def __init__(self, parent, **kw):
        super().__init__(
            parent,
            text="",
            font=("Segoe UI", 28, "bold"),
            fg=FG_ACCENT,
            bg=BG_DARK,
            **kw,
        )

    def set(self, seconds: int):
        self.config(text=f"Starting in  {seconds}s")

    def clear(self):
        self.config(text="")


# ────────────────────────────────────────────────────────────────────────────
class StatusBar(tk.Label):
    """Single-line status bar at the bottom of the window."""

    def __init__(self, parent, **kw):
        super().__init__(
            parent,
            text="Ready. Add conversations and click Start.",
            anchor="w",
            font=("Segoe UI", 9),
            fg=FG_DIM,
            bg=BG_PANEL,
            padx=10,
            pady=5,
            **kw,
        )

    def set(self, message: str, color: str = FG_MAIN):
        self.config(text=message, fg=color)
