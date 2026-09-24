import 'package:reeltune/core/errors/failures.dart';
import 'package:reeltune/core/logging/app_logger.dart';
import 'package:reeltune/data/database/database_service.dart';
import 'package:reeltune/data/models/timeline_track_model.dart';
import 'package:reeltune/data/models/timeline_item_model.dart';
import 'package:reeltune/data/models/audio_settings_model.dart';
import 'package:reeltune/data/models/effect_model.dart';
import 'package:reeltune/data/models/caption_model.dart';

class TimelineRepository {
  final DatabaseService _dbService;
  TimelineRepository([DatabaseService? dbService]) : _dbService = dbService ?? DatabaseService();

  // Tracks
  Future<List<TimelineTrackModel>> getTracks(String projectId) async {
    try {
      final rows = await _dbService.db.query(
        'timeline_tracks',
        where: 'project_id = ?',
        whereArgs: [projectId],
        orderBy: 'track_index ASC',
      );
      return rows.map((r) => TimelineTrackModel.fromMap(r)).toList();
    } catch (e, st) {
      AppLogger.e('TimelineRepository', 'Failed to get tracks for $projectId', e, st);
      throw DatabaseFailure('Failed to fetch tracks: $e');
    }
  }

  Future<void> saveTrack(TimelineTrackModel track) async {
    try {
      await _dbService.db.rawInsert(
        '''
        INSERT OR REPLACE INTO timeline_tracks 
        (id, project_id, track_type, track_index, is_muted, is_locked, volume)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        [track.id, track.projectId, track.type.name, track.index, track.isMuted ? 1 : 0, track.isLocked ? 1 : 0, track.volume],
      );
    } catch (e, st) {
      AppLogger.e('TimelineRepository', 'Failed to save track', e, st);
      throw DatabaseFailure('Failed to save track: $e');
    }
  }

  // Items
  Future<List<TimelineItemModel>> getItems(String projectId) async {
    try {
      final rows = await _dbService.db.query(
        'timeline_items',
        where: 'project_id = ?',
        whereArgs: [projectId],
        orderBy: 'start_time ASC',
      );
      return rows.map((r) => TimelineItemModel.fromMap(r)).toList();
    } catch (e, st) {
      AppLogger.e('TimelineRepository', 'Failed to get items for $projectId', e, st);
      throw DatabaseFailure('Failed to fetch items: $e');
    }
  }

  Future<void> saveItem(TimelineItemModel item) async {
    try {
      await _dbService.db.rawInsert(
        '''
        INSERT OR REPLACE INTO timeline_items 
        (id, track_id, project_id, media_file_id, title, start_time, duration, 
         source_start_time, source_duration, speed, volume, opacity, z_index, 
         scale, rotation, flip_horizontal, flip_vertical, position_x, position_y, 
         crop_preset, brightness, contrast, saturation, exposure, temperature, vignette)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          item.id,
          item.trackId,
          item.projectId,
          item.mediaFileId,
          item.title,
          item.startTime,
          item.duration,
          item.sourceStartTime,
          item.sourceDuration,
          item.speed,
          item.volume,
          item.opacity,
          item.zIndex,
          item.scale,
          item.rotation,
          item.flipHorizontal ? 1 : 0,
          item.flipVertical ? 1 : 0,
          item.positionX,
          item.positionY,
          item.cropPreset,
          item.brightness,
          item.contrast,
          item.saturation,
          item.exposure,
          item.temperature,
          item.vignette,
        ],
      );
    } catch (e, st) {
      AppLogger.e('TimelineRepository', 'Failed to save item', e, st);
      throw DatabaseFailure('Failed to save item: $e');
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _dbService.db.delete('timeline_items', where: 'id = ?', whereArgs: [itemId]);
    } catch (e, st) {
      AppLogger.e('TimelineRepository', 'Failed to delete item', e, st);
      throw DatabaseFailure('Failed to delete item: $e');
    }
  }

  // Audio Settings
  Future<AudioSettingsModel> getAudioSettings(String projectId) async {
    try {
      final rows = await _dbService.db.query('audio_settings', where: 'project_id = ?', whereArgs: [projectId]);
      if (rows.isEmpty) {
        final initial = AudioSettingsModel(projectId: projectId);
        await saveAudioSettings(initial);
        return initial;
      }
      return AudioSettingsModel.fromMap(rows.first);
    } catch (e, st) {
      AppLogger.e('TimelineRepository', 'Failed to get audio settings', e, st);
      return AudioSettingsModel(projectId: projectId);
    }
  }

  Future<void> saveAudioSettings(AudioSettingsModel settings) async {
    try {
      await _dbService.db.rawInsert(
        '''
        INSERT OR REPLACE INTO audio_settings
        (id, project_id, is_enhanced, gain_db, bass_gain_db, mid_gain_db, treble_gain_db,
         compressor_enabled, compressor_threshold_db, compressor_ratio, compressor_attack_ms,
         compressor_release_ms, limiter_enabled, limiter_ceiling_db, normalize_loudness,
         target_lufs, stereo_balance, fade_in_seconds, fade_out_seconds)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          settings.id,
          settings.projectId,
          settings.isEnhanced ? 1 : 0,
          settings.gainDb,
          settings.bassGainDb,
          settings.midGainDb,
          settings.trebleGainDb,
          settings.compressorEnabled ? 1 : 0,
          settings.compressorThresholdDb,
          settings.compressorRatio,
          settings.compressorAttackMs,
          settings.compressorReleaseMs,
          settings.limiterEnabled ? 1 : 0,
          settings.limiterCeilingDb,
          settings.normalizeLoudness ? 1 : 0,
          settings.targetLufs,
          settings.stereoBalance,
          settings.fadeInSeconds,
          settings.fadeOutSeconds,
        ],
      );
    } catch (e, st) {
      AppLogger.e('TimelineRepository', 'Failed to save audio settings', e, st);
      throw DatabaseFailure('Failed to save audio settings: $e');
    }
  }

  // Effects
  Future<List<EffectModel>> getEffects(String projectId) async {
    try {
      final rows = await _dbService.db.query(
        'effects',
        where: 'project_id = ?',
        whereArgs: [projectId],
        orderBy: 'start_time ASC',
      );
      return rows.map((r) => EffectModel.fromMap(r)).toList();
    } catch (e, st) {
      AppLogger.e('TimelineRepository', 'Failed to get effects for $projectId', e, st);
      return [];
    }
  }

  Future<void> saveEffect(EffectModel effect) async {
    try {
      await _dbService.db.rawInsert(
        '''
        INSERT OR REPLACE INTO effects
        (id, project_id, timeline_item_id, effect_type, start_time, duration, intensity, is_randomized, seed, beat_offset_seconds)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          effect.id,
          effect.projectId,
          effect.timelineItemId,
          effect.type.name,
          effect.startTime,
          effect.duration,
          effect.intensity,
          effect.isRandomized ? 1 : 0,
          effect.seed,
          effect.beatOffsetSeconds,
        ],
      );
    } catch (e, st) {
      AppLogger.e('TimelineRepository', 'Failed to save effect', e, st);
    }
  }

  Future<void> deleteEffect(String effectId) async {
    try {
      await _dbService.db.delete('effects', where: 'id = ?', whereArgs: [effectId]);
    } catch (_) {}
  }

  // Captions
  Future<List<CaptionModel>> getCaptions(String projectId) async {
    try {
      final rows = await _dbService.db.query(
        'captions',
        where: 'project_id = ?',
        whereArgs: [projectId],
        orderBy: 'start_time ASC',
      );
      return rows.map((r) => CaptionModel.fromMap(r)).toList();
    } catch (e, st) {
      AppLogger.e('TimelineRepository', 'Failed to get captions for $projectId', e, st);
      return [];
    }
  }

  Future<void> saveCaption(CaptionModel caption) async {
    try {
      await _dbService.db.rawInsert(
        '''
        INSERT OR REPLACE INTO captions
        (id, project_id, text, start_time, duration, font_name, font_size, text_color, outline_color, background_color, alignment, position_y)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          caption.id,
          caption.projectId,
          caption.text,
          caption.startTime,
          caption.duration,
          caption.fontName,
          caption.fontSize,
          caption.textColorHex,
          caption.outlineColorHex,
          caption.backgroundColorHex,
          caption.alignment,
          caption.positionY,
        ],
      );
    } catch (e, st) {
      AppLogger.e('TimelineRepository', 'Failed to save caption', e, st);
    }
  }

  Future<void> deleteCaption(String captionId) async {
    try {
      await _dbService.db.delete('captions', where: 'id = ?', whereArgs: [captionId]);
    } catch (_) {}
  }
}
