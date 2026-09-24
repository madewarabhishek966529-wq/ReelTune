import 'package:uuid/uuid.dart';

class MediaFileModel {
  final String id;
  final String projectId;
  final String originalPath;
  final String filename;
  final int fileSize;
  final double duration;
  final int width;
  final int height;
  final double fps;
  final String videoCodec;
  final String audioCodec;
  final int sampleRate;
  final int channels;
  final String? thumbnailPath;
  final String? proxyPath;
  final bool isOriginalPreserved;
  final DateTime importedAt;

  MediaFileModel({
    String? id,
    required this.projectId,
    required this.originalPath,
    required this.filename,
    required this.fileSize,
    required this.duration,
    this.width = 1080,
    this.height = 1920,
    this.fps = 30.0,
    this.videoCodec = 'h264',
    this.audioCodec = 'aac',
    this.sampleRate = 44100,
    this.channels = 2,
    this.thumbnailPath,
    this.proxyPath,
    this.isOriginalPreserved = true,
    DateTime? importedAt,
  })  : id = id ?? const Uuid().v4(),
        importedAt = importedAt ?? DateTime.now();

  MediaFileModel copyWith({
    String? id,
    String? projectId,
    String? originalPath,
    String? filename,
    int? fileSize,
    double? duration,
    int? width,
    int? height,
    double? fps,
    String? videoCodec,
    String? audioCodec,
    int? sampleRate,
    int? channels,
    String? thumbnailPath,
    String? proxyPath,
    bool? isOriginalPreserved,
    DateTime? importedAt,
  }) {
    return MediaFileModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      originalPath: originalPath ?? this.originalPath,
      filename: filename ?? this.filename,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      fps: fps ?? this.fps,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      proxyPath: proxyPath ?? this.proxyPath,
      isOriginalPreserved: isOriginalPreserved ?? this.isOriginalPreserved,
      importedAt: importedAt ?? this.importedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'original_path': originalPath,
      'filename': filename,
      'file_size': fileSize,
      'duration': duration,
      'width': width,
      'height': height,
      'fps': fps,
      'video_codec': videoCodec,
      'audio_codec': audioCodec,
      'sample_rate': sampleRate,
      'channels': channels,
      'thumbnail_path': thumbnailPath,
      'proxy_path': proxyPath,
      'is_original_preserved': isOriginalPreserved ? 1 : 0,
      'imported_at': importedAt.toIso8601String(),
    };
  }

  factory MediaFileModel.fromMap(Map<String, dynamic> map) {
    return MediaFileModel(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      originalPath: map['original_path'] as String,
      filename: map['filename'] as String,
      fileSize: (map['file_size'] as int?) ?? 0,
      duration: (map['duration'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as int?) ?? 1080,
      height: (map['height'] as int?) ?? 1920,
      fps: (map['fps'] as num?)?.toDouble() ?? 30.0,
      videoCodec: (map['video_codec'] as String?) ?? 'h264',
      audioCodec: (map['audio_codec'] as String?) ?? 'aac',
      sampleRate: (map['sample_rate'] as int?) ?? 44100,
      channels: (map['channels'] as int?) ?? 2,
      thumbnailPath: map['thumbnail_path'] as String?,
      proxyPath: map['proxy_path'] as String?,
      isOriginalPreserved: (map['is_original_preserved'] as int?) == 1,
      importedAt: DateTime.tryParse(map['imported_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
