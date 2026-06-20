import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_logo.dart';

// Screens
import 'dashboard_screen.dart';
import 'library_screen.dart';
import 'history_screen.dart';
import 'projects_screen.dart';
import 'guide_screen.dart';
import 'settings_screen.dart';
import 'logs_screen.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({Key? key}) : super(key: key);

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    LibraryScreen(),
    HistoryScreen(),
    ProjectsScreen(),
    GuideScreen(),
    SettingsScreen(),
    LogsScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = const [
    {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'label': 'Dashboard'},
    {'icon': Icons.chat_bubble_outline, 'activeIcon': Icons.chat_bubble, 'label': 'Library'},
    {'icon': Icons.history_outlined, 'activeIcon': Icons.history, 'label': 'History'},
    {'icon': Icons.folder_open_outlined, 'activeIcon': Icons.folder, 'label': 'Projects'},
    {'icon': Icons.help_outline, 'activeIcon': Icons.help, 'label': 'Guide'},
    {'icon': Icons.settings_outlined, 'activeIcon': Icons.settings, 'label': 'Settings'},
    {'icon': Icons.terminal_outlined, 'activeIcon': Icons.terminal, 'label': 'Logs'},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      drawer: isMobile ? _buildMobileDrawer(context, provider) : null,
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar for Desktop/Tablet
              if (!isMobile) _buildSidebar(context, provider),

              // Main Screen Area
              Expanded(
                child: SafeArea(
                  child: Column(
                    children: [
                      Builder(
                        builder: (context) => _buildTopHeader(context, provider),
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: _currentIndex,
                          children: _screens,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Active Simulation overlay
          if (provider.isRunning) _buildSimulationOverlay(context, provider),
        ],
      ),
    );
  }

  // Sidebar widget for Desktop
  Widget _buildSidebar(BuildContext context, AppProvider provider) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xff161b22),
        border: Border(right: BorderSide(color: Color(0xff30363d), width: 1)),
      ),
      child: Column(
        children: [
          // App Header Brand
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                const AppLogo(size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chat Sim Pro',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      provider.activeProject?.name ?? 'No active project',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xff30363d), height: 1),
          const SizedBox(height: 16),

          // Nav Items List
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _currentIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: InkWell(
                    onTap: () => setState(() => _currentIndex = index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? DarkEmeraldTheme.borderColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: DarkEmeraldTheme.borderColor, width: 1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? item['activeIcon'] : item['icon'],
                            color: isSelected
                                ? DarkEmeraldTheme.primaryColor
                                : Colors.white60,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            item['label'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // User Project Switcher Dropdown in Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, color: Colors.white54, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: provider.activeProject?.id,
                        isExpanded: true,
                        dropdownColor: const Color(0xff161b22),
                        items: provider.projects.map((proj) {
                          return DropdownMenuItem<String>(
                            value: proj.id,
                            child: Text(
                              proj.name,
                              style: const TextStyle(fontSize: 13, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            provider.switchProject(val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context, AppProvider provider) {
    return Drawer(
      backgroundColor: const Color(0xff161b22),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  const AppLogo(size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chat Sim Pro',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          provider.activeProject?.name ?? 'No active project',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xff30363d), height: 1),
            const SizedBox(height: 16),

            // Nav Items
            Expanded(
              child: ListView.builder(
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isSelected = _currentIndex == index;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() => _currentIndex = index);
                        Navigator.pop(context); // Close drawer
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? DarkEmeraldTheme.borderColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: DarkEmeraldTheme.borderColor, width: 1)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? item['activeIcon'] : item['icon'],
                              color: isSelected
                                  ? DarkEmeraldTheme.primaryColor
                                  : Colors.white60,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              item['label'],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white60,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Project Switcher Dropdown in Footer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: Colors.white54, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: provider.activeProject?.id,
                          isExpanded: true,
                          dropdownColor: const Color(0xff161b22),
                          items: provider.projects.map((proj) {
                            return DropdownMenuItem<String>(
                              value: proj.id,
                              child: Text(
                                proj.name,
                                style: const TextStyle(fontSize: 13, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              provider.switchProject(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Top header for pages (mostly title & quick info)
  Widget _buildTopHeader(BuildContext context, AppProvider provider) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xff0d1117),
        border: Border(bottom: BorderSide(color: Color(0xff1f242c), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isMobile) ...[
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
                const SizedBox(width: 8),
              ],
              Text(
                _navItems[_currentIndex]['label'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Project Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: DarkEmeraldTheme.borderColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: DarkEmeraldTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 8, color: DarkEmeraldTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      provider.activeProject?.name ?? 'Default',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: DarkEmeraldTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (provider.isRunning)
                const Icon(
                  Icons.flash_on,
                  color: DarkEmeraldTheme.primaryColor,
                ),
            ],
          )
        ],
      ),
    );
  }

  // Floating Active simulation HUD
  Widget _buildSimulationOverlay(BuildContext context, AppProvider provider) {
    return Positioned(
      bottom: 24,
      right: 24,
      left: MediaQuery.of(context).size.width < 800 ? 24 : null, // Stretch on mobile
      child: GlassCard(
        width: MediaQuery.of(context).size.width < 800 ? null : 350,
        color: const Color(0xe6059669), // Rich semi-transparent emerald background
        borderColor: Colors.white38,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Simulation Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (provider.countdownRemaining > 0)
                    Text(
                      'Sending in ${provider.countdownRemaining}s...',
                      style: const TextStyle(color: Color(0xffcfcfcf), fontSize: 12),
                    )
                  else
                    const Text(
                      'Transmitting messages...',
                      style: TextStyle(color: Color(0xffcfcfcf), fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => provider.stopSimulation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('STOP'),
            )
          ],
        ),
      ),
    );
  }
}
