import 'dart:convert';
import 'dart:io';
import '../models/project.dart';
import '../models/message.dart';
import '../models/history_item.dart';
import '../models/settings.dart';
import '../storage/hive_storage.dart';

class BackupService {
  final HiveStorage storage;

  BackupService(this.storage);

  // Trigger a rolling backup for the active project
  Future<void> createBackup(
    Project project,
    ProjectSettings settings,
    List<Message> messages,
    List<HistoryItem> history,
  ) async {
    try {
      final backupDir = await storage.getBackupDirectory();

      // Define files
      final file1 = File('${backupDir.path}/backup_01.json');
      final file2 = File('${backupDir.path}/backup_02.json');
      final file3 = File('${backupDir.path}/backup_03.json');

      // Shift backups (rolling system)
      if (await file2.exists()) {
        if (await file3.exists()) {
          await file3.delete();
        }
        await file2.rename(file3.path);
      }
      if (await file1.exists()) {
        await file1.rename(file2.path);
      }

      // Serialize current project data
      final backupData = {
        'projectId': project.id,
        'projectName': project.name,
        'timestamp': DateTime.now().toIso8601String(),
        'settings': settings.toMap(),
        'messages': messages.map((m) => m.toMap()).toList(),
        'history': history.map((h) => h.toMap()).toList(),
      };

      final jsonString = jsonEncode(backupData);
      await file1.writeAsString(jsonString);
    } catch (e) {
      // Failed to back up, should log to console but not crash
      print('Backup creation failed: $e');
    }
  }

  // Get list of existing backup files with their metadata
  Future<List<Map<String, dynamic>>> getBackupsInfo() async {
    final List<Map<String, dynamic>> backups = [];
    try {
      final backupDir = await storage.getBackupDirectory();
      for (int i = 1; i <= 3; i++) {
        final file = File('${backupDir.path}/backup_0${i}.json');
        if (await file.exists()) {
          final content = await file.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;
          backups.add({
            'fileName': 'backup_0${i}.json',
            'filePath': file.path,
            'timestamp': DateTime.parse(data['timestamp'] as String),
            'projectName': data['projectName'] as String,
            'messageCount': (data['messages'] as List).length,
            'historyCount': (data['history'] as List).length,
          });
        }
      }
    } catch (e) {
      print('Failed to load backup info: $e');
    }
    return backups;
  }

  // Restore project data from a backup file path
  Future<Map<String, dynamic>?> restoreBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final String projectId = data['projectId'] as String;
      final String projectName = data['projectName'] as String;
      final ProjectSettings settings = ProjectSettings.fromMap(data['settings'] as Map);

      final List<Message> messages = (data['messages'] as List)
          .map((m) => Message.fromMap(Map<dynamic, dynamic>.from(m)))
          .toList();

      final List<HistoryItem> history = (data['history'] as List)
          .map((h) => HistoryItem.fromMap(Map<dynamic, dynamic>.from(h)))
          .toList();

      return {
        'project': Project(id: projectId, name: projectName, createdAt: DateTime.now()),
        'settings': settings,
        'messages': messages,
        'history': history,
      };
    } catch (e) {
      print('Failed to restore backup: $e');
      return null;
    }
  }
}
