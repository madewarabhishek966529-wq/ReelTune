import 'package:reeltune/core/utilities/time_formatter.dart';
import 'package:reeltune/data/models/caption_model.dart';

class SrtParser {
  /// Parses standard .srt subtitle string into a list of CaptionModel
  static List<CaptionModel> parseSrt(String srtContent, String projectId) {
    final captions = <CaptionModel>[];
    final lines = srtContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

    int index = 0;
    while (index < lines.length) {
      final line = lines[index].trim();
      if (line.isEmpty) {
        index++;
        continue;
      }

      // Check if it's an index number
      if (int.tryParse(line) != null && index + 1 < lines.length) {
        final timeLine = lines[index + 1].trim();
        final arrowIndex = timeLine.indexOf('-->');
        if (arrowIndex != -1) {
          final startStr = timeLine.substring(0, arrowIndex).trim();
          final endStr = timeLine.substring(arrowIndex + 3).trim();

          final startTime = TimeFormatter.parseSrtTime(startStr);
          final endTime = TimeFormatter.parseSrtTime(endStr);
          final duration = (endTime - startTime).clamp(0.1, 3600.0);

          index += 2;
          final textLines = <String>[];
          while (index < lines.length && lines[index].trim().isNotEmpty) {
            textLines.add(lines[index].trim());
            index++;
          }

          final text = textLines.join('\n');
          captions.add(
            CaptionModel(
              projectId: projectId,
              text: text,
              startTime: startTime,
              duration: duration,
            ),
          );
          continue;
        }
      }
      index++;
    }

    return captions;
  }

  /// Exports a list of CaptionModel to standard .srt format
  static String exportToSrt(List<CaptionModel> captions) {
    final sorted = List<CaptionModel>.from(captions)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final buffer = StringBuffer();
    for (int i = 0; i < sorted.length; i++) {
      final cap = sorted[i];
      final endTime = cap.startTime + cap.duration;

      buffer.writeln('${i + 1}');
      buffer.writeln('${TimeFormatter.toSrtTime(cap.startTime)} --> ${TimeFormatter.toSrtTime(endTime)}');
      buffer.writeln(cap.text);
      buffer.writeln();
    }

    return buffer.toString();
  }
}
