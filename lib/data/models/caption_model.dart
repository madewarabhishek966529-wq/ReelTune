import 'package:uuid/uuid.dart';

class CaptionModel {
  final String id;
  final String projectId;
  final String text;
  final double startTime;
  final double duration;
  final String fontName;
  final double fontSize;
  final String textColorHex;
  final String outlineColorHex;
  final String backgroundColorHex;
  final String alignment; // 'center', 'left', 'right'
  final double positionY; // 0.0 (top) to 1.0 (bottom), default 0.85

  CaptionModel({
    String? id,
    required this.projectId,
    required this.text,
    required this.startTime,
    required this.duration,
    this.fontName = 'Roboto',
    this.fontSize = 24.0,
    this.textColorHex = '#FFFFFF',
    this.outlineColorHex = '#000000',
    this.backgroundColorHex = '#00000088',
    this.alignment = 'center',
    this.positionY = 0.85,
  }) : id = id ?? const Uuid().v4();

  CaptionModel copyWith({
    String? id,
    String? projectId,
    String? text,
    double? startTime,
    double? duration,
    String? fontName,
    double? fontSize,
    String? textColorHex,
    String? outlineColorHex,
    String? backgroundColorHex,
    String? alignment,
    double? positionY,
  }) {
    return CaptionModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      text: text ?? this.text,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      fontName: fontName ?? this.fontName,
      fontSize: fontSize ?? this.fontSize,
      textColorHex: textColorHex ?? this.textColorHex,
      outlineColorHex: outlineColorHex ?? this.outlineColorHex,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      alignment: alignment ?? this.alignment,
      positionY: positionY ?? this.positionY,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'text': text,
      'start_time': startTime,
      'duration': duration,
      'font_name': fontName,
      'font_size': fontSize,
      'text_color': textColorHex,
      'outline_color': outlineColorHex,
      'background_color': backgroundColorHex,
      'alignment': alignment,
      'position_y': positionY,
    };
  }

  factory CaptionModel.fromMap(Map<String, dynamic> map) {
    return CaptionModel(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      text: (map['text'] as String?) ?? '',
      startTime: (map['start_time'] as num).toDouble(),
      duration: (map['duration'] as num).toDouble(),
      fontName: (map['font_name'] as String?) ?? 'Roboto',
      fontSize: (map['font_size'] as num?)?.toDouble() ?? 24.0,
      textColorHex: (map['text_color'] as String?) ?? '#FFFFFF',
      outlineColorHex: (map['outline_color'] as String?) ?? '#000000',
      backgroundColorHex: (map['background_color'] as String?) ?? '#00000088',
      alignment: (map['alignment'] as String?) ?? 'center',
      positionY: (map['position_y'] as num?)?.toDouble() ?? 0.85,
    );
  }
}
