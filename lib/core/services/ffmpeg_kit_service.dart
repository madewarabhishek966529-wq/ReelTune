import 'dart:async';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/statistics.dart';
import 'package:reeltune/core/logging/app_logger.dart';

/// Wrapper around ffmpeg_kit_flutter for Android video processing
class FFmpegKitService {
  static final FFmpegKitService _instance = FFmpegKitService._internal();
  factory FFmpegKitService() => _instance;
  FFmpegKitService._internal();

  /// Execute an FFmpeg command and return a progress stream
  Stream<double> executeWithProgress(String command, {double? totalDurationSecs}) async* {
    AppLogger.i('FFmpegKitService', 'Executing: ffmpeg $command');

    final completer = Completer<bool>();

    final session = await FFmpegKit.executeAsync(
      command,
      (session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          AppLogger.i('FFmpegKitService', 'FFmpeg command succeeded');
          completer.complete(true);
        } else if (ReturnCode.isCancel(returnCode)) {
          AppLogger.w('FFmpegKitService', 'FFmpeg command cancelled');
          completer.complete(false);
        } else {
          final logs = await session.getAllLogsAsString();
          AppLogger.e('FFmpegKitService', 'FFmpeg command failed: $logs');
          completer.complete(false);
        }
      },
      (log) {
        // Log callback
        AppLogger.d('FFmpegKit', log.getMessage());
      },
      (Statistics statistics) {
        // Statistics callback — we can track progress here
        if (totalDurationSecs != null && totalDurationSecs > 0) {
          final timeMs = statistics.getTime();
          if (timeMs > 0) {
            final progress = (timeMs / 1000.0) / totalDurationSecs;
            // We can't yield from a callback, so we just log
            AppLogger.d('FFmpegKit', 'Progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
        }
      },
    );

    // Poll for progress while the session runs
    int ticks = 0;
    while (!completer.isCompleted) {
      await Future.delayed(const Duration(milliseconds: 500));
      ticks++;

      // Estimate progress from elapsed time if total duration is known
      if (totalDurationSecs != null && totalDurationSecs > 0) {
        try {
          final stats = await session.getStatistics();
          if (stats.isNotEmpty) {
            final lastStat = stats.last;
            final timeMs = lastStat.getTime();
            if (timeMs > 0) {
              final progress = ((timeMs / 1000.0) / totalDurationSecs).clamp(0.0, 0.99);
              yield progress;
            }
          }
        } catch (_) {}
      } else {
        // Fallback: linear estimation based on time elapsed
        yield (ticks * 0.05).clamp(0.0, 0.95);
      }
    }

    final success = await completer.future;
    if (success) {
      yield 1.0;
    } else {
      throw Exception('FFmpeg execution failed');
    }
  }

  /// Execute an FFprobe command and return the JSON output
  Future<String?> probe(String filePath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(filePath);
      final info = session.getMediaInformation();
      if (info != null) {
        // Build a JSON-like map from MediaInformation
        final streams = info.getStreams();
        final format = info.getFormatProperties();

        final streamsJson = streams.map((s) => s.getAllProperties()).toList();

        return '{"streams": $streamsJson, "format": $format}';
      }
    } catch (e) {
      AppLogger.e('FFmpegKitService', 'FFprobe error', e);
    }
    return null;
  }

  /// Cancel all running FFmpeg sessions
  Future<void> cancelAll() async {
    await FFmpegKit.cancel();
  }
}
