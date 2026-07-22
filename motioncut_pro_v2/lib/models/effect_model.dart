import 'package:equatable/equatable.dart';

enum EffectType {
  none,
  glow,
  innerGlow,
  dropShadow,
  innerShadow,
  blur,
  motionBlur,
  chromaticAberration,
  rgbShift,
  pixelate,
  vignette,
  noise,
  shake,
  pulse,
  flicker,
  glitch,
  wave,
  bulge,
  pinch,
}

class EffectModel extends Equatable {
  final String id;
  final EffectType type;
  final double intensity;
  final double radius;
  final int color;
  final OffsetModel offset;
  final double angle;
  final int? startTimeMs;
  final int? endTimeMs;
  final bool enabled;

  const EffectModel({
    required this.id,
    required this.type,
    this.intensity = 0.5,
    this.radius = 10.0,
    this.color = 0xFFFFFFFF,
    this.offset = const OffsetModel(0, 0),
    this.angle = 0.0,
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

  EffectModel copyWith({
    EffectType? type,
    double? intensity,
    double? radius,
    int? color,
    OffsetModel? offset,
    double? angle,
    int? startTimeMs,
    int? endTimeMs,
    bool? enabled,
  }) =>
      EffectModel(
        id: id,
        type: type ?? this.type,
        intensity: intensity ?? this.intensity,
        radius: radius ?? this.radius,
        color: color ?? this.color,
        offset: offset ?? this.offset,
        angle: angle ?? this.angle,
        startTimeMs: startTimeMs ?? this.startTimeMs,
        endTimeMs: endTimeMs ?? this.endTimeMs,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'intensity': intensity,
        'radius': radius,
        'color': color,
        'offset': offset.toJson(),
        'angle': angle,
        'startTimeMs': startTimeMs,
        'endTimeMs': endTimeMs,
        'enabled': enabled,
      };

  factory EffectModel.fromJson(Map<String, dynamic> json) => EffectModel(
        id: json['id'] as String,
        type: EffectType.values.byName(json['type'] as String? ?? 'none'),
        intensity: (json['intensity'] as num?)?.toDouble() ?? 0.5,
        radius: (json['radius'] as num?)?.toDouble() ?? 10.0,
        color: (json['color'] as num?)?.toInt() ?? 0xFFFFFFFF,
        offset: json['offset'] != null
            ? OffsetModel.fromJson(json['offset'] as Map<String, dynamic>)
            : const OffsetModel(0, 0),
        angle: (json['angle'] as num?)?.toDouble() ?? 0.0,
        startTimeMs: (json['startTimeMs'] as num?)?.toInt(),
        endTimeMs: (json['endTimeMs'] as num?)?.toInt(),
        enabled: json['enabled'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id, type, intensity, radius, color, offset, angle, startTimeMs, endTimeMs, enabled];
}

class OffsetModel extends Equatable {
  final double dx;
  final double dy;
  const OffsetModel(this.dx, this.dy);

  Map<String, dynamic> toJson() => {'dx': dx, 'dy': dy};
  factory OffsetModel.fromJson(Map<String, dynamic> json) =>
      OffsetModel((json['dx'] as num).toDouble(), (json['dy'] as num).toDouble());

  @override
  List<Object?> get props => [dx, dy];
}
