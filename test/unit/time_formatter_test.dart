import 'package:flutter_test/flutter_test.dart';
import 'package:reeltune/core/utilities/time_formatter.dart';

void main() {
  group('TimeFormatter Tests', () {
    test('formatDuration formats minutes and seconds correctly', () {
      expect(TimeFormatter.formatDuration(0.0), '00:00');
      expect(TimeFormatter.formatDuration(65.0), '01:05');
      expect(TimeFormatter.formatDuration(3665.0), '01:01:05');
      expect(TimeFormatter.formatDuration(-5.0), '00:00');
    });

    test('formatDetailed formats milliseconds accurately', () {
      expect(TimeFormatter.formatDetailed(12.45), '00:12.45');
      expect(TimeFormatter.formatDetailed(75.12), '01:15.12');
    });

    test('toSrtTime and parseSrtTime round-trip correctly', () {
      const seconds = 73.456;
      final srtTime = TimeFormatter.toSrtTime(seconds);
      expect(srtTime, '00:01:13,456');

      final parsed = TimeFormatter.parseSrtTime(srtTime);
      expect(parsed, closeTo(73.456, 0.001));
    });
  });
}
