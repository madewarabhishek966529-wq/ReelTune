import 'package:reeltune/core/errors/failures.dart';
import 'package:reeltune/core/logging/app_logger.dart';
import 'package:reeltune/data/database/database_service.dart';
import 'package:reeltune/data/models/media_file_model.dart';

class MediaRepository {
  final DatabaseService _dbService;
  MediaRepository([DatabaseService? dbService]) : _dbService = dbService ?? DatabaseService();

  Future<List<MediaFileModel>> getMediaForProject(String projectId) async {
    try {
      final rows = await _dbService.db.query(
        'media_files',
        where: 'project_id = ?',
        whereArgs: [projectId],
        orderBy: 'imported_at ASC',
      );
      return rows.map((r) => MediaFileModel.fromMap(r)).toList();
    } catch (e, st) {
      AppLogger.e('MediaRepository', 'Failed to get media for project $projectId', e, st);
      throw DatabaseFailure('Failed to fetch media files: $e');
    }
  }

  Future<MediaFileModel?> getMediaById(String id) async {
    try {
      final rows = await _dbService.db.query('media_files', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) return null;
      return MediaFileModel.fromMap(rows.first);
    } catch (e, st) {
      AppLogger.e('MediaRepository', 'Failed to get media $id', e, st);
      throw DatabaseFailure('Failed to fetch media file: $e');
    }
  }

  Future<void> addMediaFile(MediaFileModel media) async {
    try {
      await _dbService.db.insert('media_files', media.toMap());
      AppLogger.i('MediaRepository', 'Added media: ${media.filename} (${media.id})');
    } catch (e, st) {
      AppLogger.e('MediaRepository', 'Failed to add media file', e, st);
      throw DatabaseFailure('Failed to insert media file: $e');
    }
  }

  Future<void> updateMediaFile(MediaFileModel media) async {
    try {
      await _dbService.db.update(
        'media_files',
        media.toMap(),
        where: 'id = ?',
        whereArgs: [media.id],
      );
    } catch (e, st) {
      AppLogger.e('MediaRepository', 'Failed to update media file', e, st);
      throw DatabaseFailure('Failed to update media file: $e');
    }
  }

  Future<void> deleteMediaFile(String id) async {
    try {
      await _dbService.db.delete('media_files', where: 'id = ?', whereArgs: [id]);
      AppLogger.i('MediaRepository', 'Deleted media file reference $id');
    } catch (e, st) {
      AppLogger.e('MediaRepository', 'Failed to delete media file', e, st);
      throw DatabaseFailure('Failed to delete media file: $e');
    }
  }
}
