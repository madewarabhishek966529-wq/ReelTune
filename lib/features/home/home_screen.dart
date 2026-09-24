import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reeltune/app/theme.dart';
import 'package:reeltune/core/services/workspace_service.dart';
import 'package:reeltune/core/utilities/time_formatter.dart';
import 'package:reeltune/data/models/project_model.dart';
import 'package:reeltune/features/developer/developer_screen.dart';
import 'package:reeltune/features/editor/editor_provider.dart';
import 'package:reeltune/features/editor/editor_screen.dart';
import 'package:reeltune/features/projects/project_providers.dart';
import 'package:reeltune/features/settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Map<String, int> _storageStats = {};

  @override
  void initState() {
    super.initState();
    _loadWorkspaceStats();
  }

  Future<void> _loadWorkspaceStats() async {
    final stats = await WorkspaceService().getStorageStats();
    if (mounted) setState(() => _storageStats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectListProvider);
    final projectsNotifier = ref.read(projectListProvider.notifier);

    final totalMb = ((_storageStats['total'] ?? 0) / 1024 / 1024).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.movie_filter_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('ReelTune', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('PRO STUDIO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
            ),
          ],
        ),
        actions: [
          // Developer / Automated Test Suite
          IconButton(
            icon: const Icon(Icons.terminal_rounded, color: AppTheme.secondary),
            tooltip: 'Automated Test Suite & Dev Loop',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperScreen()));
            },
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings & Workspace',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Top Hero Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Non-Destructive Reel Studio',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create beat-synced, audio-enhanced short videos for Reels, Shorts, and TikTok without modifying original source media.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('New Project'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                              onPressed: () => _showNewProjectDialog(context, projectsNotifier),
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.video_file_outlined, size: 18),
                              label: const Text('Import Video'),
                              onPressed: () => _handleDirectImport(context, projectsNotifier),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Workspace Storage Metric Chip
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 14, color: AppTheme.accentNeon),
                            SizedBox(width: 6),
                            Text('Workspace Cache', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('$totalMb MB Used', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentNeon)),
                        const Text('Offline Storage Protected', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section Title: Recent Projects
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Projects', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    onPressed: () => projectsNotifier.loadProjects(),
                  ),
                ],
              ),
            ),
          ),

          // Projects Grid
          projectsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(child: Text('Error loading projects: $err', style: const TextStyle(color: Colors.redAccent))),
            ),
            data: (projects) {
              if (projects.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.movie_edit, size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No projects yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('Click "New Project" or "Import Video" to get started.', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Create First Project'),
                          onPressed: () => _showNewProjectDialog(context, projectsNotifier),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.15,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final project = projects[index];
                      return _buildProjectCard(context, project, projectsNotifier);
                    },
                    childCount: projects.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project, ProjectListNotifier notifier) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EditorScreen(project: project)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Thumbnail Header
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.3),
                    AppTheme.secondary.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.play_circle_fill_rounded, size: 40, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${project.width}x${project.height}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        TimeFormatter.formatDuration(project.duration),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Meta Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Modified ${dateFormat.format(project.updatedAt)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                    tooltip: 'Delete Project',
                    onPressed: () => _confirmDeleteProject(context, project, notifier),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewProjectDialog(BuildContext context, ProjectListNotifier notifier) {
    final nameController = TextEditingController(text: 'Reel ${DateFormat('MMdd_HHmm').format(DateTime.now())}');
    int selectedWidth = 1080;
    int selectedHeight = 1920;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create New Project', style: TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Project Name'),
              ),
              const SizedBox(height: 16),
              const Text('Resolution / Format Preset', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('9:16 (1080x1920 Reel)', style: TextStyle(fontSize: 11)),
                    selected: selectedWidth == 1080 && selectedHeight == 1920,
                    onSelected: (_) => setDialogState(() {
                      selectedWidth = 1080;
                      selectedHeight = 1920;
                    }),
                  ),
                  ChoiceChip(
                    label: const Text('1:1 (1080x1080 Square)', style: TextStyle(fontSize: 11)),
                    selected: selectedWidth == 1080 && selectedHeight == 1080,
                    onSelected: (_) => setDialogState(() {
                      selectedWidth = 1080;
                      selectedHeight = 1080;
                    }),
                  ),
                  ChoiceChip(
                    label: const Text('16:9 (1920x1080 Landscape)', style: TextStyle(fontSize: 11)),
                    selected: selectedWidth == 1920 && selectedHeight == 1080,
                    onSelected: (_) => setDialogState(() {
                      selectedWidth = 1920;
                      selectedHeight = 1080;
                    }),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(ctx);
                  final proj = await notifier.createNewProject(
                    name: name,
                    width: selectedWidth,
                    height: selectedHeight,
                  );
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditorScreen(project: proj)),
                    );
                  }
                }
              },
              child: const Text('Create & Open'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDirectImport(BuildContext context, ProjectListNotifier notifier) async {
    final result = await FilePickerPlatform.instance.pickFiles(
      type: FileType.video,
    );

    if (result.isNotEmpty && result.first.path != null) {
      final filePath = result.first.path!;
      final filename = filePath.split(RegExp(r'[\\/]')).last;

      final project = await notifier.createNewProject(
        name: filename.replaceAll(RegExp(r'\.[^.]+$'), ''),
      );

      if (context.mounted) {
        // Open editor and import video
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditorScreen(project: project)),
        );
        ref.read(editorProvider(project).notifier).importMediaFile(filePath);
      }
    }
  }

  void _confirmDeleteProject(BuildContext context, ProjectModel project, ProjectListNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text('Are you sure you want to delete "${project.name}"? Source media files will not be touched.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              notifier.deleteProject(project.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
