import 'package:flutter/material.dart';
import 'package:reeltune/app/theme.dart';
import 'package:reeltune/core/utilities/time_formatter.dart';
import 'package:reeltune/data/models/timeline_track_model.dart';
import 'package:reeltune/features/editor/editor_provider.dart';
import 'package:reeltune/features/editor/editor_state.dart';
import 'package:reeltune/shared/widgets/waveform_painter.dart';

class TimelineView extends StatelessWidget {
  final EditorState editorState;
  final EditorNotifier editorNotifier;

  const TimelineView({
    super.key,
    required this.editorState,
    required this.editorNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final pps = editorState.pixelsPerSecond;
    final totalDuration = editorState.maxTimelineDuration;
    final timelineWidth = (totalDuration * pps) + 400.0;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          // Timeline Toolbar (Transport, Split, Duplicate, Undo/Redo, Zoom)
          _buildTimelineToolbar(context),

          const Divider(height: 1),

          // Main Multi-track scrollable body
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Track Headers (Left sidebar: Video, Audio, Captions, FX)
                  _buildTrackHeaders(),

                  // Scrollable Tracks Area with Playhead
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          final tappedTime = details.localPosition.dx / pps;
                          editorNotifier.seekPlayhead(tappedTime);
                        },
                        child: SizedBox(
                          width: timelineWidth,
                          child: Stack(
                            children: [
                              // Tracks Content (isolated in RepaintBoundary for smooth 60fps performance)
                              RepaintBoundary(
                                child: Column(
                                  children: [
                                    _buildTimeRuler(timelineWidth, pps),
                                    const Divider(height: 1),
                                    ...editorState.tracks.map((track) {
                                      return _buildTrackLane(track, pps);
                                    }),
                                  ],
                                ),
                              ),

                              // Playhead vertical line & cursor
                              Positioned(
                                left: editorState.playhead * pps,
                                top: 0,
                                bottom: 0,
                                child: IgnorePointer(
                                  child: Container(
                                    width: 2,
                                    color: Colors.redAccent,
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const Spacer(),
                                      ],
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineToolbar(BuildContext context) {
    final canUndo = editorState.undoStack.isNotEmpty;
    final canRedo = editorState.redoStack.isNotEmpty;
    final hasSelection = editorState.selectedItem != null;

    return Container(
      height: 44,
      color: AppTheme.surfaceVariant,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play / Pause
            IconButton(
              icon: Icon(editorState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
              color: Colors.white,
              iconSize: 22,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: editorState.isPlaying ? 'Pause' : 'Play',
              onPressed: () => editorNotifier.togglePlayPause(),
            ),
            const SizedBox(width: 4),

            // Current time readout
            Text(
              TimeFormatter.formatDetailed(editorState.playhead),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryAccent),
            ),
            const Text(' / ', style: TextStyle(color: Colors.grey, fontSize: 11)),
            Text(
              TimeFormatter.formatDetailed(editorState.maxTimelineDuration),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),

            const VerticalDivider(width: 16, indent: 8, endIndent: 8),

            // Split at Playhead
            IconButton(
              icon: const Icon(Icons.content_cut_rounded, size: 18),
              color: hasSelection ? Colors.white : Colors.grey.shade600,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Split at Playhead',
              onPressed: hasSelection ? () => editorNotifier.splitItemAtPlayhead() : null,
            ),

            // Duplicate
            IconButton(
              icon: const Icon(Icons.content_copy_rounded, size: 18),
              color: hasSelection ? Colors.white : Colors.grey.shade600,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Duplicate Clip',
              onPressed: hasSelection ? () => editorNotifier.duplicateItem(editorState.selectedItemId!) : null,
            ),

            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              color: hasSelection ? Colors.redAccent : Colors.grey.shade600,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Delete Clip',
              onPressed: hasSelection ? () => editorNotifier.deleteItem(editorState.selectedItemId!) : null,
            ),

            const VerticalDivider(width: 16, indent: 8, endIndent: 8),

            // Undo / Redo
            IconButton(
              icon: const Icon(Icons.undo_rounded, size: 18),
              color: canUndo ? Colors.white : Colors.grey.shade600,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Undo',
              onPressed: canUndo ? () => editorNotifier.undo() : null,
            ),
            IconButton(
              icon: const Icon(Icons.redo_rounded, size: 18),
              color: canRedo ? Colors.white : Colors.grey.shade600,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Redo',
              onPressed: canRedo ? () => editorNotifier.redo() : null,
            ),

            const VerticalDivider(width: 16, indent: 8, endIndent: 8),

            // Timeline Zoom controls
            const Icon(Icons.zoom_out, size: 16, color: Colors.grey),
            SizedBox(
              width: 80,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  trackHeight: 2,
                ),
                child: Slider(
                  value: editorState.pixelsPerSecond,
                  min: 15.0,
                  max: 150.0,
                  onChanged: (v) => editorNotifier.setZoom(v),
                ),
              ),
            ),
            const Icon(Icons.zoom_in, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackHeaders() {
    return Container(
      width: 120,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceVariant,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: AppTheme.surface,
            child: const Text('TRACKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          const Divider(height: 1),
          ...editorState.tracks.map((track) {
            return Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Icon(_trackIcon(track.type), size: 16, color: _trackColor(track.type)),
                  const SizedBox(width: 6),
                  Text(
                    _trackLabel(track.type),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeRuler(double width, double pps) {
    return Container(
      height: 24,
      width: width,
      color: const Color(0xFF141722),
      child: CustomPaint(
        painter: _TimeRulerPainter(pps: pps),
      ),
    );
  }

  Widget _buildTrackLane(TimelineTrackModel track, double pps) {
    final trackItems = editorState.items.where((i) => i.trackId == track.id).toList();

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF161922),
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Stack(
        children: [
          // Render clips on this track
          ...trackItems.map((item) {
            final isSelected = editorState.selectedItemId == item.id;
            final left = item.startTime * pps;
            final width = (item.duration * pps).clamp(24.0, double.infinity);

            return Positioned(
              left: left,
              top: 4,
              bottom: 4,
              width: width,
              child: GestureDetector(
                onTap: () => editorNotifier.selectItem(item.id),
                child: Container(
                  decoration: BoxDecoration(
                    color: _trackColor(track.type).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? Colors.white : _trackColor(track.type),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Audio waveform display if audio track
                      if (track.type == TrackType.audio || track.type == TrackType.video)
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.6,
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: WaveformPainter(
                                  points: editorState.audioAnalysis?.waveformPoints ?? [],
                                  waveColor: _trackColor(track.type),
                                  beatColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Clip Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Render creative effects lane
          if (track.type == TrackType.effects)
            ...editorState.effects.map((eff) {
              final left = eff.startTime * pps;
              final width = (eff.duration * pps).clamp(20.0, double.infinity);
              return Positioned(
                left: left,
                top: 8,
                bottom: 8,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.effectsTrackColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.effectsTrackColor),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    eff.type.name,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),

          // Render captions lane
          if (track.type == TrackType.text)
            ...editorState.captions.map((cap) {
              final left = cap.startTime * pps;
              final width = (cap.duration * pps).clamp(24.0, double.infinity);
              return Positioned(
                left: left,
                top: 8,
                bottom: 8,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.captionsTrackColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.captionsTrackColor),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    cap.text,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  IconData _trackIcon(TrackType type) {
    switch (type) {
      case TrackType.video:
        return Icons.videocam;
      case TrackType.audio:
        return Icons.audiotrack;
      case TrackType.text:
        return Icons.subtitles;
      case TrackType.effects:
        return Icons.auto_awesome;
    }
  }

  String _trackLabel(TrackType type) {
    switch (type) {
      case TrackType.video:
        return 'Video';
      case TrackType.audio:
        return 'Audio';
      case TrackType.text:
        return 'Captions';
      case TrackType.effects:
        return 'Effects';
    }
  }

  Color _trackColor(TrackType type) {
    switch (type) {
      case TrackType.video:
        return AppTheme.videoTrackColor;
      case TrackType.audio:
        return AppTheme.audioTrackColor;
      case TrackType.text:
        return AppTheme.captionsTrackColor;
      case TrackType.effects:
        return AppTheme.effectsTrackColor;
    }
  }
}

class _TimeRulerPainter extends CustomPainter {
  final double pps;
  _TimeRulerPainter({required this.pps});

  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(color: Colors.grey.shade400, fontSize: 9);

    final totalSeconds = (size.width / pps).ceil();
    for (int sec = 0; sec <= totalSeconds; sec++) {
      final x = sec * pps;
      // Main second tick
      canvas.drawLine(Offset(x, size.height - 8), Offset(x, size.height), tickPaint);

      // Label every 2 or 5 seconds depending on zoom
      if (sec % (pps > 40 ? 2 : 5) == 0) {
        final span = TextSpan(text: '${sec}s', style: textStyle);
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(x + 2, 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimeRulerPainter oldDelegate) => oldDelegate.pps != pps;
}
