import 'package:uuid/uuid.dart';

enum EffectType {
  gaussianBlur,
  motionBlur,
  backgroundBlur,
  zoomBounce,
  shake,
  flash,
  fade,
  slide,
  spin,
  glitch,
  colorShift,
  speedRamp,
}

class EffectModel {
  final String id;
  final String projectId;
  final String? timelineItemId;
  final EffectType type;
  final double startTime;
  final double duration;
  final double intensity; // 0.0 to 1.0
  final bool isRandomized;
  final int seed;
  final double beatOffsetSeconds;

  EffectModel({
    String? id,
    required this.projectId,
    this.timelineItemId,
    required this.type,
    required this.startTime,
    required this.duration,
    this.intensity = 0.5,
    this.isRandomized = false,
    this.seed = 42,
    this.beatOffsetSeconds = 0.0,
  }) : id = id ?? const Uuid().v4();

  EffectModel copyWith({
    String? id,
    String? projectId,
    String? timelineItemId,
    EffectType? type,
    double? startTime,
    double? duration,
    double? intensity,
    bool? isRandomized,
    int? seed,
    double? beatOffsetSeconds,
  }) {
    return EffectModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      timelineItemId: timelineItemId ?? this.timelineItemId,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      intensity: intensity ?? this.intensity,
      isRandomized: isRandomized ?? this.isRandomized,
      seed: seed ?? this.seed,
      beatOffsetSeconds: beatOffsetSeconds ?? this.beatOffsetSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'timeline_item_id': timelineItemId,
      'effect_type': type.name,
      'start_time': startTime,
      'duration': duration,
      'intensity': intensity,
      'is_randomized': isRandomized ? 1 : 0,
      'seed': seed,
      'beat_offset_seconds': beatOffsetSeconds,
    };
  }

  factory EffectModel.fromMap(Map<String, dynamic> map) {
    return EffectModel(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      timelineItemId: map['timeline_item_id'] as String?,
      type: EffectType.values.firstWhere(
        (e) => e.name == map['effect_type'],
        orElse: () => EffectType.glitch,
      ),
      startTime: (map['start_time'] as num).toDouble(),
      duration: (map['duration'] as num).toDouble(),
      intensity: (map['intensity'] as num?)?.toDouble() ?? 0.5,
      isRandomized: (map['is_randomized'] as int?) == 1,
      seed: (map['seed'] as int?) ?? 42,
      beatOffsetSeconds: (map['beat_offset_seconds'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
