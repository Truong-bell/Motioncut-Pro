import 'package:equatable/equatable.dart';

/// Velocity curve defines how speed changes over time for a clip or keyframe.
enum VelocityCurveType {
  constant,
  rampIn,
  rampOut,
  rampInOut,
  hold,
  reverse,
  pingPong,
  custom,
}

class VelocityPoint extends Equatable {
  final double time;
  final double speed;
  final double? easing;

  const VelocityPoint({required this.time, required this.speed, this.easing});

  VelocityPoint copyWith({double? time, double? speed, double? easing}) =>
      VelocityPoint(time: time ?? this.time, speed: speed ?? this.speed, easing: easing ?? this.easing);

  Map<String, dynamic> toJson() => {'time': time, 'speed': speed, 'easing': easing};
  factory VelocityPoint.fromJson(Map<String, dynamic> json) => VelocityPoint(
        time: (json['time'] as num).toDouble(),
        speed: (json['speed'] as num).toDouble(),
        easing: (json['easing'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [time, speed, easing];
}

class VelocityModel extends Equatable {
  final VelocityCurveType curveType;
  final double baseSpeed;
  final List<VelocityPoint> points;
  final int? freezeAtMs;
  final int? freezeDurationMs;

  const VelocityModel({
    this.curveType = VelocityCurveType.constant,
    this.baseSpeed = 1.0,
    this.points = const [],
    this.freezeAtMs,
    this.freezeDurationMs,
  });

  double speedAt(double t) {
    switch (curveType) {
      case VelocityCurveType.constant:
        return baseSpeed;
      case VelocityCurveType.rampIn:
        return baseSpeed * (t * t);
      case VelocityCurveType.rampOut:
        return baseSpeed * ((1 - t) * (1 - t));
      case VelocityCurveType.rampInOut:
        return baseSpeed * (t < 0.5 ? 2 * t * t : 1 - ((-2 * t + 2) * (-2 * t + 2)) / 2);
      case VelocityCurveType.hold:
        return 0.0;
      case VelocityCurveType.reverse:
        return -baseSpeed;
      case VelocityCurveType.pingPong:
        return baseSpeed;
      case VelocityCurveType.custom:
        return _interpolateCustom(t);
    }
  }

  double _interpolateCustom(double t) {
    if (points.isEmpty) return baseSpeed;
    if (t <= points.first.time) return points.first.speed * baseSpeed;
    if (t >= points.last.time) return points.last.speed * baseSpeed;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (t >= p1.time && t <= p2.time) {
        final segmentT = (t - p1.time) / (p2.time - p1.time);
        return baseSpeed * (p1.speed + (p2.speed - p1.speed) * segmentT);
      }
    }
    return baseSpeed;
  }

  int mapTime(int sourceMs, int clipDurationMs) {
    if (curveType == VelocityCurveType.constant && baseSpeed == 1.0) return sourceMs;
    if (curveType == VelocityCurveType.reverse) return clipDurationMs - sourceMs;
    final t = sourceMs / clipDurationMs;
    final speed = speedAt(t);
    return (sourceMs * speed).round().clamp(0, clipDurationMs);
  }

  VelocityModel copyWith({
    VelocityCurveType? curveType,
    double? baseSpeed,
    List<VelocityPoint>? points,
    int? freezeAtMs,
    int? freezeDurationMs,
  }) =>
      VelocityModel(
        curveType: curveType ?? this.curveType,
        baseSpeed: baseSpeed ?? this.baseSpeed,
        points: points ?? this.points,
        freezeAtMs: freezeAtMs ?? this.freezeAtMs,
        freezeDurationMs: freezeDurationMs ?? this.freezeDurationMs,
      );

  Map<String, dynamic> toJson() => {
        'curveType': curveType.name,
        'baseSpeed': baseSpeed,
        'points': points.map((p) => p.toJson()).toList(),
        'freezeAtMs': freezeAtMs,
        'freezeDurationMs': freezeDurationMs,
      };

  factory VelocityModel.fromJson(Map<String, dynamic> json) => VelocityModel(
        curveType: VelocityCurveType.values.byName(json['curveType'] as String? ?? 'constant'),
        baseSpeed: (json['baseSpeed'] as num?)?.toDouble() ?? 1.0,
        points: (json['points'] as List<dynamic>?)
                ?.map((p) => VelocityPoint.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        freezeAtMs: (json['freezeAtMs'] as num?)?.toInt(),
        freezeDurationMs: (json['freezeDurationMs'] as num?)?.toInt(),
      );

  @override
  List<Object?> get props => [curveType, baseSpeed, points, freezeAtMs, freezeDurationMs];
}
