import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:reeltune/app/theme.dart';
import 'package:reeltune/core/utilities/time_formatter.dart';
import 'package:reeltune/data/models/caption_model.dart';
import 'package:reeltune/data/models/effect_model.dart';
import 'package:reeltune/data/models/timeline_item_model.dart';

class VideoPreviewCard extends StatelessWidget {
  final double playhead;
  final double duration;
  final bool isPlaying;
  final TimelineItemModel? activeItem;
  final List<EffectModel> activeEffects;
  final CaptionModel? activeCaption;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onSeek;

  const VideoPreviewCard({
    super.key,
    required this.playhead,
    required this.duration,
    required this.isPlaying,
    this.activeItem,
    this.activeEffects = const [],
    this.activeCaption,
    required this.onTogglePlay,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    // Check if any visual effects are active at the current playhead
    bool hasGlitch = false;
    bool hasFlash = false;
    double zoomFactor = 1.0;

    for (final eff in activeEffects) {
      if (playhead >= eff.startTime && playhead <= eff.startTime + eff.duration) {
        if (eff.type == EffectType.glitch) hasGlitch = true;
        if (eff.type == EffectType.flash) hasFlash = true;
        if (eff.type == EffectType.zoomBounce) zoomFactor = 1.08;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video Frame (9:16 aspect ratio box)
            AspectRatio(
              aspectRatio: 9 / 16,
              child: Transform.scale(
                scale: (activeItem?.scale ?? 1.0) * zoomFactor,
                child: Transform.rotate(
                  angle: (activeItem?.rotation ?? 0.0) * math.pi / 180,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          hasGlitch ? const Color(0xFF1E1B4B) : const Color(0xFF1E293B),
                          hasGlitch ? const Color(0xFF4C1D95) : const Color(0xFF0F172A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Stylized Grid & Mock Subject
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.secondary],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(alpha: 0.4),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.videocam_rounded, size: 48, color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                activeItem?.title ?? 'Reel Preview',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '9:16 Social Canvas • ${TimeFormatter.formatDetailed(playhead)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        // Vignette simulation
                        if ((activeItem?.vignette ?? 0.0) > 0.0)
                          Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                                radius: 0.85,
                              ),
                            ),
                          ),

                        // Flash overlay
                        if (hasFlash)
                          Container(color: Colors.white.withValues(alpha: 0.45)),

                        // Subtitles Overlay
                        if (activeCaption != null &&
                            playhead >= activeCaption!.startTime &&
                            playhead <= activeCaption!.startTime + activeCaption!.duration)
                          Align(
                            alignment: Alignment(0.0, (activeCaption!.positionY * 2) - 1.0),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                activeCaption!.text,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: activeCaption!.fontName,
                                  fontSize: activeCaption!.fontSize * 0.7,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Controls Overlay at Bottom
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xCC181B24),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
                      iconSize: 32,
                      color: AppTheme.primaryAccent,
                      onPressed: onTogglePlay,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      TimeFormatter.formatDuration(playhead),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                    ),
                    const Text(' / ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(
                      TimeFormatter.formatDuration(duration),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.replay_5_rounded, size: 20, color: Colors.white70),
                      onPressed: () => onSeek(playhead - 5.0),
                      tooltip: 'Back 5s',
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_5_rounded, size: 20, color: Colors.white70),
                      onPressed: () => onSeek(playhead + 5.0),
                      tooltip: 'Forward 5s',
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
}
