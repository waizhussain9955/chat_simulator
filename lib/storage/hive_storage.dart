import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/project.dart';
import '../models/message.dart';
import '../models/history_item.dart';
import '../models/settings.dart';

class HiveStorage {
  static const String _globalBoxName = 'global_box';
  static const String _keyActiveProjectId = 'active_project_id';
  static const String _keyProjectsList = 'projects_list';

  late Box _globalBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _globalBox = await Hive.openBox(_globalBoxName);
  }

  // Active Project ID
  String? getActiveProjectId() {
    return _globalBox.get(_keyActiveProjectId) as String?;
  }

  Future<void> setActiveProjectId(String id) async {
    await _globalBox.put(_keyActiveProjectId, id);
  }

  // Projects CRUD
  List<Project> getProjects() {
    final list = _globalBox.get(_keyProjectsList) as List?;
    if (list == null) return [];
    return list.map((item) => Project.fromMap(Map<dynamic, dynamic>.from(item))).toList();
  }

  Future<void> saveProject(Project project) async {
    final projects = getProjects();
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      projects[index] = project;
    } else {
      projects.add(project);
    }
    await _globalBox.put(_keyProjectsList, projects.map((p) => p.toMap()).toList());
  }

  Future<void> deleteProject(String id) async {
    final projects = getProjects();
    projects.removeWhere((p) => p.id == id);
    await _globalBox.put(_keyProjectsList, projects.map((p) => p.toMap()).toList());

    // Clear specific boxes
    await Hive.deleteBoxFromDisk('messages_$id');
    await Hive.deleteBoxFromDisk('history_$id');
    await Hive.deleteBoxFromDisk('settings_$id');
  }

  // Project-Specific Messages
  Future<List<Message>> getMessages(String projectId) async {
    final box = await Hive.openBox('messages_$projectId');
    final List<Message> messages = [];
    for (var key in box.keys) {
      final value = box.get(key);
      if (value != null) {
        messages.add(Message.fromMap(Map<dynamic, dynamic>.from(value)));
      }
    }
    return messages;
  }

  Future<void> saveMessage(String projectId, Message message) async {
    final box = await Hive.openBox('messages_$projectId');
    await box.put(message.id, message.toMap());
  }

  Future<void> deleteMessage(String projectId, String messageId) async {
    final box = await Hive.openBox('messages_$projectId');
    await box.delete(messageId);
  }

  // Project-Specific History
  Future<List<HistoryItem>> getHistory(String projectId) async {
    final box = await Hive.openBox('history_$projectId');
    final List<HistoryItem> history = [];
    for (var key in box.keys) {
      final value = box.get(key);
      if (value != null) {
        history.add(HistoryItem.fromMap(Map<dynamic, dynamic>.from(value)));
      }
    }
    // Sort history by timestamp descending
    history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return history;
  }

  Future<void> saveHistoryItem(String projectId, HistoryItem item) async {
    final box = await Hive.openBox('history_$projectId');
    await box.put(item.id, item.toMap());
  }

  Future<void> deleteHistoryItem(String projectId, String historyId) async {
    final box = await Hive.openBox('history_$projectId');
    await box.delete(historyId);
  }

  Future<void> clearHistory(String projectId) async {
    final box = await Hive.openBox('history_$projectId');
    await box.clear();
  }

  // Project-Specific Settings
  Future<ProjectSettings> getSettings(String projectId) async {
    final box = await Hive.openBox('settings_$projectId');
    final map = box.get('config');
    if (map == null) {
      return ProjectSettings();
    }
    return ProjectSettings.fromMap(Map<dynamic, dynamic>.from(map));
  }

  Future<void> saveSettings(String projectId, ProjectSettings settings) async {
    final box = await Hive.openBox('settings_$projectId');
    await box.put('config', settings.toMap());
  }

  // Get directory for local backups
  Future<Directory> getBackupDirectory() async {
    Directory baseDir;
    if (Platform.isWindows) {
      baseDir = await getApplicationSupportDirectory();
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }
    final backupDir = Directory('${baseDir.path}/backup');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }
}
