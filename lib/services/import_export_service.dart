import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/history_item.dart';

class ImportExportService {
  final Uuid _uuid = const Uuid();

  // ==================== EXPORT FUNCTIONALITY ====================

  // Export messages to JSON
  String exportMessagesToJson(List<Message> messages) {
    final List<Map<String, dynamic>> data = messages.map((m) {
      return {
        'message': m.message,
        'category': m.category,
        'isFavorite': m.isFavorite ? 1 : 0,
      };
    }).toList();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // Export history to JSON
  String exportHistoryToJson(List<HistoryItem> history) {
    final List<Map<String, dynamic>> data = history.map((h) {
      return {
        'message': h.message,
        'timestamp': h.timestamp.toIso8601String(),
        'sessionId': h.sessionId,
        'status': h.status,
      };
    }).toList();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // Export messages to CSV
  String exportMessagesToCsv(List<Message> messages) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('message,category,isFavorite');
    for (var m in messages) {
      final escapedMsg = m.message.replaceAll('"', '""');
      final escapedCategory = m.category.replaceAll('"', '""');
      buffer.writeln('"$escapedMsg","$escapedCategory",${m.isFavorite ? 1 : 0}');
    }
    return buffer.toString();
  }

  // Export history to CSV
  String exportHistoryToCsv(List<HistoryItem> history) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('message,timestamp,sessionId,status');
    for (var h in history) {
      final escapedMsg = h.message.replaceAll('"', '""');
      final timestamp = h.timestamp.toIso8601String();
      final sessionId = h.sessionId.replaceAll('"', '""');
      buffer.writeln('"$escapedMsg","$timestamp","$sessionId","${h.status}"');
    }
    return buffer.toString();
  }

  // Export messages to TXT (one message per line)
  String exportMessagesToTxt(List<Message> messages) {
    final StringBuffer buffer = StringBuffer();
    for (var m in messages) {
      buffer.writeln(m.message.replaceAll('\n', ' ')); // single-line messages for TXT format
    }
    return buffer.toString();
  }

  // Export history to TXT
  String exportHistoryToTxt(List<HistoryItem> history) {
    final StringBuffer buffer = StringBuffer();
    for (var h in history) {
      buffer.writeln('[${h.timestamp.toLocal().toString()}] [Session: ${h.sessionId}] ${h.message}');
    }
    return buffer.toString();
  }

  // ==================== IMPORT FUNCTIONALITY ====================

  // Import messages from JSON string
  List<Message> importMessagesFromJson(String jsonContent) {
    final List<Message> imported = [];
    final List<dynamic> data = jsonDecode(jsonContent) as List<dynamic>;
    for (var item in data) {
      if (item is Map) {
        final messageText = item['message'] as String? ?? '';
        if (messageText.isNotEmpty) {
          imported.add(Message(
            id: _uuid.v4(),
            message: messageText,
            category: item['category'] as String? ?? 'Custom',
            isFavorite: item['isFavorite'] == 1 || item['isFavorite'] == true,
            createdAt: DateTime.now(),
          ));
        }
      }
    }
    return imported;
  }

  // Import messages from CSV string
  List<Message> importMessagesFromCsv(String csvContent) {
    final List<Message> imported = [];
    final List<String> lines = csvContent.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) return [];

    // Header validation (skip if matching header)
    int startIndex = 0;
    if (lines[0].toLowerCase().contains('message') || lines[0].toLowerCase().contains('category')) {
      startIndex = 1;
    }

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Simple CSV row parser (handles quotes)
      final List<String> cells = _parseCsvLine(line);
      if (cells.isNotEmpty) {
        final messageText = cells[0];
        final category = cells.length > 1 ? cells[1] : 'Custom';
        final isFavorite = cells.length > 2 ? (cells[2] == '1' || cells[2].toLowerCase() == 'true') : false;

        if (messageText.isNotEmpty) {
          imported.add(Message(
            id: _uuid.v4(),
            message: messageText,
            category: category,
            isFavorite: isFavorite,
            createdAt: DateTime.now(),
          ));
        }
      }
    }
    return imported;
  }

  // Import messages from TXT (one message per line)
  List<Message> importMessagesFromTxt(String txtContent) {
    final List<Message> imported = [];
    final List<String> lines = txtContent.split(RegExp(r'\r?\n'));
    for (var line in lines) {
      final messageText = line.trim();
      if (messageText.isNotEmpty) {
        imported.add(Message(
          id: _uuid.v4(),
          message: messageText,
          category: 'Custom',
          isFavorite: false,
          createdAt: DateTime.now(),
        ));
      }
    }
    return imported;
  }

  // A robust CSV line parser that respects quote escaping
  List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final StringBuffer currentCell = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final String char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Double quote inside quotes means literal quote
          currentCell.write('"');
          i++; // skip next quote
        } else {
          // Toggle quote mode
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // End of cell
        result.add(currentCell.toString());
        currentCell.clear();
      } else {
        currentCell.write(char);
      }
    }
    result.add(currentCell.toString()); // add last cell
    return result;
  }
}
