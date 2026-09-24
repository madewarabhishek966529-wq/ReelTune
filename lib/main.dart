import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reeltune/app/app.dart';
import 'package:reeltune/core/logging/app_logger.dart';
import 'package:reeltune/core/services/ffmpeg_service.dart';
import 'package:reeltune/core/services/workspace_service.dart';
import 'package:reeltune/data/database/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for smooth UI
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style for a clean look
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0F1117),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

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

  // Request permissions post-frame on Android so the window is attached
  if (Platform.isAndroid) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }
}

/// Request necessary permissions on Android
Future<void> _requestPermissions() async {
  try {
    // For Android 13+ (API 33+), request granular media permissions
    if (await Permission.videos.isDenied) {
      await Permission.videos.request();
    }
    if (await Permission.audio.isDenied) {
      await Permission.audio.request();
    }
    if (await Permission.photos.isDenied) {
      await Permission.photos.request();
    }

    // For older Android versions, request storage permission
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
  } catch (e) {
    AppLogger.w('Main', 'Permission request error (non-fatal): $e');
  }
}
