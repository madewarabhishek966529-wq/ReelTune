import 'package:flutter/material.dart';
import 'package:reeltune/app/theme.dart';
import 'package:reeltune/core/utilities/time_formatter.dart';
import 'package:reeltune/data/models/caption_model.dart';
import 'package:reeltune/features/editor/editor_provider.dart';

class CaptionsInspector extends StatelessWidget {
  final List<CaptionModel> captions;
  final double currentPlayhead;
  final EditorNotifier editorNotifier;

  const CaptionsInspector({
    super.key,
    required this.captions,
    required this.currentPlayhead,
    required this.editorNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Action row: Add Caption, Import SRT, Export SRT
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_comment_outlined, size: 16),
                label: const Text('Add Text'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.captionsTrackColor),
                onPressed: () => _showAddCaptionDialog(context),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text('SRT'),
              onPressed: () => _showSrtDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (captions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.subtitles_outlined, size: 36, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No captions or text overlays added.\nCreate manual subtitles or import standard .SRT files.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ...captions.map((caption) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.captionsTrackColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.subtitles, color: AppTheme.captionsTrackColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caption.text,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${TimeFormatter.formatDetailed(caption.startTime)} - ${TimeFormatter.formatDetailed(caption.startTime + caption.duration)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white70),
                    onPressed: () => _showEditCaptionDialog(context, caption),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                    onPressed: () => editorNotifier.removeCaption(caption.id),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showAddCaptionDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subtitle', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter caption text...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                editorNotifier.addCaption(controller.text.trim(), currentPlayhead, 2.5);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCaptionDialog(BuildContext context, CaptionModel caption) {
    final controller = TextEditingController(text: caption.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Subtitle', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Edit caption text...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                editorNotifier.updateCaption(caption.copyWith(text: controller.text.trim()));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSrtDialog(BuildContext context) {
    final srtText = editorNotifier.exportSrt();
    final importController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SRT Subtitles Import / Export', style: TextStyle(fontSize: 16)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current SRT Export:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                height: 100,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10131B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  srtText.isEmpty ? '(No captions to export yet)' : srtText,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white70),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Import SRT Text:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: importController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Paste standard SRT content here...',
                ),
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              if (importController.text.trim().isNotEmpty) {
                editorNotifier.importSrt(importController.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}
