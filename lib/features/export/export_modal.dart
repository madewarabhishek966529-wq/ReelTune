import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reeltune/app/theme.dart';
import 'package:reeltune/data/models/export_job_model.dart';
import 'package:reeltune/features/editor/editor_state.dart';
import 'package:reeltune/features/export/export_provider.dart';

class ExportModal extends ConsumerStatefulWidget {
  final EditorState editorState;

  const ExportModal({super.key, required this.editorState});

  @override
  ConsumerState<ExportModal> createState() => _ExportModalState();
}

class _ExportModalState extends ConsumerState<ExportModal> {
  ExportPreset _selectedPreset = ExportPreset.instagramReel;

  @override
  Widget build(BuildContext context) {
    final exportQueue = ref.watch(exportProvider);
    final exportNotifier = ref.read(exportProvider.notifier);

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Container(
        width: 600,
        height: 640,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.video_camera_back_outlined, color: AppTheme.primaryAccent, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Export Project',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Social Presets Grid
            const Text('Select Social Media Preset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.6,
              physics: const NeverScrollableScrollPhysics(),
              children: ExportPreset.allPresets.map((preset) {
                final isSelected = _selectedPreset.name == preset.name;
                return InkWell(
                  onTap: () => setState(() => _selectedPreset = preset),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryAccent : AppTheme.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          preset.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSelected ? AppTheme.primaryAccent : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${preset.width}x${preset.height} • ${preset.fps.toInt()} fps',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Start Export CTA
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                label: Text(
                  exportQueue.isProcessing ? 'Rendering in background...' : 'Start Export (${_selectedPreset.name})',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
                onPressed: exportQueue.isProcessing
                    ? null
                    : () {
                        exportNotifier.startExport(
                          editorState: widget.editorState,
                          preset: _selectedPreset,
                        );
                      },
              ),
            ),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 10),

            // Export Queue & History Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Export Queue & History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(
                  '${exportQueue.jobs.length} jobs',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Export Queue List
            Expanded(
              child: exportQueue.jobs.isEmpty
                  ? const Center(
                      child: Text('No exports yet. Choose a preset and click Start Export.',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    )
                  : ListView.builder(
                      itemCount: exportQueue.jobs.length,
                      itemBuilder: (context, index) {
                        final job = exportQueue.jobs[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(_statusIcon(job.status), color: _statusColor(job.status), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      job.outputFilename,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _statusBadge(job.status),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                                    onPressed: () => exportNotifier.deleteExport(job.id),
                                  ),
                                ],
                              ),
                              if (job.status == ExportStatus.running) ...[
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: job.progress,
                                  backgroundColor: const Color(0xFF141721),
                                  valueColor: const AlwaysStoppedAnimation(AppTheme.primaryAccent),
                                ),
                              ],
                              if (job.outputFileSize != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Size: ${(job.outputFileSize! / 1024 / 1024).toStringAsFixed(2)} MB • Verified Safe',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.accentNeon),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(ExportStatus status) {
    switch (status) {
      case ExportStatus.pending:
        return Icons.hourglass_empty;
      case ExportStatus.running:
        return Icons.sync;
      case ExportStatus.completed:
        return Icons.check_circle;
      case ExportStatus.failed:
        return Icons.error;
      case ExportStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _statusColor(ExportStatus status) {
    switch (status) {
      case ExportStatus.pending:
        return Colors.amberAccent;
      case ExportStatus.running:
        return AppTheme.primaryAccent;
      case ExportStatus.completed:
        return AppTheme.accentNeon;
      case ExportStatus.failed:
        return Colors.redAccent;
      case ExportStatus.cancelled:
        return Colors.grey;
    }
  }

  Widget _statusBadge(ExportStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor(status)),
      ),
    );
  }
}
