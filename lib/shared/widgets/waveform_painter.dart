import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final List<double> points; // 0.0 to 1.0
  final Color waveColor;
  final Color beatColor;
  final List<double> beatTimestamps;
  final double duration;
  final double playhead;

  WaveformPainter({
    required this.points,
    required this.waveColor,
    required this.beatColor,
    this.beatTimestamps = const [],
    this.duration = 15.0,
    this.playhead = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final centerY = size.height / 2;
    final barWidth = size.width / points.length;
    final wavePaint = Paint()
      ..color = waveColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (barWidth * 0.7).clamp(1.5, 4.0);

    for (int i = 0; i < points.length; i++) {
      final x = i * barWidth;
      final amp = (points[i] * (size.height * 0.42)).clamp(2.0, size.height * 0.48);
      canvas.drawLine(Offset(x, centerY - amp), Offset(x, centerY + amp), wavePaint);
    }

    // Paint beat marker dots
    if (beatTimestamps.isNotEmpty && duration > 0) {
      final beatPaint = Paint()
        ..color = beatColor
        ..style = PaintingStyle.fill;

      for (final beat in beatTimestamps) {
        final x = (beat / duration) * size.width;
        if (x >= 0 && x <= size.width) {
          canvas.drawCircle(Offset(x, 4), 3.0, beatPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.playhead != playhead ||
        oldDelegate.waveColor != waveColor;
  }
}
