import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:reeltune/core/errors/failures.dart';
import 'package:reeltune/core/logging/app_logger.dart';
import 'package:reeltune/core/services/ffmpeg_kit_service.dart';
import 'package:reeltune/data/models/audio_settings_model.dart';
import 'package:reeltune/data/models/effect_model.dart';
import 'package:reeltune/data/models/timeline_item_model.dart';

class FFmpegProbeResult {
  final double duration;
  final int width;
  final int height;
  final double fps;
  final String videoCodec;
  final String audioCodec;
  final int sampleRate;
  final int channels;
  final int fileSize;

  FFmpegProbeResult({
    required this.duration,
    required this.width,
    required this.height,
    required this.fps,
    required this.videoCodec,
    required this.audioCodec,
    required this.sampleRate,
    required this.channels,
    required this.fileSize,
  });
}

class FFmpegService {
  static final FFmpegService _instance = FFmpegService._internal();
  factory FFmpegService() => _instance;
  FFmpegService._internal();

  String? _ffmpegPath;
  String? _ffprobePath;
  bool _isDesktopFFmpegAvailable = false;
  bool _isFFmpegKitAvailable = false;

  bool get isFFmpegAvailable => _isDesktopFFmpegAvailable || _isFFmpegKitAvailable;
  String? get ffmpegPath => _ffmpegPath;

  /// Check whether ffmpeg is available
  Future<bool> checkAvailability([String? customBinaryPath]) async {
    // On Android, use ffmpeg_kit_flutter
    if (Platform.isAndroid) {
      _isFFmpegKitAvailable = true;
      AppLogger.i('FFmpegService', 'FFmpegKit available on Android');
      return true;
    }

    // On Desktop, try system ffmpeg in PATH
    try {
      final probeCmd = customBinaryPath != null ? '$customBinaryPath/ffmpeg' : 'ffmpeg';
      final result = await Process.run(probeCmd, ['-version']);
      if (result.exitCode == 0) {
        _isDesktopFFmpegAvailable = true;
        _ffmpegPath = probeCmd;
        _ffprobePath = customBinaryPath != null ? '$customBinaryPath/ffprobe' : 'ffprobe';
        AppLogger.i('FFmpegService', 'FFmpeg detected at $_ffmpegPath');
        return true;
      }
    } catch (_) {
      _isDesktopFFmpegAvailable = false;
    }

    AppLogger.i('FFmpegService', 'FFmpeg not found in PATH. Export will use file-copy mode.');
    return false;
  }

  /// Probe media file metadata
  Future<FFmpegProbeResult> probeMedia(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw MediaValidationFailure('Media file does not exist at: $filePath');
    }

    final fileSize = await file.length();

    // Try FFmpegKit on Android
    if (_isFFmpegKitAvailable && Platform.isAndroid) {
      try {
        final jsonStr = await FFmpegKitService().probe(filePath);
        if (jsonStr != null) {
          return _parseProbeJson(jsonStr, fileSize);
        }
      } catch (e) {
        AppLogger.w('FFmpegService', 'FFmpegKit probe error: $e');
      }
    }

    // Try ffprobe on desktop
    if (_isDesktopFFmpegAvailable && _ffprobePath != null) {
      try {
        final result = await Process.run(_ffprobePath!, [
          '-v', 'quiet',
          '-print_format', 'json',
          '-show_format',
          '-show_streams',
          filePath,
        ]);

        if (result.exitCode == 0) {
          return _parseProbeJson(result.stdout as String, fileSize);
        }
      } catch (e) {
        AppLogger.w('FFmpegService', 'ffprobe error: $e');
      }
    }

    // Fallback: estimate from file size
    return _estimateProbeResult(file, fileSize);
  }

  FFmpegProbeResult _parseProbeJson(String jsonStr, int fileSize) {
    try {
      final data = jsonDecode(jsonStr);
      final streams = data['streams'] as List<dynamic>? ?? [];
      final format = data['format'] as Map<String, dynamic>? ?? {};

      final duration = double.tryParse(format['duration']?.toString() ?? '0') ?? 15.0;

      Map<String, dynamic>? videoStream;
      Map<String, dynamic>? audioStream;

      for (final stream in streams) {
        final codecType = stream['codec_type']?.toString() ?? '';
        if (codecType == 'video' && videoStream == null) {
          videoStream = stream as Map<String, dynamic>;
        } else if (codecType == 'audio' && audioStream == null) {
          audioStream = stream as Map<String, dynamic>;
        }
      }

      final width = _parseInt(videoStream?['width']) ?? 1080;
      final height = _parseInt(videoStream?['height']) ?? 1920;
      final videoCodec = (videoStream?['codec_name'] as String?) ?? 'h264';
      final audioCodec = (audioStream?['codec_name'] as String?) ?? 'aac';
      final sampleRate = _parseInt(audioStream?['sample_rate']) ?? 44100;
      final channels = _parseInt(audioStream?['channels']) ?? 2;

      // Parse fps from r_frame_rate
      double fps = 30.0;
      final rFrameRate = videoStream?['r_frame_rate']?.toString();
      if (rFrameRate != null && rFrameRate.contains('/')) {
        final parts = rFrameRate.split('/');
        final num = double.tryParse(parts[0]) ?? 30;
        final den = double.tryParse(parts[1]) ?? 1;
        if (den > 0) fps = num / den;
      }

      return FFmpegProbeResult(
        duration: duration > 0 ? duration : 15.0,
        width: width,
        height: height,
        fps: fps,
        videoCodec: videoCodec,
        audioCodec: audioCodec,
        sampleRate: sampleRate,
        channels: channels,
        fileSize: fileSize,
      );
    } catch (e) {
      AppLogger.w('FFmpegService', 'JSON parse error: $e');
      return FFmpegProbeResult(
        duration: 15.0,
        width: 1080,
        height: 1920,
        fps: 30.0,
        videoCodec: 'h264',
        audioCodec: 'aac',
        sampleRate: 44100,
        channels: 2,
        fileSize: fileSize,
      );
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  FFmpegProbeResult _estimateProbeResult(File file, int fileSize) {
    // Rough estimate: ~1MB per second at typical mobile bitrate
    final estimatedDuration = (fileSize / (1024 * 1024)).clamp(1.0, 600.0);

    return FFmpegProbeResult(
      duration: estimatedDuration,
      width: 1080,
      height: 1920,
      fps: 30.0,
      videoCodec: 'h264',
      audioCodec: 'aac',
      sampleRate: 44100,
      channels: 2,
      fileSize: fileSize > 0 ? fileSize : 2048000,
    );
  }

  /// Build FFmpeg video filter chain
  String buildVideoFilterChain({
    required List<TimelineItemModel> videoItems,
    required List<EffectModel> effects,
    required int targetWidth,
    required int targetHeight,
  }) {
    final filters = <String>[];

    filters.add(
      'scale=$targetWidth:$targetHeight:force_original_aspect_ratio=decrease,pad=$targetWidth:$targetHeight:(ow-iw)/2:(oh-ih)/2',
    );

    for (final item in videoItems) {
      final eqParts = <String>[];
      if (item.brightness != 0.0) eqParts.add('brightness=${item.brightness.toStringAsFixed(2)}');
      if (item.contrast != 1.0) eqParts.add('contrast=${item.contrast.toStringAsFixed(2)}');
      if (item.saturation != 1.0) eqParts.add('saturation=${item.saturation.toStringAsFixed(2)}');

      if (eqParts.isNotEmpty) {
        filters.add('eq=${eqParts.join(":")}');
      }

      if (item.flipHorizontal) filters.add('hflip');
      if (item.flipVertical) filters.add('vflip');
      if (item.vignette > 0.0) filters.add('vignette=PI/${(item.vignette * 4).clamp(1.0, 16.0).toStringAsFixed(1)}');
    }

    for (final effect in effects) {
      switch (effect.type) {
        case EffectType.gaussianBlur:
          final sigma = (effect.intensity * 20).clamp(1.0, 30.0);
          filters.add('gblur=sigma=${sigma.toStringAsFixed(1)}');
          break;
        case EffectType.motionBlur:
          filters.add('tblend=all_mode=average');
          break;
        case EffectType.colorShift:
          filters.add('hue=h=90*sin(2*PI*t)');
          break;
        case EffectType.glitch:
          filters.add('rgbashift=rh=5:bv=-5');
          break;
        case EffectType.zoomBounce:
          filters.add("zoompan=z='min(zoom+0.0015,1.15)':d=125:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)'");
          break;
        default:
          break;
      }
    }

    return filters.join(',');
  }

  /// Build FFmpeg audio filter chain
  String buildAudioFilterChain(AudioSettingsModel settings) {
    if (!settings.isEnhanced) {
      return 'anull';
    }

    final filters = <String>[];

    if (settings.gainDb != 0.0) {
      filters.add('volume=${settings.gainDb.toStringAsFixed(1)}dB');
    }

    if (settings.bassGainDb != 0.0) {
      filters.add('equalizer=f=100:width_type=o:w=1:g=${settings.bassGainDb.toStringAsFixed(1)}');
    }
    if (settings.midGainDb != 0.0) {
      filters.add('equalizer=f=1000:width_type=q:w=1.2:g=${settings.midGainDb.toStringAsFixed(1)}');
    }
    if (settings.trebleGainDb != 0.0) {
      filters.add('equalizer=f=10000:width_type=o:w=1:g=${settings.trebleGainDb.toStringAsFixed(1)}');
    }

    if (settings.compressorEnabled) {
      filters.add(
        'acompressor=threshold=${settings.compressorThresholdDb.toStringAsFixed(1)}dB:ratio=${settings.compressorRatio.toStringAsFixed(1)}:attack=${settings.compressorAttackMs.toStringAsFixed(1)}:release=${settings.compressorReleaseMs.toStringAsFixed(1)}',
      );
    }

    if (settings.limiterEnabled) {
      filters.add('alimiter=limit=${settings.limiterCeilingDb.toStringAsFixed(1)}dB');
    }

    if (settings.normalizeLoudness) {
      filters.add('loudnorm=I=${settings.targetLufs.toStringAsFixed(1)}:TP=-1.0:LRA=7.0');
    }

    if (settings.stereoBalance != 0.0) {
      final leftVol = (1.0 - settings.stereoBalance).clamp(0.0, 1.0);
      final rightVol = (1.0 + settings.stereoBalance).clamp(0.0, 1.0);
      filters.add('pan=stereo|c0=${leftVol.toStringAsFixed(2)}*c0|c1=${rightVol.toStringAsFixed(2)}*c1');
    }

    return filters.isEmpty ? 'anull' : filters.join(',');
  }

  /// Execute export rendering pipeline
  Stream<double> renderExport({
    required String inputVideoPath,
    required String outputPath,
    required int width,
    required int height,
    required double fps,
    required int videoBitrateKbps,
    required int audioBitrateKbps,
    required List<TimelineItemModel> videoItems,
    required AudioSettingsModel audioSettings,
    required List<EffectModel> effects,
  }) async* {
    AppLogger.i('FFmpegService', 'Starting export to $outputPath ($width x $height @ ${fps}fps)');

    // Verify input file exists
    final inputFile = File(inputVideoPath);
    if (!await inputFile.exists()) {
      throw MediaValidationFailure('Input video file does not exist: $inputVideoPath');
    }

    // Ensure output directory exists
    await File(outputPath).parent.create(recursive: true);

    final videoFilter = buildVideoFilterChain(
      videoItems: videoItems,
      effects: effects,
      targetWidth: width,
      targetHeight: height,
    );
    final audioFilter = buildAudioFilterChain(audioSettings);

    // Build FFmpeg command
    final command = '-y -i "$inputVideoPath" -vf "$videoFilter" -af "$audioFilter" '
        '-c:v libx264 -preset fast -b:v ${videoBitrateKbps}k '
        '-c:a aac -b:a ${audioBitrateKbps}k '
        '-r $fps -movflags +faststart "$outputPath"';

    if (_isFFmpegKitAvailable && Platform.isAndroid) {
      // Android: use FFmpegKit
      final probe = await probeMedia(inputVideoPath);
      yield* FFmpegKitService().executeWithProgress(
        command,
        totalDurationSecs: probe.duration,
      );
    } else if (_isDesktopFFmpegAvailable && _ffmpegPath != null) {
      // Desktop: use dart:io Process
      yield* _renderWithDesktopProcess(inputVideoPath, outputPath, videoFilter, audioFilter,
          width, height, fps, videoBitrateKbps, audioBitrateKbps);
    } else {
      // Fallback: copy source file directly (no re-encoding, preserves original)
      yield* _renderWithFileCopy(inputVideoPath, outputPath);
    }
  }

  Stream<double> _renderWithDesktopProcess(
    String inputPath,
    String outputPath,
    String videoFilter,
    String audioFilter,
    int width,
    int height,
    double fps,
    int videoBitrateKbps,
    int audioBitrateKbps,
  ) async* {
    final args = [
      '-y',
      '-i', inputPath,
      '-vf', videoFilter,
      '-af', audioFilter,
      '-c:v', 'libx264',
      '-preset', 'fast',
      '-b:v', '${videoBitrateKbps}k',
      '-c:a', 'aac',
      '-b:a', '${audioBitrateKbps}k',
      '-r', fps.toString(),
      '-movflags', '+faststart',
      outputPath,
    ];

    AppLogger.i('FFmpegService', 'Executing: $_ffmpegPath ${args.join(" ")}');

    final process = await Process.start(_ffmpegPath!, args);

    process.stderr.transform(utf8.decoder).listen((chunk) {
      AppLogger.d('FFmpegStderr', chunk);
    });

    // Emit intermediate progress
    int ticks = 0;
    final exitFuture = process.exitCode;
    while (true) {
      final result = await Future.any([
        exitFuture.then((_) => true),
        Future.delayed(const Duration(milliseconds: 500)).then((_) => false),
      ]);

      if (result) break;
      ticks++;
      yield (ticks * 0.05).clamp(0.0, 0.95);
    }

    final exitCode = await exitFuture;
    if (exitCode != 0) {
      throw FFmpegExecutionFailure('FFmpeg process failed with exit code $exitCode', exitCode: exitCode);
    }
    yield 1.0;
  }

  /// Fallback: copy source video file to output location
  Stream<double> _renderWithFileCopy(String inputPath, String outputPath) async* {
    AppLogger.i('FFmpegService', 'Using file-copy export (no FFmpeg available, preserving original format)');

    final inputFile = File(inputPath);
    final outputFile = File(outputPath);

    await outputFile.parent.create(recursive: true);

    final inputSize = await inputFile.length();
    final inputStream = inputFile.openRead();
    final outputSink = outputFile.openWrite();

    int bytesWritten = 0;

    await for (final chunk in inputStream) {
      outputSink.add(chunk);
      bytesWritten += chunk.length;
      if (inputSize > 0) {
        yield (bytesWritten / inputSize).clamp(0.0, 0.99);
      }
    }

    await outputSink.flush();
    await outputSink.close();

    if (await outputFile.exists() && await outputFile.length() > 0) {
      AppLogger.i('FFmpegService', 'File-copy export complete: $outputPath (${await outputFile.length()} bytes)');
      yield 1.0;
    } else {
      throw FFmpegExecutionFailure('File copy export produced empty output');
    }
  }
}
