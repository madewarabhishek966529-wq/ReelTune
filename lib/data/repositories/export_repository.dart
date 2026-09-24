import 'package:reeltune/core/errors/failures.dart';
import 'package:reeltune/core/logging/app_logger.dart';
import 'package:reeltune/data/database/database_service.dart';
import 'package:reeltune/data/models/export_job_model.dart';

class ExportRepository {
  final DatabaseService _dbService;
  ExportRepository([DatabaseService? dbService]) : _dbService = dbService ?? DatabaseService();

  Future<List<ExportJobModel>> getAllExports() async {
    try {
      final rows = await _dbService.db.query('exports', orderBy: 'created_at DESC');
      return rows.map((r) => ExportJobModel.fromMap(r)).toList();
    } catch (e, st) {
      AppLogger.e('ExportRepository', 'Failed to fetch exports', e, st);
      throw DatabaseFailure('Failed to fetch exports: $e');
    }
  }

  Future<ExportJobModel?> getExportById(String id) async {
    try {
      final rows = await _dbService.db.query('exports', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) return null;
      return ExportJobModel.fromMap(rows.first);
    } catch (e, st) {
      AppLogger.e('ExportRepository', 'Failed to fetch export $id', e, st);
      return null;
    }
  }

  Future<void> saveExport(ExportJobModel job) async {
    try {
      await _dbService.db.rawInsert(
        '''
        INSERT OR REPLACE INTO exports
        (id, project_id, project_name, output_filename, output_path, preset_name, status,
         progress, width, height, fps, video_bitrate_kbps, audio_bitrate_kbps, error_reason,
         output_file_size, output_duration, created_at, completed_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          job.id,
          job.projectId,
          job.projectName,
          job.outputFilename,
          job.outputPath,
          job.presetName,
          job.status.name,
          job.progress,
          job.width,
          job.height,
          job.fps,
          job.videoBitrateKbps,
          job.audioBitrateKbps,
          job.errorReason,
          job.outputFileSize,
          job.outputDuration,
          job.createdAt.toIso8601String(),
          job.completedAt?.toIso8601String(),
        ],
      );
    } catch (e, st) {
      AppLogger.e('ExportRepository', 'Failed to save export job', e, st);
      throw DatabaseFailure('Failed to save export job: $e');
    }
  }

  Future<void> deleteExport(String id) async {
    try {
      await _dbService.db.delete('exports', where: 'id = ?', whereArgs: [id]);
    } catch (_) {}
  }
}
