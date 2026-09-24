import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reeltune/app/theme.dart';
import 'package:reeltune/data/models/project_model.dart';
import 'package:reeltune/features/editor/editor_provider.dart';
import 'package:reeltune/features/editor/editor_state.dart';
import 'package:reeltune/features/editor/widgets/audio_inspector.dart';
import 'package:reeltune/features/editor/widgets/captions_inspector.dart';
import 'package:reeltune/features/editor/widgets/effects_inspector.dart';
import 'package:reeltune/features/editor/widgets/video_inspector.dart';
import 'package:reeltune/features/export/export_modal.dart';
import 'package:reeltune/features/timeline/timeline_view.dart';
import 'package:reeltune/shared/widgets/video_preview_card.dart';

class EditorScreen extends ConsumerWidget {
  final ProjectModel project;

  const EditorScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider(project));
    final editorNotifier = ref.read(editorProvider(project).notifier);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back to Projects',
        ),
        title: Row(
          children: [
            Text(
              project.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                '${project.width}x${project.height} (${project.fps.toInt()}fps)',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentNeon.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 12, color: AppTheme.accentNeon),
                  SizedBox(width: 4),
                  Text(
                    'Non-Destructive',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentNeon),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Import Media button
          TextButton.icon(
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: const Text('Import Media'),
            onPressed: () async {
              final result = await FilePickerPlatform.instance.pickFiles(
                type: FileType.video,
              );
              if (result.isNotEmpty && result.first.path != null) {
                editorNotifier.importMediaFile(result.first.path!);
              }
            },
          ),
          const SizedBox(width: 8),

          // Export Button
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.ios_share_rounded, size: 16),
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => ExportModal(editorState: editorState),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Middle Stage: Video Preview (Left) + Inspector Drawer (Right)
          Expanded(
            flex: 6,
            child: Row(
              children: [
                // Video Preview Canvas
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: VideoPreviewCard(
                      playhead: editorState.playhead,
                      duration: editorState.maxTimelineDuration,
                      isPlaying: editorState.isPlaying,
                      activeItem: editorState.selectedItem,
                      activeEffects: editorState.effects,
                      activeCaption: editorState.captions.isEmpty ? null : editorState.captions.first,
                      onTogglePlay: () => editorNotifier.togglePlayPause(),
                      onSeek: (t) => editorNotifier.seekPlayhead(t),
                    ),
                  ),
                ),

                // Inspector Tabs (Right Sidebar)
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                      border: Border(left: BorderSide(color: AppTheme.border)),
                    ),
                    child: Column(
                      children: [
                        // Tab Selector Header
                        Container(
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            border: Border(bottom: BorderSide(color: AppTheme.border)),
                          ),
                          child: Row(
                            children: [
                              _buildInspectorTab(context, editorState, editorNotifier, 0, 'Visuals', Icons.tune_rounded),
                              _buildInspectorTab(context, editorState, editorNotifier, 1, 'Audio EQ', Icons.graphic_eq_rounded),
                              _buildInspectorTab(context, editorState, editorNotifier, 2, 'Effects', Icons.auto_awesome_rounded),
                              _buildInspectorTab(context, editorState, editorNotifier, 3, 'Captions', Icons.subtitles_rounded),
                            ],
                          ),
                        ),

                        // Tab Content View
                        Expanded(
                          child: IndexedStack(
                            index: editorState.activeInspectorTab,
                            children: [
                              VideoInspector(
                                selectedItem: editorState.selectedItem,
                                editorNotifier: editorNotifier,
                              ),
                              AudioInspector(
                                audioSettings: editorState.audioSettings,
                                audioAnalysis: editorState.audioAnalysis,
                                editorNotifier: editorNotifier,
                              ),
                              EffectsInspector(
                                effects: editorState.effects,
                                currentPlayhead: editorState.playhead,
                                editorNotifier: editorNotifier,
                              ),
                              CaptionsInspector(
                                captions: editorState.captions,
                                currentPlayhead: editorState.playhead,
                                editorNotifier: editorNotifier,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Stage: Multi-Track Timeline
          Expanded(
            flex: 4,
            child: TimelineView(
              editorState: editorState,
              editorNotifier: editorNotifier,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorTab(
    BuildContext context,
    EditorState state,
    EditorNotifier notifier,
    int index,
    String label,
    IconData icon,
  ) {
    final isSelected = state.activeInspectorTab == index;

    return Expanded(
      child: InkWell(
        onTap: () => notifier.setActiveTab(index),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.primaryAccent : Colors.transparent,
                width: 2.0,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? AppTheme.primaryAccent : Colors.grey),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
