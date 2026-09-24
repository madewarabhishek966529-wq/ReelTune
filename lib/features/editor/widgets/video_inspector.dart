import 'package:flutter/material.dart';
import 'package:reeltune/app/theme.dart';
import 'package:reeltune/data/models/timeline_item_model.dart';
import 'package:reeltune/features/editor/editor_provider.dart';

class VideoInspector extends StatelessWidget {
  final TimelineItemModel? selectedItem;
  final EditorNotifier editorNotifier;

  const VideoInspector({
    super.key,
    required this.selectedItem,
    required this.editorNotifier,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedItem == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Select a clip on the timeline to edit visual properties, crop, and color grading.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final item = selectedItem!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Clip Info
        Row(
          children: [
            const Icon(Icons.movie_creation_outlined, color: AppTheme.primaryAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white70),
              tooltip: 'Duplicate Clip',
              onPressed: () => editorNotifier.duplicateItem(item.id),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
              tooltip: 'Delete Clip',
              onPressed: () => editorNotifier.deleteItem(item.id),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Aspect / Crop Presets
        const Text('Aspect Ratio Crop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildPresetChip('Original', item.cropPreset == 'original', () {
              editorNotifier.updateItemTransform(id: item.id, cropPreset: 'original');
            }),
            _buildPresetChip('9:16 Reel/Short', item.cropPreset == '9:16', () {
              editorNotifier.updateItemTransform(id: item.id, cropPreset: '9:16');
            }),
            _buildPresetChip('1:1 Square', item.cropPreset == '1:1', () {
              editorNotifier.updateItemTransform(id: item.id, cropPreset: '1:1');
            }),
            _buildPresetChip('16:9 Landscape', item.cropPreset == '16:9', () {
              editorNotifier.updateItemTransform(id: item.id, cropPreset: '16:9');
            }),
          ],
        ),
        const SizedBox(height: 20),

        // Speed Ramping
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Playback Speed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('${item.speed}x', style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
            final isSel = item.speed == s;
            return ChoiceChip(
              label: Text('${s}x', style: TextStyle(fontSize: 12, color: isSel ? Colors.white : Colors.grey)),
              selected: isSel,
              selectedColor: AppTheme.primary,
              backgroundColor: AppTheme.surfaceVariant,
              onSelected: (_) => editorNotifier.setSpeed(item.id, s),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Transform controls
        const Text('Transform & Position', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        _buildSlider(
          label: 'Scale',
          value: item.scale,
          min: 0.5,
          max: 2.5,
          display: '${item.scale.toStringAsFixed(2)}x',
          onChanged: (v) => editorNotifier.updateItemTransform(id: item.id, scale: v),
        ),
        _buildSlider(
          label: 'Rotation',
          value: item.rotation,
          min: -180.0,
          max: 180.0,
          display: '${item.rotation.toInt()}°',
          onChanged: (v) => editorNotifier.updateItemTransform(id: item.id, rotation: v),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.flip, size: 16),
                label: const Text('Flip H'),
                onPressed: () => editorNotifier.updateItemTransform(id: item.id, flipH: !item.flipHorizontal),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.swap_vert, size: 16),
                label: const Text('Flip V'),
                onPressed: () => editorNotifier.updateItemTransform(id: item.id, flipV: !item.flipVertical),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Visual / Color Grading
        const Text('Color Grading & Visuals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        _buildSlider(
          label: 'Brightness',
          value: item.brightness,
          min: -1.0,
          max: 1.0,
          display: item.brightness.toStringAsFixed(2),
          onChanged: (v) => editorNotifier.updateItemColor(id: item.id, brightness: v),
        ),
        _buildSlider(
          label: 'Contrast',
          value: item.contrast,
          min: 0.0,
          max: 2.0,
          display: item.contrast.toStringAsFixed(2),
          onChanged: (v) => editorNotifier.updateItemColor(id: item.id, contrast: v),
        ),
        _buildSlider(
          label: 'Saturation',
          value: item.saturation,
          min: 0.0,
          max: 2.0,
          display: item.saturation.toStringAsFixed(2),
          onChanged: (v) => editorNotifier.updateItemColor(id: item.id, saturation: v),
        ),
        _buildSlider(
          label: 'Vignette',
          value: item.vignette,
          min: 0.0,
          max: 1.0,
          display: item.vignette.toStringAsFixed(2),
          onChanged: (v) => editorNotifier.updateItemColor(id: item.id, vignette: v),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, bool isSelected, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.grey)),
      backgroundColor: isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
      side: BorderSide(color: isSelected ? AppTheme.primaryAccent : AppTheme.border),
      onPressed: onTap,
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(display, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
