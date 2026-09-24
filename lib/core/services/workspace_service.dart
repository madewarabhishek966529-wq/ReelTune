import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:reeltune/app/constants.dart';
import 'package:reeltune/core/logging/app_logger.dart';

class WorkspaceService {
  static final WorkspaceService _instance = WorkspaceService._internal();
  factory WorkspaceService() => _instance;
  WorkspaceService._internal();

  Directory? _rootWorkspaceDir;

  Directory get rootDir {
    if (_rootWorkspaceDir == null) {
      throw StateError('WorkspaceService not initialized. Call init() first.');
    }
    return _rootWorkspaceDir!;
  }

  Directory get inputDir => Directory(p.join(rootDir.path, AppConstants.dirInput));
  Directory get projectsDir => Directory(p.join(rootDir.path, AppConstants.dirProjects));
  Directory get outputDir => Directory(p.join(rootDir.path, AppConstants.dirOutput));
  Directory get tempDir => Directory(p.join(rootDir.path, AppConstants.dirTemp));
  Directory get cacheDir => Directory(p.join(rootDir.path, AppConstants.dirCache));
  Directory get testFixturesDir => Directory(p.join(rootDir.path, AppConstants.dirTestFixtures));
  Directory get testResultsDir => Directory(p.join(rootDir.path, AppConstants.dirTestResults));
  Directory get testReportsDir => Directory(p.join(rootDir.path, AppConstants.dirTestReports));

  Future<void> init([String? customPath]) async {
    if (customPath != null && customPath.isNotEmpty) {
      _rootWorkspaceDir = Directory(customPath);
    } else if (Platform.isWindows) {
      // In Windows, use standard Documents/ReelTune or local project workspace
      final docDir = await getApplicationDocumentsDirectory();
      _rootWorkspaceDir = Directory(p.join(docDir.path, 'ReelTuneWorkspace'));
    } else {
      // Android / mobile
      final appDir = await getApplicationDocumentsDirectory();
      _rootWorkspaceDir = Directory(p.join(appDir.path, 'workspace'));
    }

    AppLogger.i('WorkspaceService', 'Initializing workspace at: ${_rootWorkspaceDir!.path}');

    // Create all required directories
    await inputDir.create(recursive: true);
    await projectsDir.create(recursive: true);
    await outputDir.create(recursive: true);
    await tempDir.create(recursive: true);
    await cacheDir.create(recursive: true);
    await testFixturesDir.create(recursive: true);
    await testResultsDir.create(recursive: true);
    await testReportsDir.create(recursive: true);

    // Create .gitkeep or dummy sample fixture if empty
    await _ensureTestFixtures();
  }

  /// Clean all temporary files (used after successful operations or user cleanup)
  Future<void> cleanTempFiles() async {
    try {
      if (await tempDir.exists()) {
        final entities = tempDir.listSync();
        for (final entity in entities) {
          try {
            await entity.delete(recursive: true);
          } catch (e) {
            AppLogger.w('WorkspaceService', 'Could not delete temp item: ${entity.path}');
          }
        }
      }
    } catch (e) {
      AppLogger.e('WorkspaceService', 'Error cleaning temp files', e);
    }
  }

  /// Clean cache files
  Future<void> cleanCache() async {
    try {
      if (await cacheDir.exists()) {
        final entities = cacheDir.listSync();
        for (final entity in entities) {
          try {
            await entity.delete(recursive: true);
          } catch (e) {
            AppLogger.w('WorkspaceService', 'Could not delete cache item: ${entity.path}');
          }
        }
      }
    } catch (e) {
      AppLogger.e('WorkspaceService', 'Error cleaning cache', e);
    }
  }

  /// Generate a unique, non-destructive output path in workspace/output/
  String generateOutputPath(String baseName, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedBase = baseName.replaceAll(RegExp(r'[^\w\-]'), '_');
    final filename = '${sanitizedBase}_$timestamp.$extension';
    return p.join(outputDir.path, filename);
  }

  /// Get storage stats (size in bytes)
  Future<Map<String, int>> getStorageStats() async {
    int inputSize = await _calcDirSize(inputDir);
    int outputSize = await _calcDirSize(outputDir);
    int cacheSize = await _calcDirSize(cacheDir);
    int tempSize = await _calcDirSize(tempDir);

    return {
      'input': inputSize,
      'output': outputSize,
      'cache': cacheSize,
      'temp': tempSize,
      'total': inputSize + outputSize + cacheSize + tempSize,
    };
  }

  Future<int> _calcDirSize(Directory dir) async {
    int total = 0;
    if (await dir.exists()) {
      try {
        await for (final file in dir.list(recursive: true, followLinks: false)) {
          if (file is File) {
            total += await file.length();
          }
        }
      } catch (_) {}
    }
    return total;
  }

  Future<void> _ensureTestFixtures() async {
    // Generate sample test fixture markers if needed
    final sampleVideo = File(p.join(testFixturesDir.path, 'sample_short_9_16.mp4'));
    if (!await sampleVideo.exists()) {
      await sampleVideo.writeAsString('REELTUNE_SAMPLE_VIDEO_FIXTURE');
    }
    final sampleAudio = File(p.join(testFixturesDir.path, 'sample_audio.wav'));
    if (!await sampleAudio.exists()) {
      await sampleAudio.writeAsString('REELTUNE_SAMPLE_AUDIO_FIXTURE');
    }
  }
}
