import 'package:flutter_test/flutter_test.dart';
import 'package:reeltune/core/services/ffmpeg_service.dart';
import 'package:reeltune/data/models/audio_settings_model.dart';
import 'package:reeltune/data/models/effect_model.dart';
import 'package:reeltune/data/models/timeline_item_model.dart';

void main() {
  group('FFmpegService Tests', () {
    final ffmpeg = FFmpegService();

    test('buildVideoFilterChain generates 9:16 vertical scale and pad', () {
      final items = [
        TimelineItemModel(
          trackId: 'tr_1',
          projectId: 'p_1',
          startTime: 0,
          duration: 5,
          sourceDuration: 5,
          brightness: 0.1,
          contrast: 1.2,
        ),
      ];

      final filter = ffmpeg.buildVideoFilterChain(
        videoItems: items,
        effects: [],
        targetWidth: 1080,
        targetHeight: 1920,
      );

      expect(filter, contains('scale=1080:1920'));
      expect(filter, contains('pad=1080:1920'));
      expect(filter, contains('brightness=0.10'));
      expect(filter, contains('contrast=1.20'));
    });

    test('buildAudioFilterChain preserves original audio when not enhanced', () {
      final originalSettings = AudioSettingsModel(projectId: 'p_1', isEnhanced: false);
      final filter = ffmpeg.buildAudioFilterChain(originalSettings);
      expect(filter, 'anull');
    });

    test('buildAudioFilterChain adds EQ, compressor, limiter, and loudnorm when enhanced', () {
      final enhancedSettings = AudioSettingsModel(
        projectId: 'p_1',
        isEnhanced: true,
        gainDb: 2.0,
        bassGainDb: 3.0,
        midGainDb: -1.0,
        trebleGainDb: 2.5,
        compressorEnabled: true,
        limiterEnabled: true,
        normalizeLoudness: true,
      );

      final filter = ffmpeg.buildAudioFilterChain(enhancedSettings);

      expect(filter, contains('volume=2.0dB'));
      expect(filter, contains('equalizer=f=100'));
      expect(filter, contains('equalizer=f=1000'));
      expect(filter, contains('equalizer=f=10000'));
      expect(filter, contains('acompressor='));
      expect(filter, contains('alimiter='));
      expect(filter, contains('loudnorm=I=-14.0'));
    });

    test('buildVideoFilterChain integrates creative effects', () {
      final effects = [
        EffectModel(
          projectId: 'p_1',
          type: EffectType.gaussianBlur,
          startTime: 1.0,
          duration: 0.5,
          intensity: 0.5,
        ),
        EffectModel(
          projectId: 'p_1',
          type: EffectType.glitch,
          startTime: 2.0,
          duration: 0.5,
        ),
      ];

      final filter = ffmpeg.buildVideoFilterChain(
        videoItems: [],
        effects: effects,
        targetWidth: 1080,
        targetHeight: 1920,
      );

      expect(filter, contains('gblur=sigma=10.0'));
      expect(filter, contains('rgbashift='));
    });
  });
}
