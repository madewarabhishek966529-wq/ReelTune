import 'package:flutter/material.dart';
import 'package:reeltune/app/theme.dart';
import 'package:reeltune/core/utilities/time_formatter.dart';
import 'package:reeltune/data/models/effect_model.dart';
import 'package:reeltune/features/editor/editor_provider.dart';

class EffectsInspector extends StatelessWidget {
  final List<EffectModel> effects;
  final double currentPlayhead;
  final EditorNotifier editorNotifier;

  const EffectsInspector({
    super.key,
    required this.effects,
    required this.currentPlayhead,
    required this.editorNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Action Buttons: Add Effect & Beat-Sync Randomizer
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Add Effect'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.effectsTrackColor),
                onPressed: () => _showAddEffectDialog(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bolt_rounded, size: 16, color: Colors.amberAccent),
                label: const Text('Beat Sync FX'),
                onPressed: () => editorNotifier.generateRandomCreativeEffects(count: 4, seed: 42),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (effects.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.auto_fix_high_rounded, size: 36, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No creative effects added yet.\nAdd blur, glitch, zoom bounce, or auto-sync to music beats!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ...effects.map((effect) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
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
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.effectsTrackColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.flash_on, color: AppTheme.effectsTrackColor, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _effectName(effect.type),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                            Text(
                              '${TimeFormatter.formatDetailed(effect.startTime)} - ${TimeFormatter.formatDetailed(effect.startTime + effect.duration)}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        onPressed: () => editorNotifier.removeEffect(effect.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('Intensity: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Expanded(
                        child: Slider(
                          value: effect.intensity,
                          min: 0.1,
                          max: 1.0,
                          onChanged: (val) {
                            editorNotifier.addEffect(effect.type, effect.startTime, effect.duration, intensity: val);
                          },
                        ),
                      ),
                      Text('${(effect.intensity * 100).toInt()}%', style: const TextStyle(fontSize: 11, color: Colors.white)),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  String _effectName(EffectType type) {
    switch (type) {
      case EffectType.gaussianBlur:
        return 'Gaussian Blur';
      case EffectType.motionBlur:
        return 'Motion Blur';
      case EffectType.backgroundBlur:
        return 'Background Blur';
      case EffectType.zoomBounce:
        return 'Beat Zoom Bounce';
      case EffectType.glitch:
        return 'Digital Glitch';
      case EffectType.shake:
        return 'Camera Shake';
      case EffectType.flash:
        return 'Beat Flash';
      case EffectType.colorShift:
        return 'Color Shift';
      case EffectType.speedRamp:
        return 'Speed Ramp';
      default:
        return type.name;
    }
  }

  void _showAddEffectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Creative Effect', style: TextStyle(fontSize: 16)),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAddOption(ctx, 'Beat Zoom Bounce', EffectType.zoomBounce, Icons.zoom_in),
              _buildAddOption(ctx, 'Digital Glitch', EffectType.glitch, Icons.grain),
              _buildAddOption(ctx, 'Beat Flash', EffectType.flash, Icons.flash_on),
              _buildAddOption(ctx, 'Gaussian Blur', EffectType.gaussianBlur, Icons.blur_on),
              _buildAddOption(ctx, 'Color Shift', EffectType.colorShift, Icons.color_lens),
              _buildAddOption(ctx, 'Camera Shake', EffectType.shake, Icons.vibration),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOption(BuildContext ctx, String label, EffectType type, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.effectsTrackColor),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      dense: true,
      onTap: () {
        Navigator.pop(ctx);
        editorNotifier.addEffect(type, currentPlayhead, 1.0, intensity: 0.7);
      },
    );
  }
}
