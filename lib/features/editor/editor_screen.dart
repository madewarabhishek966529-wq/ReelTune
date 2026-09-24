import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reeltune/app/theme.dart';
import 'package:reeltune/data/models/caption_model.dart';
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
          onPressed: () {
            editorNotifier.cancelPlayback();
            Navigator.pop(context);
          },
          tooltip: 'Back to Projects',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              project.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              '${project.width}x${project.height} (${project.fps.toInt()}fps) • Non-Destructive',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // Undo/Redo
          IconButton(
            icon: const Icon(Icons.undo_rounded, size: 20),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Undo',
            onPressed: editorState.undoStack.isNotEmpty ? () => editorNotifier.undo() : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded, size: 20),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Redo',
            onPressed: editorState.redoStack.isNotEmpty ? () => editorNotifier.redo() : null,
          ),
          // Import Media button
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Import Video/Audio',
            onPressed: () => _pickAndImportMedia(context, editorNotifier),
          ),
          // Export Button
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.ios_share_rounded, size: 14),
              label: const Text('Export', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: editorState.mediaFiles.isNotEmpty ? AppTheme.primary : Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(60, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;

          if (isCompact) {
            // Mobile / Portrait Phone Layout
            return Column(
              children: [
                // Top: Video Preview Player
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    child: RepaintBoundary(
                      child: VideoPreviewCard(
                        playhead: editorState.playhead,
                        duration: editorState.maxTimelineDuration,
                        isPlaying: editorState.isPlaying,
                        activeItem: editorState.selectedItem,
                        activeEffects: editorState.effects,
                        activeCaption: _getActiveCaptionAtPlayhead(editorState),
                        mediaFiles: editorState.mediaFiles,
                        audioSettings: editorState.audioSettings,
                        onTogglePlay: () => editorNotifier.togglePlayPause(),
                        onSeek: (t) => editorNotifier.seekPlayhead(t),
                      ),
                    ),
                  ),
                ),

                // Middle: Tabbed Inspector Drawer
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                      border: Border(top: BorderSide(color: AppTheme.border)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 40,
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

                // Bottom: Multi-Track Timeline
                Expanded(
                  flex: 3,
                  child: RepaintBoundary(
                    child: TimelineView(
                      editorState: editorState,
                      editorNotifier: editorNotifier,
                    ),
                  ),
                ),
              ],
            );
          }

          // Desktop / Landscape Layout (Side-by-side)
          return Column(
            children: [
              Expanded(
                flex: 6,
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: RepaintBoundary(
                          child: VideoPreviewCard(
                            playhead: editorState.playhead,
                            duration: editorState.maxTimelineDuration,
                            isPlaying: editorState.isPlaying,
                            activeItem: editorState.selectedItem,
                            activeEffects: editorState.effects,
                            activeCaption: _getActiveCaptionAtPlayhead(editorState),
                            mediaFiles: editorState.mediaFiles,
                            audioSettings: editorState.audioSettings,
                            onTogglePlay: () => editorNotifier.togglePlayPause(),
                            onSeek: (t) => editorNotifier.seekPlayhead(t),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.surface,
                          border: Border(left: BorderSide(color: AppTheme.border)),
                        ),
                        child: Column(
                          children: [
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
              Expanded(
                flex: 4,
                child: RepaintBoundary(
                  child: TimelineView(
                    editorState: editorState,
                    editorNotifier: editorNotifier,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Get the active caption at the current playhead position
  CaptionModel? _getActiveCaptionAtPlayhead(EditorState state) {
    for (final caption in state.captions) {
      if (state.playhead >= caption.startTime &&
          state.playhead <= caption.startTime + caption.duration) {
        return caption;
      }
    }
    return null;
  }

  /// Pick a video or audio file and import it into the editor
  Future<void> _pickAndImportMedia(BuildContext context, EditorNotifier editorNotifier) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Import Media',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
                ),
                title: const Text('Import Video', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('MP4, MOV, MKV to Video track', style: TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _executePickFile(context, editorNotifier, FileType.video);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.secondary,
                  child: Icon(Icons.audiotrack_rounded, color: Colors.white, size: 20),
                ),
                title: const Text('Import Audio / Music', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('MP3, WAV, AAC, M4A to Audio track', style: TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _executePickFile(context, editorNotifier, FileType.audio);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executePickFile(BuildContext context, EditorNotifier editorNotifier, FileType type) async {
    try {
      final result = await FilePicker.pickFile(type: type);

      if (result != null && result.path != null) {
        final filePath = result.path!;
        if (type == FileType.audio) {
          await editorNotifier.importAudioFile(filePath);
        } else {
          await editorNotifier.importMediaFile(filePath);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported: ${result.name}'),
              backgroundColor: AppTheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
