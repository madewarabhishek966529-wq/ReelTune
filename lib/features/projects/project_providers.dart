import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:reeltune/data/models/project_model.dart';
import 'package:reeltune/data/repositories/project_repository.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository();
});

class ProjectListNotifier extends StateNotifier<AsyncValue<List<ProjectModel>>> {
  final ProjectRepository _repo;

  ProjectListNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    state = const AsyncValue.loading();
    try {
      final projects = await _repo.getAllProjects();
      if (!mounted) return;
      state = AsyncValue.data(projects);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<ProjectModel> createNewProject({
    required String name,
    String description = '',
    int width = 1080,
    int height = 1920,
    double fps = 30.0,
  }) async {
    final project = ProjectModel(
      name: name,
      description: description,
      width: width,
      height: height,
      fps: fps,
    );
    await _repo.createProject(project);
    await loadProjects();
    return project;
  }

  Future<void> deleteProject(String id) async {
    await _repo.deleteProject(id);
    await loadProjects();
  }
}

final projectListProvider = StateNotifierProvider<ProjectListNotifier, AsyncValue<List<ProjectModel>>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return ProjectListNotifier(repo);
});
