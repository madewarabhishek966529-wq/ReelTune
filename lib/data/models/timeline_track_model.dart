import 'package:uuid/uuid.dart';

enum TrackType { video, audio, text, effects }

class TimelineTrackModel {
  final String id;
  final String projectId;
  final TrackType type;
  final int index;
  final bool isMuted;
  final bool isLocked;
  final double volume;

  TimelineTrackModel({
    String? id,
    required this.projectId,
    required this.type,
    required this.index,
    this.isMuted = false,
    this.isLocked = false,
    this.volume = 1.0,
  }) : id = id ?? const Uuid().v4();

  TimelineTrackModel copyWith({
    String? id,
    String? projectId,
    TrackType? type,
    int? index,
    bool? isMuted,
    bool? isLocked,
    double? volume,
  }) {
    return TimelineTrackModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      index: index ?? this.index,
      isMuted: isMuted ?? this.isMuted,
      isLocked: isLocked ?? this.isLocked,
      volume: volume ?? this.volume,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'track_type': type.name,
      'track_index': index,
      'is_muted': isMuted ? 1 : 0,
      'is_locked': isLocked ? 1 : 0,
      'volume': volume,
    };
  }

  factory TimelineTrackModel.fromMap(Map<String, dynamic> map) {
    return TimelineTrackModel(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      type: TrackType.values.firstWhere(
        (e) => e.name == map['track_type'],
        orElse: () => TrackType.video,
      ),
      index: (map['track_index'] as int?) ?? 0,
      isMuted: (map['is_muted'] as int?) == 1,
      isLocked: (map['is_locked'] as int?) == 1,
      volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
