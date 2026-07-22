import 'package:equatable/equatable.dart';

enum FilterPreset {
  none,
  grayscale,
  sepia,
  invert,
  brightness,
  contrast,
  saturation,
  hueRotate,
  vintage,
  cinematic,
  dramatic,
  warm,
  cool,
}

class FilterModel extends Equatable {
  final String id;
  final FilterPreset preset;
  final double intensity;
  final int? startTimeMs;
  final int? endTimeMs;
  final bool enabled;

  const FilterModel({
    required this.id,
    this.preset = FilterPreset.none,
    this.intensity = 1.0,
    this.startTimeMs,
    this.endTimeMs,
    this.enabled = true,
  });

  bool isActiveAt(int timeMs) {
    if (!enabled) return false;
    if (startTimeMs != null && timeMs < startTimeMs!) return false;
    if (endTimeMs != null && timeMs > endTimeMs!) return false;
    return true;
  }

  FilterModel copyWith({
    FilterPreset? preset,
    double? intensity,
    int? startTimeMs,
    int? endTimeMs,
    bool? enabled,
  }) =>
      FilterModel(
        id: id,
        preset: preset ?? this.preset,
        intensity: intensity ?? this.intensity,
        startTimeMs: startTimeMs ?? this.startTimeMs,
        endTimeMs: endTimeMs ?? this.endTimeMs,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'preset': preset.name,
        'intensity': intensity,
        'startTimeMs': startTimeMs,
        'endTimeMs': endTimeMs,
        'enabled': enabled,
      };

  factory FilterModel.fromJson(Map<String, dynamic> json) => FilterModel(
        id: json['id'] as String,
        preset: FilterPreset.values.byName(json['preset'] as String? ?? 'none'),
        intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
        startTimeMs: (json['startTimeMs'] as num?)?.toInt(),
        endTimeMs: (json['endTimeMs'] as num?)?.toInt(),
        enabled: json['enabled'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id, preset, intensity, startTimeMs, endTimeMs, enabled];
}
