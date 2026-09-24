import 'dart:convert';
import 'package:reeltune/core/errors/failures.dart';
import 'package:reeltune/core/logging/app_logger.dart';
import 'package:reeltune/data/database/database_service.dart';
import 'package:reeltune/data/models/project_model.dart';

class ProjectRepository {
  final DatabaseService _dbService;
  ProjectRepository([DatabaseService? dbService]) : _dbService = dbService ?? DatabaseService();

  Future<List<ProjectModel>> getAllProjects() async {
    try {
      final rows = await _dbService.db.query('projects', orderBy: 'updated_at DESC');
      return rows.map((r) => ProjectModel.fromMap(r)).toList();
    } catch (e, st) {
      AppLogger.e('ProjectRepository', 'Failed to get all projects', e, st);
      throw DatabaseFailure('Failed to fetch projects: $e');
    }
  }

  Future<ProjectModel?> getProjectById(String id) async {
    try {
      final rows = await _dbService.db.query('projects', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) return null;
      return ProjectModel.fromMap(rows.first);
    } catch (e, st) {
      AppLogger.e('ProjectRepository', 'Failed to get project $id', e, st);
      throw DatabaseFailure('Failed to fetch project: $e');
    }
  }

  Future<void> createProject(ProjectModel project) async {
    try {
      await _dbService.db.insert('projects', project.toMap());
      AppLogger.i('ProjectRepository', 'Created project: ${project.name} (${project.id})');
    } catch (e, st) {
      AppLogger.e('ProjectRepository', 'Failed to create project', e, st);
      throw DatabaseFailure('Failed to insert project: $e');
    }
  }

  Future<void> updateProject(ProjectModel project) async {
    try {
      await _dbService.db.update(
        'projects',
        project.toMap(),
        where: 'id = ?',
        whereArgs: [project.id],
      );
      AppLogger.i('ProjectRepository', 'Updated project: ${project.name} (${project.id})');
    } catch (e, st) {
      AppLogger.e('ProjectRepository', 'Failed to update project', e, st);
      throw DatabaseFailure('Failed to update project: $e');
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _dbService.db.delete('projects', where: 'id = ?', whereArgs: [id]);
      AppLogger.i('ProjectRepository', 'Deleted project $id');
    } catch (e, st) {
      AppLogger.e('ProjectRepository', 'Failed to delete project', e, st);
      throw DatabaseFailure('Failed to delete project: $e');
    }
  }

  // Autosave & Recovery
  Future<void> saveAutosave(String projectId, Map<String, dynamic> projectData) async {
    try {
      await _dbService.db.insert(
        'autosaves',
        {
          'project_id': projectId,
          'saved_at': DateTime.now().toIso8601String(),
          'project_data_json': jsonEncode(projectData),
        },
        conflictAlgorithm: null, // We can replace or insert
      );
    } catch (_) {
      await _dbService.db.rawInsert(
        'INSERT OR REPLACE INTO autosaves (project_id, saved_at, project_data_json) VALUES (?, ?, ?)',
        [projectId, DateTime.now().toIso8601String(), jsonEncode(projectData)],
      );
    }
  }

  Future<Map<String, dynamic>?> getAutosave(String projectId) async {
    try {
      final rows = await _dbService.db.query('autosaves', where: 'project_id = ?', whereArgs: [projectId]);
      if (rows.isEmpty) return null;
      return jsonDecode(rows.first['project_data_json'] as String) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearAutosave(String projectId) async {
    try {
      await _dbService.db.delete('autosaves', where: 'project_id = ?', whereArgs: [projectId]);
    } catch (_) {}
  }
}
