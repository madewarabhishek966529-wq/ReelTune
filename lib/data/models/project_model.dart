import 'package:uuid/uuid.dart';

class ProjectModel {
  final String id;
  final String name;
  final String description;
  final double duration;
  final int width;
  final int height;
  final double fps;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailPath;
  final bool isRecovered;

  ProjectModel({
    String? id,
    required this.name,
    this.description = '',
    this.duration = 0.0,
    this.width = 1080,
    this.height = 1920,
    this.fps = 30.0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.thumbnailPath,
    this.isRecovered = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ProjectModel copyWith({
    String? id,
    String? name,
    String? description,
    double? duration,
    int? width,
    int? height,
    double? fps,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? thumbnailPath,
    bool? isRecovered,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      fps: fps ?? this.fps,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isRecovered: isRecovered ?? this.isRecovered,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'duration': duration,
      'width': width,
      'height': height,
      'fps': fps,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'thumbnail_path': thumbnailPath,
      'is_recovered': isRecovered ? 1 : 0,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      duration: (map['duration'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as int?) ?? 1080,
      height: (map['height'] as int?) ?? 1920,
      fps: (map['fps'] as num?)?.toDouble() ?? 30.0,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
      thumbnailPath: map['thumbnail_path'] as String?,
      isRecovered: (map['is_recovered'] as int?) == 1,
    );
  }
}
