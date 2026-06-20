import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/settings.dart';
import '../utils/theme.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  final _urlController = TextEditingController();
  final _pathController = TextEditingController();
  List<Map<String, dynamic>> _backupsInfo = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      _urlController.text = provider.customChatAppUrl;
      _pathController.text = provider.settings.storagePath;
      _loadBackups(provider);
      if (Platform.isAndroid) {
        provider.checkAccessibilityStatus();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _urlController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (Platform.isAndroid) {
        Provider.of<AppProvider>(context, listen: false).checkAccessibilityStatus();
      }
    }
  }

  Future<void> _loadBackups(AppProvider provider) async {
    final list = await provider.backupService.getBackupsInfo();
    setState(() {
      _backupsInfo = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final settings = provider.settings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Simulation Engine Settings
          _buildSectionHeader('Simulation Profile & Modes'),
          const SizedBox(height: 12),
          _buildSimulationSettingsCard(provider, settings),
          
          const SizedBox(height: 24),

          // 2. Storage & AutoSave Settings
          _buildSectionHeader('Storage & Auto-Save Options'),
          const SizedBox(height: 12),
          _buildStorageSettingsCard(provider, settings),

          const SizedBox(height: 24),

          // 3. Android Mobile Link Launcher
          _buildSectionHeader('Android App Link Scheme'),
          const SizedBox(height: 12),
          _buildMobileLinkSettingsCard(provider),

          const SizedBox(height: 24),

          // 4. Android Universal Automation Accessibility Service
          if (Platform.isAndroid) ...[
            _buildSectionHeader('Android Universal Automation'),
            const SizedBox(height: 12),
            _buildUniversalAutomationCard(provider),
            const SizedBox(height: 24),
          ],

          // 5. Rolling Backup Manager
          _buildSectionHeader('Rolling Backup Manager'),
          const SizedBox(height: 12),
          _buildBackupManagerCard(provider),
          
          const SizedBox(height: 24),

          // 6. Legal & Policy
          _buildSectionHeader('Legal & Resources'),
          const SizedBox(height: 12),
          _buildLegalSettingsCard(context),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  // Simulation Profile Card
  Widget _buildSimulationSettingsCard(AppProvider provider, ProjectSettings settings) {
    return GlassCard(
      child: Column(
        children: [
          // Mode select
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Sending Profile Mode', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Choose between Human, Fast or Instant injection.', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: settings.sendingMode,
                dropdownColor: const Color(0xff161b22),
                items: const [
                  DropdownMenuItem(value: 'human', child: Text('Human Mode')),
                  DropdownMenuItem(value: 'fast', child: Text('Fast Mode')),
                  DropdownMenuItem(value: 'instant', child: Text('Instant Mode (Fastest)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    provider.updateSettings(settings.copyWith(sendingMode: val));
                  }
                },
              ),
            ],
          ),
          const Divider(color: Color(0xff30363d), height: 32),

          // Countdown Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delay Countdown: ${settings.countdown}s', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('Seconds to wait before typing so you can click the chatbox.', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: Slider(
                  value: settings.countdown.toDouble(),
                  min: 0,
                  max: 15,
                  divisions: 15,
                  activeColor: DarkEmeraldTheme.primaryColor,
                  onChanged: (val) {
                    provider.updateSettings(settings.copyWith(countdown: val.toInt()));
                  },
                ),
              ),
            ],
          ),
          
          const Divider(color: Color(0xff30363d), height: 32),

          // Inter-Message Delay Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inter-Message Delay: ${settings.interMessageDelay}s', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('Delay time between sending consecutive messages.', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: Slider(
                  value: settings.interMessageDelay.toDouble(),
                  min: 1,
                  max: 15,
                  divisions: 14,
                  activeColor: DarkEmeraldTheme.primaryColor,
                  onChanged: (val) {
                    provider.updateSettings(settings.copyWith(interMessageDelay: val.toInt()));
                  },
                ),
              ),
            ],
          ),
          
          
          if (settings.sendingMode == 'human') ...[
            const Divider(color: Color(0xff30363d), height: 32),
            // Keystroke Delay Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Keystroke Speed: ${settings.typingSpeed}ms', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      const Text('Character-by-character typing speed interval in milliseconds.', style: TextStyle(fontSize: 12, color: Colors.white54)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: Slider(
                    value: settings.typingSpeed.toDouble(),
                    min: 30,
                    max: 300,
                    divisions: 27,
                    activeColor: DarkEmeraldTheme.primaryColor,
                    onChanged: (val) {
                      provider.updateSettings(settings.copyWith(typingSpeed: val.toInt()));
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Storage Settings
  Widget _buildStorageSettingsCard(AppProvider provider, ProjectSettings settings) {
    return GlassCard(
      child: Column(
        children: [
          // Auto-Save Switch
          SwitchListTile(
            title: const Text('Auto Save Changes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: const Text('Instantly save modifications and create local rolling backups.', style: TextStyle(fontSize: 11, color: Colors.white54)),
            value: settings.autoSave,
            activeColor: DarkEmeraldTheme.primaryColor,
            onChanged: (val) {
              provider.updateSettings(settings.copyWith(autoSave: val));
            },
          ),
          const Divider(color: Color(0xff30363d), height: 32),

          // Custom storage path (info only, or set custom folder)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Custom Database Path', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(
                      settings.storagePath.isEmpty ? 'System Default (App Directory)' : settings.storagePath,
                      style: const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  final dirPath = await FilePicker.platform.getDirectoryPath();
                  if (dirPath != null) {
                    provider.updateSettings(settings.copyWith(storagePath: dirPath));
                    _pathController.text = dirPath;
                  }
                },
                child: const Text('BROWSE'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Mobile intent launch card
  Widget _buildMobileLinkSettingsCard(AppProvider provider) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Custom Launch URL Scheme (Android/iOS)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          const Text(
            'Allows opening chat apps on mobile with copied messages. Use {text} where message goes.',
            style: TextStyle(fontSize: 11, color: Colors.white54),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. whatsapp://send?text={text}',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  provider.updateCustomChatAppUrl(_urlController.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: DarkEmeraldTheme.primaryColor,
                      content: Text('Launch Scheme Saved!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
                child: const Text('SAVE LINK'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: () {
                  _urlController.text = 'whatsapp://send?text={text}';
                  provider.updateCustomChatAppUrl(_urlController.text);
                },
                child: const Text('WhatsApp'),
              ),
              TextButton(
                onPressed: () {
                  _urlController.text = 'whatsapp-business://send?text={text}';
                  provider.updateCustomChatAppUrl(_urlController.text);
                },
                child: const Text('WA Business'),
              ),
              TextButton(
                onPressed: () {
                  _urlController.text = 'tg://msg?text={text}';
                  provider.updateCustomChatAppUrl(_urlController.text);
                },
                child: const Text('Telegram'),
              ),
              TextButton(
                onPressed: () {
                  _urlController.text = 'https://wa.me/?text={text}';
                  provider.updateCustomChatAppUrl(_urlController.text);
                },
                child: const Text('WA Web'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting WhatsApp prefill test...')),
              );
              final result = await provider.testWhatsAppPrefill();
              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: result['success'] ? DarkEmeraldTheme.primaryColor : Colors.redAccent,
                    content: Text(
                      result['message'],
                      style: TextStyle(
                        color: result['success'] ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.phonelink_setup, size: 16),
            label: const Text('TEST WHATSAPP PREFILL'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigoAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(45),
            ),
          ),
        ],
      ),
    );
  }

  // Backup Manager UI Card
  Widget _buildBackupManagerCard(AppProvider provider) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Rolling Backups', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Restore past snapshots or create backups manually.', style: TextStyle(fontSize: 11, color: Colors.white54)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  await provider.forceBackup();
                  await _loadBackups(provider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: DarkEmeraldTheme.primaryColor,
                      content: Text('Manual backup created successfully!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
                icon: const Icon(Icons.backup, size: 16),
                label: const Text('BACKUP NOW'),
              ),
            ],
          ),
          const Divider(color: Color(0xff30363d), height: 32),

          // Lists backups
          if (_backupsInfo.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text('No backup files found. Create one now!', style: TextStyle(color: Colors.white30, fontSize: 13)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _backupsInfo.length,
              itemBuilder: (context, index) {
                final backup = _backupsInfo[index];
                final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(backup['timestamp'] as DateTime);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xff0d1117),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xff30363d)),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.description, color: DarkEmeraldTheme.primaryColor),
                    title: Text(backup['fileName'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(
                      'Project: ${backup['projectName']} | Time: $dateStr\nMessages: ${backup['messageCount']} | Logs: ${backup['historyCount']}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    isThreeLine: true,
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                      onPressed: () => _confirmRestoreBackup(context, provider, backup),
                      child: const Text('RESTORE', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  // Confirm restore
  void _confirmRestoreBackup(BuildContext context, AppProvider provider, Map<String, dynamic> backup) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Restore ${backup['fileName']}?'),
          content: Text(
            'Are you sure you want to restore data from ${backup['fileName']}? This will overwrite the active project\'s message library, sent history, and configuration settings with the backup data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final messenger = ScaffoldMessenger.of(context);
                final success = await provider.restoreFromBackupPath(backup['filePath'] as String);
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      backgroundColor: DarkEmeraldTheme.primaryColor,
                      content: Text('Restored successfully!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.redAccent,
                      content: Text('Failed to restore backup.'),
                    ),
                  );
                }
              },
              child: const Text('RESTORE DATA'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUniversalAutomationCard(AppProvider provider) {
    final isActive = provider.isAccessibilityActive;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Universal Text Injection',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0x2610b981) : const Color(0x26f43f5e),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? DarkEmeraldTheme.primaryColor : const Color(0xfff43f5e),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: isActive ? DarkEmeraldTheme.primaryColor : const Color(0xfff43f5e),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? 'ACTIVE' : 'INACTIVE',
                      style: TextStyle(
                        color: isActive ? DarkEmeraldTheme.primaryColor : const Color(0xfff43f5e),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Injects your simulated text directly into the focused input box of any chat application on click/focus. Requires manual authorization in your system\'s accessibility settings.',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await provider.openAccessibilitySettings();
            },
            icon: const Icon(Icons.settings_accessibility, size: 18),
            label: Text(isActive ? 'MANAGE ACCESSIBILITY SERVICE' : 'ENABLE ACCESSIBILITY SERVICE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.grey[800] : DarkEmeraldTheme.primaryColor,
              foregroundColor: isActive ? Colors.white : Colors.black,
              minimumSize: const Size.fromHeight(45),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: Settings -> Accessibility -> Installed Services -> Chat Simulator Pro',
            style: TextStyle(fontSize: 10, color: Colors.white38, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSettingsCard(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          ListTile(
            title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: const Text('Read about our offline-first local data storage policy.', style: TextStyle(fontSize: 11, color: Colors.white54)),
            trailing: const Icon(Icons.keyboard_arrow_right, color: Colors.white54),
            onTap: () => _showPrivacyPolicyDialog(context),
          ),
          const Divider(color: Color(0xff30363d), height: 1),
          ListTile(
            title: const Text('Application Documentation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: const Text('View detailed step-by-step visual configuration instructions.', style: TextStyle(fontSize: 11, color: Colors.white54)),
            trailing: const Icon(Icons.keyboard_arrow_right, color: Colors.white54),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select the "Guide" tab in the navigation menu to view full documentation!'),
                  duration: Duration(seconds: 4),
                  backgroundColor: DarkEmeraldTheme.primaryColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Privacy Policy & Data Security'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '1. 100% Offline & Local Storage',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                SizedBox(height: 6),
                Text(
                  'Chat Simulator Pro performs all database actions directly on your physical hardware. We use Hive local database boxes to store your project profiles, message libraries, and send history. None of this data is ever synced, sent, or uploaded to any remote servers.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                SizedBox(height: 16),
                Text(
                  '2. Accessibility Permission Usage',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                SizedBox(height: 6),
                Text(
                  'Our custom Accessibility Service is strictly used to facilitate character typing simulation and automated send button trigger events. It operates entirely locally on your device. It does not monitor other app behaviors, read keystrokes outside active window simulation, or collect/transmit keyboard inputs.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                SizedBox(height: 16),
                Text(
                  '3. Zero Telemetry & Diagnostics',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                SizedBox(height: 6),
                Text(
                  'The application runs without any cloud infrastructure, authentication handlers, or diagnostic tracking metrics (like Firebase Analytics). We have zero insight into how many messages you send, what you write, or which applications you target.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }
}
