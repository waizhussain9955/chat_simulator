import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/app_provider.dart';
import '../models/message.dart';
import '../utils/theme.dart';
import '../widgets/glass_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';
  final Set<String> _selectedMessageIds = {};

  final List<String> _categories = [
    'All',
    'Friends',
    'Clients',
    'Leads',
    'Follow-up',
    'Custom'
  ];

  final List<String> _formCategories = [
    'Friends',
    'Clients',
    'Leads',
    'Follow-up',
    'Custom'
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    // Apply filtering
    final filteredMessages = provider.messages.where((msg) {
      final matchesSearch = msg.message.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryFilter == 'All' || msg.category == _selectedCategoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Toolbar: Search + Category Selector + Add Button
          _buildToolbar(context, provider),
          const SizedBox(height: 16),

          // Bulk Simulation Bar (appears when messages are checked)
          if (_selectedMessageIds.isNotEmpty) _buildBulkActionWidget(context, provider),

          const SizedBox(height: 16),

          // Message Grid / List
          Expanded(
            child: filteredMessages.isEmpty
                ? _buildEmptyState()
                : _buildMessageList(context, provider, filteredMessages),
          ),
        ],
      ),
    );
  }

  // Toolbar Component
  Widget _buildToolbar(BuildContext context, AppProvider provider) {
    final isSmall = MediaQuery.of(context).size.width < 650;

    return Column(
      children: [
        if (isSmall) ...[
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: const InputDecoration(
              hintText: 'Search message library...',
              prefixIcon: Icon(Icons.search, color: Colors.white30),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDataActionsButton(context, provider)),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddMessageDialog(context, provider),
                  icon: const Icon(Icons.add),
                  label: const Text('NEW MESSAGE'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Search message library...',
                    prefixIcon: Icon(Icons.search, color: Colors.white30),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildDataActionsButton(context, provider),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddMessageDialog(context, provider),
                icon: const Icon(Icons.add),
                label: const Text('NEW MESSAGE'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        // Categories horizontal list
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategoryFilter == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() => _selectedCategoryFilter = cat);
                  },
                  selectedColor: DarkEmeraldTheme.primaryColor.withOpacity(0.2),
                  checkmarkColor: DarkEmeraldTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? DarkEmeraldTheme.primaryColor : Colors.white60,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: const Color(0xff161b22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? DarkEmeraldTheme.primaryColor : const Color(0xff30363d),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Bulk execution controls
  Widget _buildBulkActionWidget(BuildContext context, AppProvider provider) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        color: DarkEmeraldTheme.borderColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${_selectedMessageIds.length} Messages Selected',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: provider.isRunning
                  ? null
                  : () {
                      final selectedMessages = provider.messages
                          .where((m) => _selectedMessageIds.contains(m.id))
                          .toList();
                      provider.startSimulation(selectedMessages);
                      setState(() => _selectedMessageIds.clear());
                    },
              icon: const Icon(Icons.play_circle_filled, size: 20),
              label: const Text('SIMULATE SEQUENCE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DarkEmeraldTheme.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => setState(() => _selectedMessageIds.clear()),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white30, width: 0.5),
              ),
              child: const Text('Deselect All'),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: DarkEmeraldTheme.borderColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_selectedMessageIds.length} Messages Selected',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => setState(() => _selectedMessageIds.clear()),
                child: const Text('Deselect All', style: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: provider.isRunning
                    ? null
                    : () {
                        final selectedMessages = provider.messages
                            .where((m) => _selectedMessageIds.contains(m.id))
                            .toList();
                        provider.startSimulation(selectedMessages);
                        setState(() => _selectedMessageIds.clear());
                      },
                icon: const Icon(Icons.play_circle_filled, size: 20),
                label: const Text('SIMULATE SEQUENCE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DarkEmeraldTheme.primaryColor,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(
    BuildContext context,
    AppProvider provider,
    Message msg,
    bool isChecked,
  ) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: isChecked,
            activeColor: DarkEmeraldTheme.primaryColor,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedMessageIds.add(msg.id);
                } else {
                  _selectedMessageIds.remove(msg.id);
                }
              });
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  msg.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xff0d1117),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    msg.category,
                    style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  msg.isFavorite ? Icons.star : Icons.star_border,
                  color: msg.isFavorite ? Colors.amber : Colors.white30,
                  size: 20,
                ),
                onPressed: () => provider.toggleFavoriteMessage(msg),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                color: const Color(0xff161b22),
                onSelected: (action) {
                  if (action == 'edit') {
                    _showEditMessageDialog(context, provider, msg);
                  } else if (action == 'duplicate') {
                    provider.duplicateMessage(msg);
                  } else if (action == 'delete') {
                    provider.deleteMessage(msg.id);
                  } else if (action == 'flood') {
                    _showFloodDialog(context, provider, msg);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 16),
                        SizedBox(width: 8),
                        Text('Duplicate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'flood',
                    child: Row(
                      children: [
                        Icon(Icons.bolt, size: 16, color: Colors.amberAccent),
                        SizedBox(width: 8),
                        Text('Flood Send...'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Grid/List of messages
  Widget _buildMessageList(
    BuildContext context,
    AppProvider provider,
    List<Message> list,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (isMobile) {
      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final msg = list[index];
          final isChecked = _selectedMessageIds.contains(msg.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: _buildMessageCard(context, provider, msg, isChecked),
          );
        },
      );
    }

    return GridView.builder(
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 4.2,
      ),
      itemBuilder: (context, index) {
        final msg = list[index];
        final isChecked = _selectedMessageIds.contains(msg.id);
        return _buildMessageCard(context, provider, msg, isChecked);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.speaker_notes_off, color: Colors.white12, size: 64),
          SizedBox(height: 16),
          Text(
            'No messages found',
            style: TextStyle(fontSize: 16, color: Colors.white54, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Try adjusting your filters or add a new message.',
            style: TextStyle(fontSize: 12, color: Colors.white30),
          ),
        ],
      ),
    );
  }

  // Dialog to Add Message
  void _showAddMessageDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    String category = 'Friends';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Message'),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter your message here...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _formCategories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => category = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) {
                      provider.addMessage(text, category);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('ADD'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog to Edit Message
  void _showEditMessageDialog(
    BuildContext context,
    AppProvider provider,
    Message msg,
  ) {
    final controller = TextEditingController(text: msg.message);
    String category = msg.category;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Message'),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter message text...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _formCategories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => category = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) {
                      provider.updateMessage(msg.copyWith(
                        message: text,
                        category: category,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Data Actions Dropdown (Import/Export)
  Widget _buildDataActionsButton(BuildContext context, AppProvider provider) {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: DarkEmeraldTheme.borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.unfold_more, color: DarkEmeraldTheme.primaryColor, size: 16),
            SizedBox(width: 8),
            Text('DATA ACTIONS', style: TextStyle(color: DarkEmeraldTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      color: const Color(0xff161b22),
      onSelected: (action) {
        if (action.startsWith('import_')) {
          _importMessages(context, provider, action.substring(7));
        } else if (action.startsWith('export_')) {
          _exportMessages(context, provider, action.substring(7));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(enabled: false, child: Text('Import Messages', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white54))),
        const PopupMenuItem(value: 'import_json', child: Text('  From JSON (.json)')),
        const PopupMenuItem(value: 'import_csv', child: Text('  From CSV (.csv)')),
        const PopupMenuItem(value: 'import_txt', child: Text('  From Plain TXT (.txt)')),
        const PopupMenuDivider(),
        const PopupMenuItem(enabled: false, child: Text('Export Messages', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white54))),
        const PopupMenuItem(value: 'export_json', child: Text('  As JSON (.json)')),
        const PopupMenuItem(value: 'export_csv', child: Text('  As CSV (.csv)')),
        const PopupMenuItem(value: 'export_txt', child: Text('  As Plain TXT (.txt)')),
      ],
    );
  }

  Future<void> _importMessages(BuildContext context, AppProvider provider, String format) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [format],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await provider.importFromFile(file, format);
      }
    } catch (e) {
      provider.addLog('Failed to import messages: $e', 'error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Import failed: $e'),
        ),
      );
    }
  }

  Future<void> _exportMessages(BuildContext context, AppProvider provider, String format) async {
    String fileContent = '';
    String fileExt = format;

    if (format == 'json') {
      fileContent = provider.importExportService.exportMessagesToJson(provider.messages);
    } else if (format == 'csv') {
      fileContent = provider.importExportService.exportMessagesToCsv(provider.messages);
    } else if (format == 'txt') {
      fileContent = provider.importExportService.exportMessagesToTxt(provider.messages);
    }

    try {
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final projName = provider.activeProject?.name.replaceAll(' ', '_') ?? 'project';
        final outputFile = '$selectedDirectory${Platform.pathSeparator}messages_${projName}_$timestamp.$fileExt';
        
        final file = File(outputFile);
        await file.writeAsString(fileContent);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DarkEmeraldTheme.primaryColor,
            content: Text('Messages successfully exported to ${file.path.split(Platform.pathSeparator).last}', 
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        );
        provider.addLog('Exported messages to $outputFile', 'success');
      }
    } catch (e) {
      provider.addLog('Failed to export messages: $e', 'error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Export failed: $e'),
        ),
      );
    }
  }

  void _showFloodDialog(BuildContext context, AppProvider provider, Message msg) {
    final countController = TextEditingController(text: '100');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.bolt, color: Colors.amber),
              SizedBox(width: 8),
              Expanded(
                child: Text('Flood Chat / Bomber Mode'),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Message to repeat:',
                  style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xff0d1117),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xff30363d)),
                  ),
                  child: Text(
                    msg.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: countController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Repeat Count (e.g. 500)',
                    hintText: 'Enter count',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Warning: Flooding chats quickly may trigger app rate limits.',
                  style: TextStyle(fontSize: 10, color: Colors.redAccent),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final int? count = int.tryParse(countController.text.trim());
                if (count != null && count > 0) {
                  Navigator.pop(context);
                  
                  // Duplicate message in memory N times
                  final List<Message> list = List.generate(count, (index) => msg);
                  provider.startSimulation(list);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.redAccent,
                      content: Text('Please enter a valid positive number.'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('START FLOOD'),
            ),
          ],
        );
      },
    );
  }
}
