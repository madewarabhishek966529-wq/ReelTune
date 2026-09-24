import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reeltune/app/app.dart';
import 'package:reeltune/core/logging/app_logger.dart';
import 'package:reeltune/core/services/ffmpeg_service.dart';
import 'package:reeltune/core/services/workspace_service.dart';
import 'package:reeltune/data/database/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.i('Main', 'Starting ReelTune Studio...');

  try {
    // 1. Initialize workspace directories
    await WorkspaceService().init();

    // 2. Initialize cross-platform SQLite database
    await DatabaseService().init();

    // 3. Probe FFmpeg binary availability
    await FFmpegService().checkAvailability();

    AppLogger.i('Main', 'ReelTune core services initialized successfully.');
  } catch (e, st) {
    AppLogger.e('Main', 'Error initializing ReelTune services', e, st);
  }

  runApp(
    const ProviderScope(
      child: ReelTuneApp(),
    ),
  );
}
