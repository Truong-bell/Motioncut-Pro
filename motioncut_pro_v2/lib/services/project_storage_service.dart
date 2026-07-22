import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/project_model.dart';

class ProjectStorageService {
  static const _projectsDir = 'motioncut_projects';

  Future<Directory> _getDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_projectsDir');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> saveProject(ProjectModel project) async {
    final dir = await _getDir();
    final file = File('${dir.path}/${project.id}.json');
    await file.writeAsString(jsonEncode(project.toJson()));
  }

  Future<ProjectModel?> loadProject(String id) async {
    final dir = await _getDir();
    final file = File('${dir.path}/$id.json');
    if (!await file.exists()) return null;
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return ProjectModel.fromJson(json);
  }

  Future<List<ProjectModel>> loadAllProjects() async {
    final dir = await _getDir();
    final files = await dir.list().where((f) => f.path.endsWith('.json')).toList();
    final projects = <ProjectModel>[];
    for (final file in files) {
      try {
        final content = await File(file.path).readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        projects.add(ProjectModel.fromJson(json));
      } catch (_) {
        // Skip corrupted files
      }
    }
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  Future<void> deleteProject(String id) async {
    final dir = await _getDir();
    final file = File('${dir.path}/$id.json');
    if (await file.exists()) await file.delete();
  }
}
