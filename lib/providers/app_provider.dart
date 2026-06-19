import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/project.dart';
import '../models/message.dart';
import '../models/history_item.dart';
import '../models/settings.dart';
import '../models/log_entry.dart';
import '../storage/hive_storage.dart';
import '../services/backup_service.dart';
import '../services/import_export_service.dart';
import '../services/simulation_service.dart';

class AppProvider extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('com.chatsimulator.chat_simulator_pro/automation');

  final HiveStorage _storage = HiveStorage();
  late BackupService _backupService;
  final ImportExportService _importExportService = ImportExportService();
  final SimulationService _simulationService = SimulationService();
  final Uuid _uuid = const Uuid();

  bool _isAccessibilityActive = false;
  bool get isAccessibilityActive => _isAccessibilityActive;

  // State Variables
  List<Project> _projects = [];
  Project? _activeProject;
  List<Message> _messages = [];
  List<HistoryItem> _history = [];
  ProjectSettings _settings = ProjectSettings();
  final List<LogEntry> _logs = [];

  bool _isRunning = false;
  int _countdownRemaining = 0;

  // Getters
  List<Project> get projects => _projects;
  Project? get activeProject => _activeProject;
  List<Message> get messages => _messages;
  List<HistoryItem> get history => _history;
  ProjectSettings get settings => _settings;
  List<LogEntry> get logs => _logs;
  bool get isRunning => _isRunning;
  int get countdownRemaining => _countdownRemaining;
  String get customChatAppUrl => _settings.customChatAppUrl;

  HiveStorage get storage => _storage;
  BackupService get backupService => _backupService;
  ImportExportService get importExportService => _importExportService;

  // Initialize Provider
  Future<void> init() async {
    await _storage.init();
    _backupService = BackupService(_storage);

    // Load projects
    _projects = _storage.getProjects();

    // Check accessibility status on Android
    if (Platform.isAndroid) {
      await checkAccessibilityStatus();
    }

    // Load or create active project
    String? activeId = _storage.getActiveProjectId();
    if (activeId == null || !_projects.any((p) => p.id == activeId)) {
      if (_projects.isNotEmpty) {
        activeId = _projects.first.id;
      } else {
        // Create initial default project
        final defaultProj = Project(
          id: _uuid.v4(),
          name: 'Default Project',
          createdAt: DateTime.now(),
        );
        await _storage.saveProject(defaultProj);
        _projects.add(defaultProj);
        activeId = defaultProj.id;
      }
    }

    await _storage.setActiveProjectId(activeId);
    _activeProject = _projects.firstWhere((p) => p.id == activeId);

    // Load active project data
    await _loadActiveProjectData();
    
    addLog('Chat Simulator Pro initialized.', 'success');
  }

  // Load Active Project Messages, Settings, History
  Future<void> _loadActiveProjectData() async {
    if (_activeProject == null) return;
    final id = _activeProject!.id;

    _messages = await _storage.getMessages(id);
    _history = await _storage.getHistory(id);
    _settings = await _storage.getSettings(id);

    notifyListeners();
  }

  // Switch Project
  Future<void> switchProject(String projectId) async {
    if (_activeProject?.id == projectId) return;

    // Save current settings first
    if (_activeProject != null) {
      await _storage.saveSettings(_activeProject!.id, _settings);
    }

    _activeProject = _projects.firstWhere((p) => p.id == projectId);
    await _storage.setActiveProjectId(projectId);

    addLog('Switched to project: ${_activeProject!.name}', 'info');
    await _loadActiveProjectData();
  }

  // Create Project
  Future<void> createProject(String name) async {
    final newProj = Project(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    await _storage.saveProject(newProj);
    _projects.add(newProj);
    
    addLog('Created new project: $name', 'success');
    await switchProject(newProj.id);
  }

  // Delete Project
  Future<void> deleteProject(String projectId) async {
    if (_projects.length <= 1) {
      addLog('Cannot delete the only remaining project.', 'warning');
      return;
    }

    final name = _projects.firstWhere((p) => p.id == projectId).name;
    await _storage.deleteProject(projectId);
    _projects.removeWhere((p) => p.id == projectId);

    addLog('Deleted project: $name', 'warning');

    if (_activeProject?.id == projectId) {
      await switchProject(_projects.first.id);
    } else {
      notifyListeners();
    }
  }

  // Edit Project Name
  Future<void> renameProject(String projectId, String newName) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index >= 0) {
      final updated = Project(id: projectId, name: newName, createdAt: _projects[index].createdAt);
      _projects[index] = updated;
      await _storage.saveProject(updated);
      if (_activeProject?.id == projectId) {
        _activeProject = updated;
      }
      addLog('Renamed project to: $newName', 'info');
      notifyListeners();
    }
  }

  // ==================== SETTINGS ACTIONS ====================

  Future<void> updateSettings(ProjectSettings newSettings) async {
    if (_activeProject == null) return;
    _settings = newSettings;
    if (_settings.autoSave) {
      await _storage.saveSettings(_activeProject!.id, _settings);
      _triggerAutoBackup();
    }
    notifyListeners();
  }

  Future<void> updateCustomChatAppUrl(String url) async {
    await updateSettings(_settings.copyWith(customChatAppUrl: url));
  }

  // ==================== MESSAGE LIBRARY ACTIONS ====================

  Future<void> addMessage(String text, String category, {bool isFavorite = false}) async {
    if (_activeProject == null) return;
    final msg = Message(
      id: _uuid.v4(),
      message: text,
      category: category,
      isFavorite: isFavorite,
      createdAt: DateTime.now(),
    );
    _messages.add(msg);
    if (_settings.autoSave) {
      await _storage.saveMessage(_activeProject!.id, msg);
      _triggerAutoBackup();
    }
    notifyListeners();
  }

  Future<void> updateMessage(Message message) async {
    if (_activeProject == null) return;
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index >= 0) {
      _messages[index] = message;
      if (_settings.autoSave) {
        await _storage.saveMessage(_activeProject!.id, message);
        _triggerAutoBackup();
      }
      notifyListeners();
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (_activeProject == null) return;
    _messages.removeWhere((m) => m.id == messageId);
    if (_settings.autoSave) {
      await _storage.deleteMessage(_activeProject!.id, messageId);
      _triggerAutoBackup();
    }
    notifyListeners();
  }

  Future<void> duplicateMessage(Message message) async {
    await addMessage(
      '${message.message} (Copy)',
      message.category,
      isFavorite: message.isFavorite,
    );
  }

  Future<void> toggleFavoriteMessage(Message message) async {
    final updated = message.copyWith(isFavorite: !message.isFavorite);
    await updateMessage(updated);
  }

  // ==================== CHAT HISTORY ACTIONS ====================

  Future<void> deleteHistoryItem(String historyId) async {
    if (_activeProject == null) return;
    _history.removeWhere((h) => h.id == historyId);
    if (_settings.autoSave) {
      await _storage.deleteHistoryItem(_activeProject!.id, historyId);
      _triggerAutoBackup();
    }
    notifyListeners();
  }

  Future<void> clearHistory() async {
    if (_activeProject == null) return;
    _history.clear();
    if (_settings.autoSave) {
      await _storage.clearHistory(_activeProject!.id);
      _triggerAutoBackup();
    }
    notifyListeners();
  }

  // ==================== BACKUP & RESTORE ====================

  Future<void> _triggerAutoBackup() async {
    if (_activeProject == null) return;
    // Perform background backup
    await _backupService.createBackup(_activeProject!, _settings, _messages, _history);
  }

  Future<void> forceBackup() async {
    await _triggerAutoBackup();
    addLog('Manual backup created successfully.', 'success');
  }

  Future<bool> restoreFromBackupPath(String path) async {
    final data = await _backupService.restoreBackup(path);
    if (data == null || _activeProject == null) {
      addLog('Failed to restore from backup.', 'error');
      return false;
    }

    final pId = _activeProject!.id;
    _settings = data['settings'] as ProjectSettings;
    _messages = data['messages'] as List<Message>;
    _history = data['history'] as List<HistoryItem>;

    // Save to active project boxes
    await _storage.saveSettings(pId, _settings);
    
    // Clear & overwrite messages box
    final msgBox = await Hive.openBox('messages_$pId');
    await msgBox.clear();
    for (var m in _messages) {
      await _storage.saveMessage(pId, m);
    }

    // Clear & overwrite history box
    final histBox = await Hive.openBox('history_$pId');
    await histBox.clear();
    for (var h in _history) {
      await _storage.saveHistoryItem(pId, h);
    }

    addLog('Project data successfully restored from backup.', 'success');
    notifyListeners();
    return true;
  }

  // ==================== IMPORT & EXPORT ACTIONS ====================

  Future<void> importFromFile(File file, String format) async {
    try {
      final content = await file.readAsString();
      List<Message> imported = [];
      
      if (format.toLowerCase() == 'json') {
        imported = _importExportService.importMessagesFromJson(content);
      } else if (format.toLowerCase() == 'csv') {
        imported = _importExportService.importMessagesFromCsv(content);
      } else if (format.toLowerCase() == 'txt') {
        imported = _importExportService.importMessagesFromTxt(content);
      }

      if (imported.isNotEmpty && _activeProject != null) {
        for (var m in imported) {
          _messages.add(m);
          await _storage.saveMessage(_activeProject!.id, m);
        }
        addLog('Successfully imported ${imported.length} messages.', 'success');
        _triggerAutoBackup();
        notifyListeners();
      } else {
        addLog('No valid messages found in imported file.', 'warning');
      }
    } catch (e) {
      addLog('Import failed: $e', 'error');
    }
  }

  // ==================== LOGGING ====================

  void addLog(String message, String type) {
    _logs.insert(0, LogEntry(timestamp: DateTime.now(), message: message, type: type));
    if (_logs.length > 200) {
      _logs.removeLast(); // Cap at 200 logs
    }
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  // ==================== SIMULATION RUNNER ====================

  Future<void> startSimulation(List<Message> targetMessages) async {
    if (_isRunning) return;
    if (targetMessages.isEmpty) {
      addLog('No messages selected for simulation.', 'warning');
      return;
    }

    _isRunning = true;
    _countdownRemaining = _settings.countdown;
    notifyListeners();

    await _simulationService.run(
      messages: targetMessages,
      settings: _settings,
      customChatAppUrl: _settings.customChatAppUrl,
      onLog: (msg, type) {
        addLog(msg, type);
      },
      onCountdown: (seconds) {
        _countdownRemaining = seconds;
        notifyListeners();
      },
      onMessageSent: (sentItem) async {
        _history.insert(0, sentItem);
        if (_activeProject != null) {
          await _storage.saveHistoryItem(_activeProject!.id, sentItem);
        }
        notifyListeners();
      },
      onFinished: () {
        _isRunning = false;
        _countdownRemaining = 0;
        _triggerAutoBackup();
        notifyListeners();
      },
    );
  }

  void stopSimulation() {
    if (!_isRunning) return;
    _simulationService.cancel();
    _isRunning = false;
    _countdownRemaining = 0;
    addLog('Simulation stopped manually.', 'warning');
    notifyListeners();
  }

  Future<Map<String, dynamic>> testWhatsAppPrefill() async {
    addLog('Starting test of WhatsApp prefill URL variants...', 'info');
    final result = await _simulationService.testWhatsAppPrefill(
      onLog: (msg, type) {
        addLog(msg, type);
      },
    );
    return result;
  }

  // ==================== ACCESSIBILITY ACTIONS ====================

  Future<void> checkAccessibilityStatus() async {
    if (!Platform.isAndroid) return;
    try {
      final bool enabled = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled') ?? false;
      if (_isAccessibilityActive != enabled) {
        _isAccessibilityActive = enabled;
        notifyListeners();
      }
    } catch (e) {
      addLog('Error checking accessibility service status: $e', 'warning');
    }
  }

  Future<void> openAccessibilitySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      addLog('Failed to open Accessibility Settings: $e', 'error');
    }
  }
}
