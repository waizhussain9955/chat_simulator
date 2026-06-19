# Chat Conversation Simulator

A **Python desktop application** for educational and testing purposes that simulates human-like chat conversations by automating keyboard input into any text field.

---

## Features

| Feature | Details |
|---------|---------|
| 🤖 Human-like typing | Random keystroke delays, optional typo + auto-correction |
| 💬 Conversation pairs | Unlimited message / reply pairs |
| ⏱️ Smart delays | Random 5–15 s pause between each turn |
| 💾 Persistence | Save / Load conversations as JSON |
| ✏️ Live editor | JSON editor with Format & Clear buttons |
| ⚙️ Settings panel | Tunable delays, countdown, typo toggle |
| 🛑 Safe stop | Emergency Stop button + PyAutoGUI FAILSAFE |

---

## Project Structure

```
chat_simulator/
├── main.py                  ← entry point
├── requirements.txt
├── automation/
│   ├── __init__.py
│   ├── typer.py             ← human-like keystroke engine
│   └── session.py           ← conversation session orchestrator
├── data/
│   ├── __init__.py
│   └── storage.py           ← JSON save / load
└── gui/
    ├── __init__.py
    ├── app.py               ← main Tkinter window
    └── widgets.py           ← reusable widgets
```

---

## Quick Start

### 1. Install dependencies

```bash
pip install -r requirements.txt
```

### 2. Run the application

```bash
python main.py
```

### 3. Usage Workflow

1. **Add conversations** in the JSON editor (or load a saved `.json` file).
2. Adjust **Settings** (countdown, delays, typo simulation).
3. Click **▶ Start**.
4. During the countdown, **switch to any chat window** and click inside the text input box.
5. The program will automatically type and send each message/reply pair.
6. Click **■ Stop** or move the mouse to the **top-left corner** to abort at any time.

---

## Conversation JSON Format

```json
[
  {
    "message": "Hey, how are you?",
    "reply": "I'm good, thanks! How about you?"
  },
  {
    "message": "Busy ho?",
    "reply": "Thoda busy hoon, bolo kya kaam hai?"
  }
]
```

---

## Safety

- **PyAutoGUI FAILSAFE** is always enabled — move the mouse to the **top-left corner** to instantly abort.
- The **■ Stop** button signals the worker thread to halt gracefully.
- The program never accesses the internet or any external service.

---

## Requirements

- Python 3.12+
- `pyautogui`
- `pyperclip`
- `tkinter` (built into Python on Windows/macOS/Linux)
