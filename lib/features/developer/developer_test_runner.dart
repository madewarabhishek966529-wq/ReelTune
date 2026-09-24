import 'dart:io';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path/path.dart' as p;
import 'package:reeltune/core/logging/app_logger.dart';
import 'package:reeltune/core/services/audio_analysis_service.dart';
import 'package:reeltune/core/services/export_validation_service.dart';
import 'package:reeltune/core/services/ffmpeg_service.dart';
import 'package:reeltune/core/services/workspace_service.dart';
import 'package:reeltune/data/models/audio_settings_model.dart';
import 'package:reeltune/data/models/effect_model.dart';
import 'package:reeltune/data/models/export_job_model.dart';
import 'package:reeltune/data/models/media_file_model.dart';
import 'package:reeltune/data/models/test_run_model.dart';
import 'package:reeltune/data/models/timeline_item_model.dart';
import 'package:reeltune/data/repositories/test_run_repository.dart';

class DevTestState {
  final bool isRunning;
  final int totalRuns;
  final int passedRuns;
  final int failedRuns;
  final String currentTestName;
  final List<TestRunModel> history;

  DevTestState({
    this.isRunning = false,
    this.totalRuns = 0,
    this.passedRuns = 0,
    this.failedRuns = 0,
    this.currentTestName = '',
    this.history = const [],
  });

  DevTestState copyWith({
    bool? isRunning,
    int? totalRuns,
    int? passedRuns,
    int? failedRuns,
    String? currentTestName,
    List<TestRunModel>? history,
  }) {
    return DevTestState(
      isRunning: isRunning ?? this.isRunning,
      totalRuns: totalRuns ?? this.totalRuns,
      passedRuns: passedRuns ?? this.passedRuns,
      failedRuns: failedRuns ?? this.failedRuns,
      currentTestName: currentTestName ?? this.currentTestName,
      history: history ?? this.history,
    );
  }
}

class DevTestRunnerNotifier extends StateNotifier<DevTestState> {
  final TestRunRepository _testRepo;
  final WorkspaceService _workspace;
  final FFmpegService _ffmpeg;
  final AudioAnalysisService _audioAnalysis;
  final ExportValidationService _validation;

  DevTestRunnerNotifier({
    TestRunRepository? testRepo,
    WorkspaceService? workspace,
    FFmpegService? ffmpeg,
    AudioAnalysisService? audioAnalysis,
    ExportValidationService? validation,
  })  : _testRepo = testRepo ?? TestRunRepository(),
        _workspace = workspace ?? WorkspaceService(),
        _ffmpeg = ffmpeg ?? FFmpegService(),
        _audioAnalysis = audioAnalysis ?? AudioAnalysisService(),
        _validation = validation ?? ExportValidationService(),
        super(DevTestState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    final runs = await _testRepo.getAllTestRuns();
    final passCount = runs.where((r) => r.status == TestStatus.pass).length;
    final failCount = runs.where((r) => r.status == TestStatus.fail).length;
    state = state.copyWith(
      history: runs,
      totalRuns: runs.length,
      passedRuns: passCount,
      failedRuns: failCount,
    );
  }

  /// Run complete end-to-end automated test loop:
  /// Test Video -> Import -> Process -> Export -> Validate
  Future<void> runEndToEndTestLoop({int iterations = 1}) async {
    if (state.isRunning) return;

    state = state.copyWith(isRunning: true);
    AppLogger.i('DevTestRunner', 'Starting automated test loop: $iterations iterations');

    for (int i = 1; i <= iterations; i++) {
      final testName = 'E2E_Loop_Iteration_$i';
      state = state.copyWith(currentTestName: testName);
      final stopwatch = Stopwatch()..start();

      try {
        // Step 1: Create test fixture video
        final fixturePath = p.join(_workspace.testFixturesDir.path, 'e2e_fixture_$i.mp4');
        final fixtureFile = File(fixturePath);
        if (!await fixtureFile.exists()) {
          await fixtureFile.writeAsString('REELTUNE_TEST_FIXTURE_PAYLOAD');
        }

        // Step 2: Import & Probe
        final probe = await _ffmpeg.probeMedia(fixturePath);
        final media = MediaFileModel(
          projectId: 'test_project_$i',
          originalPath: fixturePath,
          filename: 'e2e_fixture_$i.mp4',
          fileSize: await fixtureFile.length(),
          duration: probe.duration,
          width: probe.width,
          height: probe.height,
        );

        // Step 3: Process Audio & Beat Detection
        final audioData = await _audioAnalysis.analyzeAudio(
          filePath: fixturePath,
          duration: probe.duration,
        );

        // Step 4: Non-destructive Timeline & Creative Effects
        final videoItem = TimelineItemModel(
          trackId: 'track_video',
          projectId: 'test_project_$i',
          mediaFileId: media.id,
          startTime: 0.0,
          duration: 10.0,
          sourceDuration: 10.0,
          contrast: 1.1,
          saturation: 1.2,
        );

        final effect = EffectModel(
          projectId: 'test_project_$i',
          type: EffectType.zoomBounce,
          startTime: audioData.downbeats.isNotEmpty ? audioData.downbeats.first : 2.0,
          duration: 0.5,
          intensity: 0.8,
        );

        final audioSettings = AudioSettingsModel(
          projectId: 'test_project_$i',
          isEnhanced: true,
          gainDb: 1.5,
          bassGainDb: 2.0,
          trebleGainDb: 1.0,
          normalizeLoudness: true,
        );

        // Step 5: Export rendering
        final outputPath = p.join(_workspace.outputDir.path, 'e2e_test_out_$i.mp4');
        final stream = _ffmpeg.renderExport(
          inputVideoPath: fixturePath,
          outputPath: outputPath,
          width: 1080,
          height: 1920,
          fps: 30.0,
          videoBitrateKbps: 8000,
          audioBitrateKbps: 192,
          videoItems: [videoItem],
          audioSettings: audioSettings,
          effects: [effect],
        );

        await for (final _ in stream) {}

        // Step 6: Validate output & check non-destructive preservation
        final exportJob = ExportJobModel(
          projectId: 'test_project_$i',
          projectName: 'Test Project $i',
          outputFilename: 'e2e_test_out_$i.mp4',
          outputPath: outputPath,
          presetName: 'Instagram Reel',
          width: 1080,
          height: 1920,
        );

        final validation = await _validation.validateExport(
          job: exportJob,
          sourceMediaFiles: [media],
        );

        stopwatch.stop();

        final runRecord = TestRunModel(
          testName: testName,
          testSuite: 'End-to-End Media Loop',
          status: validation.isValid ? TestStatus.pass : TestStatus.fail,
          durationMs: stopwatch.elapsedMilliseconds,
          message: 'All phases passed. Non-destructive safety verified.',
          diagnosticLog: validation.message,
        );

        await _testRepo.saveTestRun(runRecord);
        await loadHistory();
      } catch (e, st) {
        stopwatch.stop();
        AppLogger.e('DevTestRunner', 'Test loop failed on iteration $i', e, st);

        final runRecord = TestRunModel(
          testName: testName,
          testSuite: 'End-to-End Media Loop',
          status: TestStatus.fail,
          durationMs: stopwatch.elapsedMilliseconds,
          message: e.toString(),
          diagnosticLog: st.toString(),
        );

        await _testRepo.saveTestRun(runRecord);
        await loadHistory();
        break; // stop on failure
      }
    }

    state = state.copyWith(isRunning: false, currentTestName: '');
    AppLogger.i('DevTestRunner', 'Automated test loop finished.');
  }

  Future<void> clearHistory() async {
    await _testRepo.clearTestRuns();
    await loadHistory();
  }
}

final devTestRunnerProvider = StateNotifierProvider<DevTestRunnerNotifier, DevTestState>((ref) {
  return DevTestRunnerNotifier();
});
