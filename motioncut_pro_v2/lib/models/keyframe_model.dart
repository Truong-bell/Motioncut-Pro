import 'package:equatable/equatable.dart';
import '../core/utils/easing_utils.dart';

enum KeyframeProperty {
  positionX,
  positionY,
  scale,
  rotation,
  opacity,
  anchorX,
  anchorY,
  // NEW: for advanced animation
  skewX,
  skewY,
  blur,
  brightness,
  contrast,
  saturation,
}

enum EasingType {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  // NEW advanced easings
  easeInCubic,
  easeOutCubic,
  easeInOutCubic,
  easeInQuart,
  easeOutQuart,
  easeInExpo,
  easeOutExpo,
  easeInBack,
  easeOutBack,
  easeOutElastic,
  easeOutBounce,
  spring,
}

class Keyframe extends Equatable {
  final String id;
  final int timeMs;
  final double value;
  final EasingType easing;
  final double? velocityIn;   // incoming velocity tangent (for bezier curves)
  final double? velocityOut;  // outgoing velocity tangent

  const Keyframe({
    required this.id,
    required this.timeMs,
    required this.value,
    this.easing = EasingType.linear,
    this.velocityIn,
    this.velocityOut,
  });

  Keyframe copyWith({
    String? id,
    int? timeMs,
    double? value,
    EasingType? easing,
    double? velocityIn,
    double? velocityOut,
  }) =>
      Keyframe(
        id: id ?? this.id,
        timeMs: timeMs ?? this.timeMs,
        value: value ?? this.value,
        easing: easing ?? this.easing,
        velocityIn: velocityIn ?? this.velocityIn,
        velocityOut: velocityOut ?? this.velocityOut,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timeMs': timeMs,
        'value': value,
        'easing': easing.name,
        'velocityIn': velocityIn,
        'velocityOut': velocityOut,
      };

  factory Keyframe.fromJson(Map<String, dynamic> json) => Keyframe(
        id: json['id'] as String? ?? '',
        timeMs: (json['timeMs'] as num?)?.toInt() ?? 0,
        value: (json['value'] as num?)?.toDouble() ?? 0.0,
        easing: _safeEasing(json['easing']),
        velocityIn: (json['velocityIn'] as num?)?.toDouble(),
        velocityOut: (json['velocityOut'] as num?)?.toDouble(),
      );

  static EasingType _safeEasing(dynamic raw) {
    if (raw is! String) return EasingType.linear;
    try {
      return EasingType.values.byName(raw);
    } catch (_) {
      return EasingType.linear;
    }
  }

  @override
  List<Object?> get props => [id, timeMs, value, easing, velocityIn, velocityOut];
}

typedef KeyframeTrack = List<Keyframe>;

class KeyframeInterpolator {
  KeyframeInterpolator._();

  static double valueAt(
    KeyframeTrack track,
    int timeMs, {
    required double fallback,
  }) {
    if (track.isEmpty) return fallback;
    if (track.length == 1) return track.first.value;

    if (timeMs <= track.first.timeMs) return track.first.value;
    if (timeMs >= track.last.timeMs) return track.last.value;

    int low = 0;
    int high = track.length - 1;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (track[mid].timeMs < timeMs) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    final k2 = track[low.clamp(0, track.length - 1)];
    final k1 = track[(low - 1).clamp(0, track.length - 1)];

    if (k1.timeMs == k2.timeMs) return k1.value;

    final t = (timeMs - k1.timeMs) / (k2.timeMs - k1.timeMs);

    // If both keyframes have velocity tangents, use cubic bezier interpolation
    if (k1.velocityOut != null && k2.velocityIn != null) {
      final cx1 = 0.5 + (k1.velocityOut! * 0.5);
      final cx2 = 0.5 + (k2.velocityIn! * 0.5);
      final easedT = EasingUtils.cubicBezier(t, cx1.clamp(0.0, 1.0), 0.0, cx2.clamp(0.0, 1.0), 1.0);
      return k1.value + (k2.value - k1.value) * easedT;
    }

    final easedT = EasingUtils.apply(t, k2.easing);
    return k1.value + (k2.value - k1.value) * easedT;
  }
}
