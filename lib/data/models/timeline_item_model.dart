import 'package:uuid/uuid.dart';

class TimelineItemModel {
  final String id;
  final String trackId;
  final String projectId;
  final String? mediaFileId;
  final String title;

  // Timeline placement
  final double startTime;
  final double duration;

  // Source media trim
  final double sourceStartTime;
  final double sourceDuration;

  // Playback & Transform
  final double speed;
  final double volume;
  final double opacity;
  final int zIndex;

  // Crop & Transform (non-destructive instructions)
  final double scale;
  final double rotation; // in degrees
  final bool flipHorizontal;
  final bool flipVertical;
  final double positionX; // Normalized -1.0 to 1.0
  final double positionY; // Normalized -1.0 to 1.0
  final String cropPreset; // 'original', '9:16', '16:9', '1:1', '4:5'

  // Visual filters
  final double brightness; // -1.0 to 1.0 (default 0)
  final double contrast; // 0.0 to 2.0 (default 1.0)
  final double saturation; // 0.0 to 2.0 (default 1.0)
  final double exposure; // -2.0 to 2.0 (default 0)
  final double temperature; // -1.0 to 1.0 (default 0)
  final double vignette; // 0.0 to 1.0 (default 0)

  TimelineItemModel({
    String? id,
    required this.trackId,
    required this.projectId,
    this.mediaFileId,
    this.title = 'Clip',
    required this.startTime,
    required this.duration,
    this.sourceStartTime = 0.0,
    required this.sourceDuration,
    this.speed = 1.0,
    this.volume = 1.0,
    this.opacity = 1.0,
    this.zIndex = 0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.positionX = 0.0,
    this.positionY = 0.0,
    this.cropPreset = 'original',
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.exposure = 0.0,
    this.temperature = 0.0,
    this.vignette = 0.0,
  }) : id = id ?? const Uuid().v4();

  TimelineItemModel copyWith({
    String? id,
    String? trackId,
    String? projectId,
    String? mediaFileId,
    String? title,
    double? startTime,
    double? duration,
    double? sourceStartTime,
    double? sourceDuration,
    double? speed,
    double? volume,
    double? opacity,
    int? zIndex,
    double? scale,
    double? rotation,
    bool? flipHorizontal,
    bool? flipVertical,
    double? positionX,
    double? positionY,
    String? cropPreset,
    double? brightness,
    double? contrast,
    double? saturation,
    double? exposure,
    double? temperature,
    double? vignette,
  }) {
    return TimelineItemModel(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      projectId: projectId ?? this.projectId,
      mediaFileId: mediaFileId ?? this.mediaFileId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      sourceStartTime: sourceStartTime ?? this.sourceStartTime,
      sourceDuration: sourceDuration ?? this.sourceDuration,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      opacity: opacity ?? this.opacity,
      zIndex: zIndex ?? this.zIndex,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      cropPreset: cropPreset ?? this.cropPreset,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      exposure: exposure ?? this.exposure,
      temperature: temperature ?? this.temperature,
      vignette: vignette ?? this.vignette,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'track_id': trackId,
      'project_id': projectId,
      'media_file_id': mediaFileId,
      'title': title,
      'start_time': startTime,
      'duration': duration,
      'source_start_time': sourceStartTime,
      'source_duration': sourceDuration,
      'speed': speed,
      'volume': volume,
      'opacity': opacity,
      'z_index': zIndex,
      'scale': scale,
      'rotation': rotation,
      'flip_horizontal': flipHorizontal ? 1 : 0,
      'flip_vertical': flipVertical ? 1 : 0,
      'position_x': positionX,
      'position_y': positionY,
      'crop_preset': cropPreset,
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
      'exposure': exposure,
      'temperature': temperature,
      'vignette': vignette,
    };
  }

  factory TimelineItemModel.fromMap(Map<String, dynamic> map) {
    return TimelineItemModel(
      id: map['id'] as String,
      trackId: map['track_id'] as String,
      projectId: map['project_id'] as String,
      mediaFileId: map['media_file_id'] as String?,
      title: (map['title'] as String?) ?? 'Clip',
      startTime: (map['start_time'] as num).toDouble(),
      duration: (map['duration'] as num).toDouble(),
      sourceStartTime: (map['source_start_time'] as num?)?.toDouble() ?? 0.0,
      sourceDuration: (map['source_duration'] as num).toDouble(),
      speed: (map['speed'] as num?)?.toDouble() ?? 1.0,
      volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      zIndex: (map['z_index'] as int?) ?? 0,
      scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
      flipHorizontal: (map['flip_horizontal'] as int?) == 1,
      flipVertical: (map['flip_vertical'] as int?) == 1,
      positionX: (map['position_x'] as num?)?.toDouble() ?? 0.0,
      positionY: (map['position_y'] as num?)?.toDouble() ?? 0.0,
      cropPreset: (map['crop_preset'] as String?) ?? 'original',
      brightness: (map['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (map['contrast'] as num?)?.toDouble() ?? 1.0,
      saturation: (map['saturation'] as num?)?.toDouble() ?? 1.0,
      exposure: (map['exposure'] as num?)?.toDouble() ?? 0.0,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      vignette: (map['vignette'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
