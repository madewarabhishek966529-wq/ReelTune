import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:reeltune/core/logging/app_logger.dart';
import 'package:reeltune/core/services/export_validation_service.dart';
import 'package:reeltune/core/services/ffmpeg_service.dart';
import 'package:reeltune/core/services/workspace_service.dart';
import 'package:reeltune/data/models/export_job_model.dart';
import 'package:reeltune/data/repositories/export_repository.dart';
import 'package:reeltune/features/editor/editor_state.dart';

final exportRepositoryProvider = Provider<ExportRepository>((ref) {
  return ExportRepository();
});

class ExportQueueState {
  final List<ExportJobModel> jobs;
  final bool isProcessing;
  final String? activeJobId;

  ExportQueueState({
    this.jobs = const [],
    this.isProcessing = false,
    this.activeJobId,
  });

  ExportQueueState copyWith({
    List<ExportJobModel>? jobs,
    bool? isProcessing,
    String? activeJobId,
  }) {
    return ExportQueueState(
      jobs: jobs ?? this.jobs,
      isProcessing: isProcessing ?? this.isProcessing,
      activeJobId: activeJobId ?? this.activeJobId,
    );
  }
}

class ExportNotifier extends StateNotifier<ExportQueueState> {
  final ExportRepository _exportRepo;
  final FFmpegService _ffmpegService;
  final ExportValidationService _validationService;
  final WorkspaceService _workspaceService;

  ExportNotifier({
    ExportRepository? exportRepo,
    FFmpegService? ffmpegService,
    ExportValidationService? validationService,
    WorkspaceService? workspaceService,
  })  : _exportRepo = exportRepo ?? ExportRepository(),
        _ffmpegService = ffmpegService ?? FFmpegService(),
        _validationService = validationService ?? ExportValidationService(),
        _workspaceService = workspaceService ?? WorkspaceService(),
        super(ExportQueueState()) {
    loadExports();
  }

  Future<void> loadExports() async {
    final jobs = await _exportRepo.getAllExports();
    state = state.copyWith(jobs: jobs);
  }

  Future<ExportJobModel> startExport({
    required EditorState editorState,
    required ExportPreset preset,
  }) async {
    final outputPath = _workspaceService.generateOutputPath(
      '${editorState.project.name}_${preset.name}',
      'mp4',
    );
    final filename = outputPath.split(Platform.pathSeparator).last;

    final job = ExportJobModel(
      projectId: editorState.project.id,
      projectName: editorState.project.name,
      outputFilename: filename,
      outputPath: outputPath,
      presetName: preset.name,
      status: ExportStatus.running,
      progress: 0.0,
      width: preset.width,
      height: preset.height,
      fps: preset.fps,
      videoBitrateKbps: preset.videoBitrateKbps,
      audioBitrateKbps: preset.audioBitrateKbps,
    );

    await _exportRepo.saveExport(job);
    state = state.copyWith(
      jobs: [job, ...state.jobs],
      isProcessing: true,
      activeJobId: job.id,
    );

    // Run export rendering outside UI thread asynchronously
    _executeExportPipeline(job, editorState);

    return job;
  }

  Future<void> _executeExportPipeline(ExportJobModel job, EditorState editorState) async {
    try {
      final inputPath = editorState.mediaFiles.isNotEmpty
          ? editorState.mediaFiles.first.originalPath
          : '${_workspaceService.testFixturesDir.path}/sample_short_9_16.mp4';

      AppLogger.i('ExportNotifier', 'Export pipeline running for job ${job.id}');

      final progressStream = _ffmpegService.renderExport(
        inputVideoPath: inputPath,
        outputPath: job.outputPath,
        width: job.width,
        height: job.height,
        fps: job.fps,
        videoBitrateKbps: job.videoBitrateKbps,
        audioBitrateKbps: job.audioBitrateKbps,
        videoItems: editorState.items,
        audioSettings: editorState.audioSettings,
        effects: editorState.effects,
      );

      await for (final progress in progressStream) {
        final updated = job.copyWith(progress: progress);
        _updateJobInState(updated);
      }

      // Output validation
      final validation = await _validationService.validateExport(
        job: job,
        sourceMediaFiles: editorState.mediaFiles,
      );

      final completedJob = job.copyWith(
        status: ExportStatus.completed,
        progress: 1.0,
        outputFileSize: validation.fileSize,
        outputDuration: validation.estimatedDuration,
        completedAt: DateTime.now(),
      );

      await _exportRepo.saveExport(completedJob);
      _updateJobInState(completedJob);

      // Clean temporary files on success
      await _workspaceService.cleanTempFiles();

      AppLogger.i('ExportNotifier', 'Export job completed successfully: ${job.outputFilename}');
    } catch (e, st) {
      AppLogger.e('ExportNotifier', 'Export pipeline failed', e, st);
      final failedJob = job.copyWith(
        status: ExportStatus.failed,
        errorReason: e.toString(),
        completedAt: DateTime.now(),
      );
      await _exportRepo.saveExport(failedJob);
      _updateJobInState(failedJob);
    } finally {
      state = state.copyWith(isProcessing: false, activeJobId: null);
    }
  }

  void _updateJobInState(ExportJobModel updatedJob) {
    state = state.copyWith(
      jobs: state.jobs.map((j) => j.id == updatedJob.id ? updatedJob : j).toList(),
    );
  }

  Future<void> retryExport(String jobId, EditorState editorState) async {
    final existing = state.jobs.firstWhere((j) => j.id == jobId);
    final preset = ExportPreset.allPresets.firstWhere(
      (p) => p.name == existing.presetName,
      orElse: () => ExportPreset.instagramReel,
    );
    await startExport(editorState: editorState, preset: preset);
  }

  Future<void> deleteExport(String jobId) async {
    await _exportRepo.deleteExport(jobId);
    state = state.copyWith(
      jobs: state.jobs.where((j) => j.id != jobId).toList(),
    );
  }
}

final exportProvider = StateNotifierProvider<ExportNotifier, ExportQueueState>((ref) {
  return ExportNotifier();
});
