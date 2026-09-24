import 'package:flutter_test/flutter_test.dart';
import 'package:reeltune/core/utilities/srt_parser.dart';
import 'package:reeltune/data/models/caption_model.dart';

void main() {
  group('SrtParser Tests', () {
    test('parseSrt parses standard subtitles correctly', () {
      const sampleSrt = '''
1
00:00:01,000 --> 00:00:03,500
Welcome to ReelTune!

2
00:00:04,000 --> 00:00:07,200
Non-destructive editing studio.
''';

      final captions = SrtParser.parseSrt(sampleSrt, 'proj_1');
      expect(captions.length, 2);
      expect(captions[0].text, 'Welcome to ReelTune!');
      expect(captions[0].startTime, 1.0);
      expect(captions[0].duration, 2.5);

      expect(captions[1].text, 'Non-destructive editing studio.');
      expect(captions[1].startTime, 4.0);
      expect(captions[1].duration, closeTo(3.2, 0.001));
    });

    test('exportToSrt exports valid SRT format', () {
      final captions = [
        CaptionModel(projectId: 'proj_1', text: 'Hello World', startTime: 0.0, duration: 2.0),
        CaptionModel(projectId: 'proj_1', text: 'Second Line', startTime: 2.5, duration: 1.5),
      ];

      final srt = SrtParser.exportToSrt(captions);
      expect(srt, contains('1\n00:00:00,000 --> 00:00:02,000\nHello World'));
      expect(srt, contains('2\n00:00:02,500 --> 00:00:04,000\nSecond Line'));
    });
  });
}
