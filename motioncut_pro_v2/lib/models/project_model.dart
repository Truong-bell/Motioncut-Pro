import 'package:equatable/equatable.dart';
import '../core/utils/id_generator.dart';
import 'effect_model.dart';
import 'filter_model.dart';
import 'layer_model.dart';

enum ExportResolution {
  r720p(1280, 720),
  r1080p(1920, 1080),
  r4k(3840, 2160);

  final int width;
  final int height;
  const ExportResolution(this.width, this.height);
}

class ProjectModel extends Equatable {
  final String id;
  final String name;
  final int fps;
  final ExportResolution resolution;
  final List<LayerModel> layers;
  final List<int> audioBeatMapMs;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailPath;
  // NEW: global effects/filters
  final List<EffectModel> globalEffects;
  final List<FilterModel> globalFilters;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.fps,
    required this.resolution,
    required this.layers,
    required this.createdAt,
    required this.updatedAt,
    this.audioBeatMapMs = const [],
    this.thumbnailPath,
    this.globalEffects = const [],
    this.globalFilters = const [],
  });

  factory ProjectModel.empty({String name = 'Untitled Project'}) {
    final now = DateTime.now();
    return ProjectModel(
      id: IdGenerator.next(),
      name: name,
      fps: 30,
      resolution: ExportResolution.r1080p,
      layers: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  int get totalDurationMs {
    if (layers.isEmpty) return 0;
    return layers.map((l) => l.durationMs).reduce((a, b) => a > b ? a : b);
  }

  ProjectModel copyWith({
    String? name,
    int? fps,
    ExportResolution? resolution,
    List<LayerModel>? layers,
    List<int>? audioBeatMapMs,
    DateTime? updatedAt,
    String? thumbnailPath,
    List<EffectModel>? globalEffects,
    List<FilterModel>? globalFilters,
  }) =>
      ProjectModel(
        id: id,
        name: name ?? this.name,
        fps: fps ?? this.fps,
        resolution: resolution ?? this.resolution,
        layers: layers ?? this.layers,
        audioBeatMapMs: audioBeatMapMs ?? this.audioBeatMapMs,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
        globalEffects: globalEffects ?? this.globalEffects,
        globalFilters: globalFilters ?? this.globalFilters,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fps': fps,
        'resolution': resolution.name,
        'layers': layers.map((l) => l.toJson()).toList(),
        'audioBeatMapMs': audioBeatMapMs,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'thumbnailPath': thumbnailPath,
        'globalEffects': globalEffects.map((e) => e.toJson()).toList(),
        'globalFilters': globalFilters.map((f) => f.toJson()).toList(),
      };

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Untitled',
        fps: (json['fps'] as num?)?.toInt() ?? 30,
        resolution: _safeResolution(json['resolution']),
        layers: (json['layers'] as List<dynamic>?)
                ?.map((l) => LayerModel.fromJson(l as Map<String, dynamic>))
                .toList() ??
            [],
        audioBeatMapMs: (json['audioBeatMapMs'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            [],
        createdAt: _safeDate(json['createdAt']),
        updatedAt: _safeDate(json['updatedAt']),
        thumbnailPath: json['thumbnailPath'] as String?,
        globalEffects: (json['globalEffects'] as List<dynamic>?)
                ?.map((e) => EffectModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        globalFilters: (json['globalFilters'] as List<dynamic>?)
                ?.map((f) => FilterModel.fromJson(f as Map<String, dynamic>))
                .toList() ??
            [],
      );

  static ExportResolution _safeResolution(dynamic raw) {
    if (raw is! String) return ExportResolution.r1080p;
    try {
      return ExportResolution.values.byName(raw);
    } catch (_) {
      return ExportResolution.r1080p;
    }
  }

  static DateTime _safeDate(dynamic raw) {
    if (raw is String) {
      try {
        return DateTime.parse(raw);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  @override
  List<Object?> get props => [
        id, name, fps, resolution, layers,
        audioBeatMapMs, createdAt, updatedAt, thumbnailPath,
        globalEffects, globalFilters
      ];
}
