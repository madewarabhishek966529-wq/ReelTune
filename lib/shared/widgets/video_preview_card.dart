import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:reeltune/app/theme.dart';
import 'package:reeltune/core/utilities/time_formatter.dart';
import 'package:reeltune/data/models/caption_model.dart';
import 'package:reeltune/data/models/effect_model.dart';
import 'package:reeltune/data/models/media_file_model.dart';
import 'package:reeltune/data/models/timeline_item_model.dart';

/// Real video preview widget that uses video_player to display actual video
class VideoPreviewCard extends StatefulWidget {
  final double playhead;
  final double duration;
  final bool isPlaying;
  final TimelineItemModel? activeItem;
  final List<EffectModel> activeEffects;
  final CaptionModel? activeCaption;
  final List<MediaFileModel> mediaFiles;
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
    this.mediaFiles = const [],
    required this.onTogglePlay,
    required this.onSeek,
  });

  @override
  State<VideoPreviewCard> createState() => _VideoPreviewCardState();
}

class _VideoPreviewCardState extends State<VideoPreviewCard> {
  VideoPlayerController? _controller;
  String? _currentVideoPath;
  bool _isInitializing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(VideoPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the video source changed
    final newPath = _getActiveVideoPath();
    if (newPath != _currentVideoPath && newPath != null) {
      _initializeVideo();
    }

    // Sync play/pause state
    if (_controller != null && _controller!.value.isInitialized) {
      if (widget.isPlaying && !_controller!.value.isPlaying) {
        _controller!.play();
      } else if (!widget.isPlaying && _controller!.value.isPlaying) {
        _controller!.pause();
      }

      // Sync playhead position (only if difference is > 0.5s to avoid jitter)
      final controllerPos = _controller!.value.position.inMilliseconds / 1000.0;
      if ((controllerPos - widget.playhead).abs() > 0.5) {
        _controller!.seekTo(Duration(milliseconds: (widget.playhead * 1000).toInt()));
      }

      // Sync speed
      if (widget.activeItem != null) {
        final speed = widget.activeItem!.speed.clamp(0.25, 4.0);
        if (_controller!.value.playbackSpeed != speed) {
          _controller!.setPlaybackSpeed(speed);
        }
      }
    }
  }

  String? _getActiveVideoPath() {
    // Find the video file for the currently active/selected item
    if (widget.activeItem != null && widget.mediaFiles.isNotEmpty) {
      final mediaId = widget.activeItem!.mediaFileId;
      if (mediaId != null) {
        try {
          final media = widget.mediaFiles.firstWhere((m) => m.id == mediaId);
          return media.originalPath;
        } catch (_) {}
      }
    }
    // Fall back to first available media file
    if (widget.mediaFiles.isNotEmpty) {
      return widget.mediaFiles.first.originalPath;
    }
    return null;
  }

  Future<void> _initializeVideo() async {
    final path = _getActiveVideoPath();
    if (path == null || path == _currentVideoPath) return;
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    // Dispose old controller
    await _controller?.dispose();
    _controller = null;

    try {
      final file = File(path);
      if (!await file.exists()) {
        setState(() {
          _errorMessage = 'Video file not found';
          _isInitializing = false;
        });
        return;
      }

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      controller.setLooping(false);

      if (widget.isPlaying) {
        controller.play();
      }

      if (mounted) {
        setState(() {
          _controller = controller;
          _currentVideoPath = path;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Cannot play video: ${e.toString().substring(0, math.min(80, e.toString().length))}';
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if any visual effects are active at the current playhead
    bool hasGlitch = false;
    bool hasFlash = false;
    double zoomFactor = 1.0;

    for (final eff in widget.activeEffects) {
      if (widget.playhead >= eff.startTime && widget.playhead <= eff.startTime + eff.duration) {
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
            // Video Frame
            AspectRatio(
              aspectRatio: 9 / 16,
              child: Transform.scale(
                scale: (widget.activeItem?.scale ?? 1.0) * zoomFactor,
                child: Transform.rotate(
                  angle: (widget.activeItem?.rotation ?? 0.0) * math.pi / 180,
                  child: _buildVideoContent(hasGlitch),
                ),
              ),
            ),

            // Vignette simulation
            if ((widget.activeItem?.vignette ?? 0.0) > 0.0)
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

            // Color adjustments overlay
            if (widget.activeItem != null) _buildColorOverlay(widget.activeItem!),

            // Subtitles Overlay
            if (widget.activeCaption != null &&
                widget.playhead >= widget.activeCaption!.startTime &&
                widget.playhead <= widget.activeCaption!.startTime + widget.activeCaption!.duration)
              Align(
                alignment: Alignment(0.0, (widget.activeCaption!.positionY * 2) - 1.0),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    widget.activeCaption!.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: widget.activeCaption!.fontName,
                      fontSize: widget.activeCaption!.fontSize * 0.7,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Controls Overlay at Bottom
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _buildControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent(bool hasGlitch) {
    // Show real video if controller is initialized
    if (_controller != null && _controller!.value.isInitialized) {
      return ColorFiltered(
        colorFilter: hasGlitch
            ? const ColorFilter.matrix([
                1, 0, 0, 0, 20,
                0, 1, 0, 0, -10,
                0, 0, 1, 0, 30,
                0, 0, 0, 1, 0,
              ])
            : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
        child: VideoPlayer(_controller!),
      );
    }

    // Loading state
    if (_isInitializing) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryAccent),
              SizedBox(height: 12),
              Text('Loading video...', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty placeholder state (no media imported)
    return Container(
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
      child: Center(
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
            const Text(
              'Import a video to start editing',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              '9:16 Social Canvas • ${TimeFormatter.formatDetailed(widget.playhead)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOverlay(TimelineItemModel item) {
    // Apply brightness/contrast overlay using ColorFiltered
    if (item.brightness == 0.0 && item.contrast == 1.0 && item.saturation == 1.0) {
      return const SizedBox.shrink();
    }

    // Use a semi-transparent overlay to simulate brightness changes
    if (item.brightness > 0) {
      return Container(
        color: Colors.white.withValues(alpha: item.brightness.clamp(0.0, 0.5)),
      );
    } else if (item.brightness < 0) {
      return Container(
        color: Colors.black.withValues(alpha: item.brightness.abs().clamp(0.0, 0.5)),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xCC181B24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seek bar
          if (widget.duration > 0)
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: AppTheme.primaryAccent,
                inactiveTrackColor: Colors.white24,
                thumbColor: AppTheme.primaryAccent,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: widget.playhead.clamp(0.0, widget.duration),
                max: widget.duration > 0 ? widget.duration : 1.0,
                onChanged: (value) => widget.onSeek(value),
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(widget.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
                iconSize: 32,
                color: AppTheme.primaryAccent,
                onPressed: widget.onTogglePlay,
              ),
              const SizedBox(width: 8),
              Text(
                TimeFormatter.formatDuration(widget.playhead),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
              ),
              const Text(' / ', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                TimeFormatter.formatDuration(widget.duration),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.replay_5_rounded, size: 20, color: Colors.white70),
                onPressed: () => widget.onSeek(widget.playhead - 5.0),
                tooltip: 'Back 5s',
              ),
              IconButton(
                icon: const Icon(Icons.forward_5_rounded, size: 20, color: Colors.white70),
                onPressed: () => widget.onSeek(widget.playhead + 5.0),
                tooltip: 'Forward 5s',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
