class TimeFormatter {
  /// Formats seconds to mm:ss or hh:mm:ss
  static String formatDuration(double seconds) {
    if (seconds.isNaN || seconds.isInfinite || seconds < 0) {
      return '00:00';
    }
    final totalSec = seconds.floor();
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;

    final mStr = m.toString().padLeft(2, '0');
    final sStr = s.toString().padLeft(2, '0');

    if (h > 0) {
      final hStr = h.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  /// Formats seconds to mm:ss.ms
  static String formatDetailed(double seconds) {
    if (seconds.isNaN || seconds.isInfinite || seconds < 0) {
      return '00:00.00';
    }
    final totalMs = (seconds * 1000).floor();
    final m = (totalMs ~/ 60000) % 60;
    final s = (totalMs ~/ 1000) % 60;
    final ms = (totalMs % 1000) ~/ 10;

    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
  }

  /// Formats to SRT timestamp (00:00:00,000)
  static String toSrtTime(double seconds) {
    final totalMs = (seconds * 1000).round();
    final h = totalMs ~/ 3600000;
    final m = (totalMs % 3600000) ~/ 60000;
    final s = (totalMs % 60000) ~/ 1000;
    final ms = totalMs % 1000;

    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')},${ms.toString().padLeft(3, '0')}';
  }

  /// Parses SRT timestamp (00:00:00,000 or 00:00:00.000) to seconds
  static double parseSrtTime(String timestamp) {
    final cleaned = timestamp.trim().replaceAll(',', '.');
    final parts = cleaned.split(':');
    if (parts.length != 3) return 0.0;

    final hours = double.tryParse(parts[0]) ?? 0.0;
    final minutes = double.tryParse(parts[1]) ?? 0.0;
    final seconds = double.tryParse(parts[2]) ?? 0.0;

    return (hours * 3600) + (minutes * 60) + seconds;
  }
}
