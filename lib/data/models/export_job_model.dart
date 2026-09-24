import 'package:uuid/uuid.dart';

enum ExportStatus { pending, running, completed, failed, cancelled }

class ExportPreset {
  final String name;
  final String description;
  final int width;
  final int height;
  final double fps;
  final int videoBitrateKbps;
  final int audioBitrateKbps;
  final String videoCodec;
  final String audioCodec;

  const ExportPreset({
    required this.name,
    required this.description,
    required this.width,
    required this.height,
    this.fps = 30.0,
    this.videoBitrateKbps = 8000,
    this.audioBitrateKbps = 192,
    this.videoCodec = 'libx264',
    this.audioCodec = 'aac',
  });

  static const instagramReel = ExportPreset(
    name: 'Instagram Reel',
    description: '1080x1920 (9:16) H.264 / AAC optimized for Instagram',
    width: 1080,
    height: 1920,
    fps: 30.0,
    videoBitrateKbps: 8000,
    audioBitrateKbps: 192,
  );

  static const youtubeShorts = ExportPreset(
    name: 'YouTube Shorts',
    description: '1080x1920 (9:16) 60 FPS crystal clear vertical video',
    width: 1080,
    height: 1920,
    fps: 60.0,
    videoBitrateKbps: 12000,
    audioBitrateKbps: 256,
  );

  static const tiktok = ExportPreset(
    name: 'TikTok',
    description: '1080x1920 (9:16) H.264 standard bitrate for fast loading',
    width: 1080,
    height: 1920,
    fps: 30.0,
    videoBitrateKbps: 7500,
    audioBitrateKbps: 192,
  );

  static const square1x1 = ExportPreset(
    name: 'Square Feed (1:1)',
    description: '1080x1080 Square post',
    width: 1080,
    height: 1080,
    fps: 30.0,
    videoBitrateKbps: 6000,
    audioBitrateKbps: 192,
  );

  static List<ExportPreset> get allPresets => [
        instagramReel,
        youtubeShorts,
        tiktok,
        square1x1,
      ];
}

class ExportJobModel {
  final String id;
  final String projectId;
  final String projectName;
  final String outputFilename;
  final String outputPath;
  final String presetName;
  final ExportStatus status;
  final double progress; // 0.0 to 1.0
  final int width;
  final int height;
  final double fps;
  final int videoBitrateKbps;
  final int audioBitrateKbps;
  final String? errorReason;
  final int? outputFileSize;
  final double? outputDuration;
  final DateTime createdAt;
  final DateTime? completedAt;

  ExportJobModel({
    String? id,
    required this.projectId,
    required this.projectName,
    required this.outputFilename,
    required this.outputPath,
    required this.presetName,
    this.status = ExportStatus.pending,
    this.progress = 0.0,
    required this.width,
    required this.height,
    this.fps = 30.0,
    this.videoBitrateKbps = 8000,
    this.audioBitrateKbps = 192,
    this.errorReason,
    this.outputFileSize,
    this.outputDuration,
    DateTime? createdAt,
    this.completedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  ExportJobModel copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? outputFilename,
    String? outputPath,
    String? presetName,
    ExportStatus? status,
    double? progress,
    int? width,
    int? height,
    double? fps,
    int? videoBitrateKbps,
    int? audioBitrateKbps,
    String? errorReason,
    int? outputFileSize,
    double? outputDuration,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return ExportJobModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      outputFilename: outputFilename ?? this.outputFilename,
      outputPath: outputPath ?? this.outputPath,
      presetName: presetName ?? this.presetName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      width: width ?? this.width,
      height: height ?? this.height,
      fps: fps ?? this.fps,
      videoBitrateKbps: videoBitrateKbps ?? this.videoBitrateKbps,
      audioBitrateKbps: audioBitrateKbps ?? this.audioBitrateKbps,
      errorReason: errorReason ?? this.errorReason,
      outputFileSize: outputFileSize ?? this.outputFileSize,
      outputDuration: outputDuration ?? this.outputDuration,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'project_name': projectName,
      'output_filename': outputFilename,
      'output_path': outputPath,
      'preset_name': presetName,
      'status': status.name,
      'progress': progress,
      'width': width,
      'height': height,
      'fps': fps,
      'video_bitrate_kbps': videoBitrateKbps,
      'audio_bitrate_kbps': audioBitrateKbps,
      'error_reason': errorReason,
      'output_file_size': outputFileSize,
      'output_duration': outputDuration,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory ExportJobModel.fromMap(Map<String, dynamic> map) {
    return ExportJobModel(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      projectName: (map['project_name'] as String?) ?? 'Project',
      outputFilename: map['output_filename'] as String,
      outputPath: map['output_path'] as String,
      presetName: map['preset_name'] as String,
      status: ExportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ExportStatus.pending,
      ),
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as int?) ?? 1080,
      height: (map['height'] as int?) ?? 1920,
      fps: (map['fps'] as num?)?.toDouble() ?? 30.0,
      videoBitrateKbps: (map['video_bitrate_kbps'] as int?) ?? 8000,
      audioBitrateKbps: (map['audio_bitrate_kbps'] as int?) ?? 192,
      errorReason: map['error_reason'] as String?,
      outputFileSize: map['output_file_size'] as int?,
      outputDuration: (map['output_duration'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      completedAt: map['completed_at'] != null ? DateTime.tryParse(map['completed_at'] as String) : null,
    );
  }
}
