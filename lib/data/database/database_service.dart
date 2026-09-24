import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reeltune/core/logging/app_logger.dart';
import 'package:reeltune/core/services/workspace_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Database get db {
    if (_db == null) {
      throw StateError('DatabaseService not initialized. Call init() first.');
    }
    return _db!;
  }

  Future<void> init() async {
    if (_db != null) return;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = p.join(WorkspaceService().projectsDir.path, 'reeltune_master.db');
    AppLogger.i('DatabaseService', 'Opening database at $dbPath');

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    AppLogger.i('DatabaseService', 'Creating database tables...');

    // 1. projects table
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        duration REAL NOT NULL,
        width INTEGER NOT NULL,
        height INTEGER NOT NULL,
        fps REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        thumbnail_path TEXT,
        is_recovered INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. media_files table
    await db.execute('''
      CREATE TABLE media_files (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        original_path TEXT NOT NULL,
        filename TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        duration REAL NOT NULL,
        width INTEGER NOT NULL,
        height INTEGER NOT NULL,
        fps REAL NOT NULL,
        video_codec TEXT NOT NULL,
        audio_codec TEXT NOT NULL,
        sample_rate INTEGER NOT NULL,
        channels INTEGER NOT NULL,
        thumbnail_path TEXT,
        proxy_path TEXT,
        is_original_preserved INTEGER NOT NULL DEFAULT 1,
        imported_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');

    // 3. timeline_tracks table
    await db.execute('''
      CREATE TABLE timeline_tracks (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        track_type TEXT NOT NULL,
        track_index INTEGER NOT NULL,
        is_muted INTEGER NOT NULL DEFAULT 0,
        is_locked INTEGER NOT NULL DEFAULT 0,
        volume REAL NOT NULL DEFAULT 1.0,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');

    // 4. timeline_items table
    await db.execute('''
      CREATE TABLE timeline_items (
        id TEXT PRIMARY KEY,
        track_id TEXT NOT NULL,
        project_id TEXT NOT NULL,
        media_file_id TEXT,
        title TEXT NOT NULL,
        start_time REAL NOT NULL,
        duration REAL NOT NULL,
        source_start_time REAL NOT NULL DEFAULT 0.0,
        source_duration REAL NOT NULL,
        speed REAL NOT NULL DEFAULT 1.0,
        volume REAL NOT NULL DEFAULT 1.0,
        opacity REAL NOT NULL DEFAULT 1.0,
        z_index INTEGER NOT NULL DEFAULT 0,
        scale REAL NOT NULL DEFAULT 1.0,
        rotation REAL NOT NULL DEFAULT 0.0,
        flip_horizontal INTEGER NOT NULL DEFAULT 0,
        flip_vertical INTEGER NOT NULL DEFAULT 0,
        position_x REAL NOT NULL DEFAULT 0.0,
        position_y REAL NOT NULL DEFAULT 0.0,
        crop_preset TEXT NOT NULL DEFAULT 'original',
        brightness REAL NOT NULL DEFAULT 0.0,
        contrast REAL NOT NULL DEFAULT 1.0,
        saturation REAL NOT NULL DEFAULT 1.0,
        exposure REAL NOT NULL DEFAULT 0.0,
        temperature REAL NOT NULL DEFAULT 0.0,
        vignette REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY (track_id) REFERENCES timeline_tracks(id) ON DELETE CASCADE,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');

    // 5. audio_settings table
    await db.execute('''
      CREATE TABLE audio_settings (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL UNIQUE,
        is_enhanced INTEGER NOT NULL DEFAULT 0,
        gain_db REAL NOT NULL DEFAULT 0.0,
        bass_gain_db REAL NOT NULL DEFAULT 0.0,
        mid_gain_db REAL NOT NULL DEFAULT 0.0,
        treble_gain_db REAL NOT NULL DEFAULT 0.0,
        compressor_enabled INTEGER NOT NULL DEFAULT 1,
        compressor_threshold_db REAL NOT NULL DEFAULT -18.0,
        compressor_ratio REAL NOT NULL DEFAULT 3.0,
        compressor_attack_ms REAL NOT NULL DEFAULT 20.0,
        compressor_release_ms REAL NOT NULL DEFAULT 150.0,
        limiter_enabled INTEGER NOT NULL DEFAULT 1,
        limiter_ceiling_db REAL NOT NULL DEFAULT -1.0,
        normalize_loudness INTEGER NOT NULL DEFAULT 1,
        target_lufs REAL NOT NULL DEFAULT -14.0,
        stereo_balance REAL NOT NULL DEFAULT 0.0,
        fade_in_seconds REAL NOT NULL DEFAULT 0.0,
        fade_out_seconds REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');

    // 6. effects table
    await db.execute('''
      CREATE TABLE effects (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        timeline_item_id TEXT,
        effect_type TEXT NOT NULL,
        start_time REAL NOT NULL,
        duration REAL NOT NULL,
        intensity REAL NOT NULL DEFAULT 0.5,
        is_randomized INTEGER NOT NULL DEFAULT 0,
        seed INTEGER NOT NULL DEFAULT 42,
        beat_offset_seconds REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');

    // 7. captions table
    await db.execute('''
      CREATE TABLE captions (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        text TEXT NOT NULL,
        start_time REAL NOT NULL,
        duration REAL NOT NULL,
        font_name TEXT NOT NULL DEFAULT 'Roboto',
        font_size REAL NOT NULL DEFAULT 24.0,
        text_color TEXT NOT NULL DEFAULT '#FFFFFF',
        outline_color TEXT NOT NULL DEFAULT '#000000',
        background_color TEXT NOT NULL DEFAULT '#00000088',
        alignment TEXT NOT NULL DEFAULT 'center',
        position_y REAL NOT NULL DEFAULT 0.85,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');

    // 8. exports table
    await db.execute('''
      CREATE TABLE exports (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        project_name TEXT NOT NULL,
        output_filename TEXT NOT NULL,
        output_path TEXT NOT NULL,
        preset_name TEXT NOT NULL,
        status TEXT NOT NULL,
        progress REAL NOT NULL DEFAULT 0.0,
        width INTEGER NOT NULL,
        height INTEGER NOT NULL,
        fps REAL NOT NULL,
        video_bitrate_kbps INTEGER NOT NULL,
        audio_bitrate_kbps INTEGER NOT NULL,
        error_reason TEXT,
        output_file_size INTEGER,
        output_duration REAL,
        created_at TEXT NOT NULL,
        completed_at TEXT
      )
    ''');

    // 9. autosaves table
    await db.execute('''
      CREATE TABLE autosaves (
        project_id TEXT PRIMARY KEY,
        saved_at TEXT NOT NULL,
        project_data_json TEXT NOT NULL
      )
    ''');

    // 10. settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 11. test_runs table
    await db.execute('''
      CREATE TABLE test_runs (
        id TEXT PRIMARY KEY,
        test_name TEXT NOT NULL,
        test_suite TEXT NOT NULL,
        status TEXT NOT NULL,
        duration_ms INTEGER NOT NULL,
        message TEXT,
        diagnostic_log TEXT,
        timestamp TEXT NOT NULL
      )
    ''');

    AppLogger.i('DatabaseService', 'Database tables created successfully.');
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
