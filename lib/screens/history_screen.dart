import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/app_provider.dart';
import '../models/history_item.dart';
import '../utils/theme.dart';
import '../widgets/glass_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    // Filter history
    final filteredHistory = provider.history.where((item) {
      final matchesSearch = item.message.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesDate = true;
      if (_selectedDateRange != null) {
        final date = item.timestamp;
        final start = _selectedDateRange!.start;
        // set end to end of day
        final end = _selectedDateRange!.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        matchesDate = date.isAfter(start) && date.isBefore(end);
      }

      return matchesSearch && matchesDate;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Filter Panel
          _buildFilterPanel(context, provider),
          const SizedBox(height: 16),

          // History List
          Expanded(
            child: filteredHistory.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(context, provider, filteredHistory),
          ),
        ],
      ),
    );
  }

  // Filter & Action Panel
  Widget _buildFilterPanel(BuildContext context, AppProvider provider) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Search + Date filter
          if (isMobile) ...[
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Search sent messages...',
                prefixIcon: Icon(Icons.search, color: Colors.white30),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDateRange(context),
                    icon: const Icon(Icons.date_range, size: 16),
                    label: Text(
                      _selectedDateRange == null
                          ? 'Filter Date'
                          : '${DateFormat('MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('MM/dd').format(_selectedDateRange!.end)}',
                    ),
                  ),
                ),
                if (_selectedDateRange != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.redAccent, size: 18),
                    onPressed: () => setState(() => _selectedDateRange = null),
                  ),
                ],
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Search sent messages...',
                      prefixIcon: Icon(Icons.search, color: Colors.white30),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _pickDateRange(context),
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    _selectedDateRange == null
                        ? 'Filter Date'
                        : '${DateFormat('MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('MM/dd').format(_selectedDateRange!.end)}',
                  ),
                ),
                if (_selectedDateRange != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.redAccent, size: 18),
                    onPressed: () => setState(() => _selectedDateRange = null),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),
          
          // Row 2: Status text + Actions (Clear & Export)
          if (isMobile) ...[
            Text(
              '${provider.history.length} records in active project',
              style: const TextStyle(fontSize: 12, color: Colors.white30),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (provider.history.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _confirmClearHistory(context, provider),
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      label: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildExportButton(context, provider),
                  ),
                ],
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${provider.history.length} records in active project',
                  style: const TextStyle(fontSize: 12, color: Colors.white30),
                ),
                Row(
                  children: [
                    if (provider.history.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _confirmClearHistory(context, provider),
                        icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 18),
                        label: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                      ),
                    const SizedBox(width: 12),
                    if (provider.history.isNotEmpty) _buildExportButton(context, provider),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Date Range Picker
  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DarkEmeraldTheme.primaryColor,
              onPrimary: Colors.black,
              surface: Color(0xff161b22),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dateRange != null) {
      setState(() {
        _selectedDateRange = dateRange;
      });
    }
  }

  // Export Action Dropdown
  Widget _buildExportButton(BuildContext context, AppProvider provider) {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: DarkEmeraldTheme.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.download, color: Colors.black, size: 16),
            SizedBox(width: 8),
            Text('EXPORT HISTORY', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      color: const Color(0xff161b22),
      onSelected: (format) => _exportHistory(context, provider, format),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'json', child: Text('JSON Format (.json)')),
        const PopupMenuItem(value: 'csv', child: Text('CSV Spreadsheet (.csv)')),
        const PopupMenuItem(value: 'txt', child: Text('Plain Text (.txt)')),
      ],
    );
  }

  // Trigger export flow
  Future<void> _exportHistory(BuildContext context, AppProvider provider, String format) async {
    String fileContent = '';
    String fileExt = '';
    
    if (format == 'json') {
      fileContent = provider.importExportService.exportHistoryToJson(provider.history);
      fileExt = 'json';
    } else if (format == 'csv') {
      fileContent = provider.importExportService.exportHistoryToCsv(provider.history);
      fileExt = 'csv';
    } else if (format == 'txt') {
      fileContent = provider.importExportService.exportHistoryToTxt(provider.history);
      fileExt = 'txt';
    }

    try {
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final projName = provider.activeProject?.name.replaceAll(' ', '_') ?? 'project';
        final outputFile = '$selectedDirectory${Platform.pathSeparator}chat_history_${projName}_$timestamp.$fileExt';
        
        final file = File(outputFile);
        await file.writeAsString(fileContent);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DarkEmeraldTheme.primaryColor,
            content: Text('History successfully exported to ${file.path.split(Platform.pathSeparator).last}', 
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        );
        provider.addLog('Exported history to $outputFile', 'success');
      }
    } catch (e) {
      provider.addLog('Failed to export history: $e', 'error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Failed to export: $e'),
        ),
      );
    }
  }

  // History List
  Widget _buildHistoryList(
    BuildContext context,
    AppProvider provider,
    List<HistoryItem> list,
  ) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(item.timestamp);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0x2610b981),
                  child: Icon(Icons.outbound, color: DarkEmeraldTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.message,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text(
                            timeStr,
                            style: const TextStyle(color: Colors.white30, fontSize: 11),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xff0d1117),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Session: ${item.sessionId}',
                              style: const TextStyle(color: Colors.white54, fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white30, size: 20),
                  onPressed: () => provider.deleteHistoryItem(item.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history_toggle_off, color: Colors.white12, size: 64),
          SizedBox(height: 16),
          Text(
            'History is empty',
            style: TextStyle(fontSize: 16, color: Colors.white54, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Sent simulator messages will appear here.',
            style: TextStyle(fontSize: 12, color: Colors.white30),
          ),
        ],
      ),
    );
  }

  // Clear confirmation
  void _confirmClearHistory(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Chat History'),
          content: const Text('Are you sure you want to delete all sent records in the active project? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.clearHistory();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: const Text('CLEAR ALL'),
            ),
          ],
        );
      },
    );
  }
}
