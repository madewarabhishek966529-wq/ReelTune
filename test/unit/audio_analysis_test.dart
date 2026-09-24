import 'package:flutter_test/flutter_test.dart';
import 'package:reeltune/core/services/audio_analysis_service.dart';

void main() {
  group('AudioAnalysisService Tests', () {
    final service = AudioAnalysisService();

    test('analyzeAudio generates beat timestamps and valid BPM', () async {
      final analysis = await service.analyzeAudio(
        filePath: 'test/fixtures/sample_audio.wav',
        duration: 10.0,
      );

      expect(analysis.bpm, greaterThanOrEqualTo(100.0));
      expect(analysis.bpm, lessThanOrEqualTo(160.0));
      expect(analysis.beatTimestamps.isNotEmpty, true);
      expect(analysis.downbeats.isNotEmpty, true);
      expect(analysis.waveformPoints.length, 120);
      expect(analysis.hasClipping, false);
    });

    test('AudioAnalysisData.mock creates consistent fallback waveform and beats', () {
      final mock = AudioAnalysisData.mock(duration: 15.0, bpm: 120.0);
      expect(mock.bpm, 120.0);
      expect(mock.waveformPoints.length, greaterThan(50));
      expect(mock.downbeats.length, greaterThan(0));
    });
  });
}
