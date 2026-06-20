# ChatSim Pro 🚀

A premium, modern cross-platform **Flutter application** (for Android, Windows, and Web) designed for educational, testing, and automation workflows. It simulates human-like chat conversations by automating system-wide direct character typing and send-trigger button clicks.

---

## 📱 Scan & Download Direct APK (Android)

Scan this QR code or click the link below to download the latest compiled `chat_simulator.zip` file containing the Android App installer directly:

### [Download chat_simulator.zip Directly](https://github.com/waizhussain9955/chat_simulator/raw/main/chat_simulator.zip)

> [!NOTE]
> Extract the zip file on your phone to find the `chat_simulator.apk` file, then open it to install. 

---

## ✨ Features

| Feature | Details |
|---------|---------|
| 🤖 **Human Typing Simulation** | Types character-by-character with organic random delays (50ms - 150ms) and simulates realistic typo corrections in real-time. |
| ⚡ **Fast & Instant Modes** | **Fast Mode** types with a minimal 10ms delay. **Instant Mode** bypasses typing entirely, copying to the clipboard, simulating `Ctrl+V` (paste), and triggering `Enter` in sub-milliseconds. |
| 🎛️ **Universal Android Automation** | A custom native Android `AccessibilityService` that intercepts text box focuses and directly injects text into any chat app (WhatsApp, Telegram, WA Business, Messenger, etc.) upon focus. |
| 🪟 **Native Windows FFI** | Uses direct Windows APIs (`SendInput` via Dart FFI in `win32`) to write Unicode text directly to active target chat inputs without clipboard dependency. |
| 📂 **Isolated Multi-Project Storage** | Offline-first database architecture using Hive, isolating message libraries, configuration speeds, and sent history per project workspace. |
| 🔄 **3-Slot Rolling Backups** | Automatically makes background backups on edits, maintaining a 3-slot rolling sequence that can be restored with a single click. |
| 📥 **Bulk Actions & Import/Export** | Instantly import and export message data from **JSON**, **CSV**, or **TXT** files. |
| 📊 **Obsidian-Emerald Theme** | High-fidelity glassmorphic dark theme (`#0d1117` background, `#10b981` primary) with a live weekly statistics bar chart. |

---

## 🛠️ Project Structure

```
chat_simulator/
├── android/                  ← Native Android configurations & Accessibility Service
├── windows/                  ← Native Windows Runner configurations
├── lib/
│   ├── main.dart             ← Application Entry Point
│   ├── models/               ← Entities (Project, Message, History, Settings, LogEntry)
│   ├── storage/              ← Isolated Hive boxes storage services
│   ├── services/             ← Backup, Import/Export, and win32 FFI Automation services
│   ├── providers/            ← AppProvider (State management, LifeCycles, MethodChannels)
│   ├── screens/              ← Responsive UI Screens (Dashboard, Library, History, Guide, Settings, Logs)
│   └── utils/                ← Styles, Theme Data, and custom configurations
├── assets/
│   └── logo/                 ← Application Brand Icon
└── pubspec.yaml              ← Dependencies (Hive, Win32, Qr_Flutter, FL_Chart, etc.)
```

---

## 🚀 Quick Start & Build Guide

### 1. Prerequisites
Ensure you have the Flutter SDK installed on your system.
- Flutter SDK (v3.10.0 or higher recommended)
- Android Studio / Android SDK (for Android build)
- Visual Studio (with "Desktop development with C++" workload for Windows Desktop build)

### 2. Install dependencies
Run this command in the project root:
```bash
flutter pub get
```

### 3. Run the application
- **For Android Device/Emulator:**
  ```bash
  flutter run -d android
  ```
- **For Windows Desktop:**
  ```bash
  flutter run -d windows
  ```

### 4. Build Production APK
To compile the Android APK:
```bash
flutter build apk --debug
```

---

## 🔒 Privacy & Local-First Compliance
ChatSim Pro is engineered as a **100% offline-first utility**:
- **Zero Cloud Infrastructure:** No registration, database syncing, tracking telemetry (like Firebase Analytics), or remote APIs.
- **Local Databases:** All configurations, logs, and messages are stored locally on your physical hardware in secure Hive binary boxes.
- **Sandbox Security:** The Android Accessibility Service operates strictly on local event handlers, never capturing keystrokes outside user-designated targets or transferring keyboard entries.

---

## 👥 About Us

**ChatSim Pro** is developed as a utility to assist developers, QA engineers, and automated testing practitioners. Our goal is to make automation reliable, fast, and secure by processing everything locally on the user's hardware.

- **Developer:** Waiz Hussain
- **Repository:** [GitHub Project](https://github.com/waizhussain9955/chat_simulator)
- **License:** Open Source under MIT License guidelines.

Feel free to open issues or contribute PRs to enhance the simulation engines!
