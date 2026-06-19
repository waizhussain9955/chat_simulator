import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/project.dart';
import '../utils/theme.dart';
import '../widgets/glass_card.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectDialog(context, provider),
        backgroundColor: DarkEmeraldTheme.primaryColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_to_photos),
        label: const Text('CREATE PROJECT', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Workspace Projects',
              style: TextStyle(fontSize: 16, color: Colors.white54),
            ),
            const SizedBox(height: 16),
            
            // Project Grid List
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 650;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.projects.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: isMobile ? 2.5 : 2.8,
                  ),
                  itemBuilder: (context, index) {
                    final proj = provider.projects[index];
                    final isActive = provider.activeProject?.id == proj.id;
                    return _buildProjectCard(context, provider, proj, isActive);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Create Project Card
  Widget _buildProjectCard(
    BuildContext context,
    AppProvider provider,
    Project project,
    bool isActive,
  ) {
    final dateStr = DateFormat('yyyy-MM-dd').format(project.createdAt);

    return GlassCard(
      borderColor: isActive ? DarkEmeraldTheme.primaryColor : const Color(0xff30363d),
      color: isActive ? const Color(0x3310b981) : DarkEmeraldTheme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isActive ? DarkEmeraldTheme.primaryColor : Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created: $dateStr',
                      style: const TextStyle(fontSize: 11, color: Colors.white30),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DarkEmeraldTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Show quick settings summary or action to delete
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: Colors.white54, size: 20),
                    tooltip: 'Rename',
                    onPressed: () => _showRenameProjectDialog(context, provider, project),
                  ),
                  if (provider.projects.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 20),
                      tooltip: 'Delete Project',
                      onPressed: () => _confirmDeleteProject(context, provider, project),
                    ),
                ],
              ),
              if (!isActive)
                ElevatedButton(
                  onPressed: () => provider.switchProject(project.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: DarkEmeraldTheme.primaryColor,
                    side: const BorderSide(color: DarkEmeraldTheme.borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('SWITCH TO'),
                )
              else
                const Text(
                  'Currently Workspace Active',
                  style: TextStyle(fontSize: 11, color: Colors.white30, fontStyle: FontStyle.italic),
                )
            ],
          )
        ],
      ),
    );
  }

  // dialogs
  void _showCreateProjectDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Project'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter project name (e.g. Project A)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  provider.createProject(name);
                  Navigator.pop(context);
                }
              },
              child: const Text('CREATE'),
            ),
          ],
        );
      },
    );
  }

  void _showRenameProjectDialog(
    BuildContext context,
    AppProvider provider,
    Project project,
  ) {
    final controller = TextEditingController(text: project.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Project'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter project name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  provider.renameProject(project.id, name);
                  Navigator.pop(context);
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteProject(
    BuildContext context,
    AppProvider provider,
    Project project,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Project "${project.name}"?'),
          content: const Text(
            'Are you sure you want to delete this project? This will permanently delete all associated message libraries, sent logs, and configurations. There is no undo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.deleteProject(project.id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }
}
