import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/log_entry.dart';
import '../utils/theme.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({Key? key}) : super(key: key);

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    // Apply log filtering
    final List<LogEntry> filteredLogs = provider.logs.where((log) {
      if (_filter == 'all') return true;
      return log.type == _filter;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logs Toolbar
          _buildLogsToolbar(context, provider),
          const SizedBox(height: 16),

          // Terminal Console Window
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xff05070a), // Deep rich black-blue terminal background
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xff30363d), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2610b981),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: filteredLogs.isEmpty
                  ? _buildEmptyState()
                  : _buildConsoleList(filteredLogs),
            ),
          ),
        ],
      ),
    );
  }

  // Logs Toolbar
  Widget _buildLogsToolbar(BuildContext context, AppProvider provider) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final filterBar = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterButton('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterButton('Success', 'success'),
          const SizedBox(width: 8),
          _buildFilterButton('Warnings', 'warning'),
          const SizedBox(width: 8),
          _buildFilterButton('Errors', 'error'),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filterBar,
          if (provider.logs.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => provider.clearLogs(),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('CLEAR CONSOLE', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        filterBar,
        if (provider.logs.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => provider.clearLogs(),
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
            label: const Text('CLEAR CONSOLE', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() => _filter = value);
        }
      },
      selectedColor: DarkEmeraldTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: DarkEmeraldTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? DarkEmeraldTheme.primaryColor : Colors.white60,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: const Color(0xff161b22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? DarkEmeraldTheme.primaryColor : const Color(0xff30363d),
        ),
      ),
    );
  }

  // Terminal Console Text list
  Widget _buildConsoleList(List<LogEntry> logs) {
    return ListView.builder(
      reverse: true, // Show latest logs at the top or bottom. We load in reverse so latest starts from bottom/top
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final color = _getLogColor(log.type);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '[${log.formattedTime}] ',
                  style: const TextStyle(color: Colors.white30),
                ),
                TextSpan(
                  text: '[${log.type.toUpperCase()}] ',
                  style: TextStyle(color: color.withOpacity(0.7), fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: log.message,
                  style: TextStyle(color: color),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getLogColor(String type) {
    switch (type) {
      case 'success':
        return DarkEmeraldTheme.primaryColor;
      case 'warning':
        return Colors.amberAccent;
      case 'error':
        return Colors.redAccent;
      case 'info':
      default:
        return const Color(0xffcfcfcf);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.terminal_outlined, color: Colors.white12, size: 48),
          SizedBox(height: 12),
          Text(
            'Terminal feed is empty.',
            style: TextStyle(fontFamily: 'monospace', color: Colors.white30, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
extension ColorsExtension on Color {
  static const Color whitecf = Color(0xffcfcfcf);
}
const Color Colors_whitecf = Color(0xffcfcfcf);
