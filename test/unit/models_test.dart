import 'package:flutter_test/flutter_test.dart';
import 'package:reeltune/data/models/audio_settings_model.dart';
import 'package:reeltune/data/models/effect_model.dart';
import 'package:reeltune/data/models/project_model.dart';
import 'package:reeltune/data/models/timeline_item_model.dart';

void main() {
  group('Models Serialization Tests', () {
    test('ProjectModel serialization and copyWith', () {
      final project = ProjectModel(
        name: 'My Reel',
        description: 'First reel test',
        duration: 15.0,
        width: 1080,
        height: 1920,
      );

      final map = project.toMap();
      expect(map['name'], 'My Reel');
      expect(map['width'], 1080);
      expect(map['height'], 1920);

      final fromMap = ProjectModel.fromMap(map);
      expect(fromMap.id, project.id);
      expect(fromMap.name, project.name);
      expect(fromMap.duration, 15.0);

      final copy = project.copyWith(name: 'Updated Reel');
      expect(copy.name, 'Updated Reel');
      expect(copy.id, project.id);
    });

    test('TimelineItemModel non-destructive crop and visual filters', () {
      final item = TimelineItemModel(
        trackId: 'track_1',
        projectId: 'proj_1',
        title: 'Clip 1',
        startTime: 2.0,
        duration: 5.0,
        sourceDuration: 5.0,
        cropPreset: '9:16',
        contrast: 1.25,
        vignette: 0.3,
      );

      final map = item.toMap();
      expect(map['crop_preset'], '9:16');
      expect(map['contrast'], 1.25);
      expect(map['vignette'], 0.3);

      final fromMap = TimelineItemModel.fromMap(map);
      expect(fromMap.cropPreset, '9:16');
      expect(fromMap.contrast, 1.25);
      expect(fromMap.vignette, 0.3);
    });

    test('AudioSettingsModel preserves original audio by default', () {
      final settings = AudioSettingsModel(projectId: 'p_1');
      expect(settings.isEnhanced, false);
      expect(settings.targetLufs, -14.0);

      final map = settings.toMap();
      expect(map['is_enhanced'], 0);
      final fromMap = AudioSettingsModel.fromMap(map);
      expect(fromMap.isEnhanced, false);
    });

    test('EffectModel random seed and beat offset', () {
      final effect = EffectModel(
        projectId: 'p_1',
        type: EffectType.zoomBounce,
        startTime: 4.0,
        duration: 0.5,
        seed: 1234,
        isRandomized: true,
      );

      final map = effect.toMap();
      expect(map['effect_type'], 'zoomBounce');
      expect(map['seed'], 1234);
      expect(map['is_randomized'], 1);

      final fromMap = EffectModel.fromMap(map);
      expect(fromMap.type, EffectType.zoomBounce);
      expect(fromMap.seed, 1234);
      expect(fromMap.isRandomized, true);
    });
  });
}
