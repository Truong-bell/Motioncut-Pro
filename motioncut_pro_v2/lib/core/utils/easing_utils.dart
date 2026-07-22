import 'dart:math';
import '../../models/keyframe_model.dart';

/// Advanced easing curves with velocity control.
/// Supports: linear, easeIn/Out/InOut (quadratic), cubic, quartic,
/// exponential, elastic, bounce, back, and custom bezier.
class EasingUtils {
  EasingUtils._();

  static double apply(double t, EasingType easing) {
    final c = t.clamp(0.0, 1.0);
    switch (easing) {
      case EasingType.linear:
        return c;
      case EasingType.easeIn:
        return _easeInQuad(c);
      case EasingType.easeOut:
        return _easeOutQuad(c);
      case EasingType.easeInOut:
        return _easeInOutQuad(c);
      case EasingType.easeInCubic:
        return c * c * c;
      case EasingType.easeOutCubic:
        return 1 - pow(1 - c, 3).toDouble();
      case EasingType.easeInOutCubic:
        return c < 0.5 ? 4 * c * c * c : 1 - pow(-2 * c + 2, 3).toDouble() / 2;
      case EasingType.easeInQuart:
        return c * c * c * c;
      case EasingType.easeOutQuart:
        return 1 - pow(1 - c, 4).toDouble();
      case EasingType.easeInExpo:
        return c == 0 ? 0 : pow(2, 10 * (c - 1)).toDouble();
      case EasingType.easeOutExpo:
        return c == 1 ? 1 : 1 - pow(2, -10 * c).toDouble();
      case EasingType.easeInBack:
        const s = 1.70158;
        return c * c * ((s + 1) * c - s);
      case EasingType.easeOutBack:
        const s = 1.70158;
        final c1 = c - 1;
        return c1 * c1 * ((s + 1) * c1 + s) + 1;
      case EasingType.easeOutElastic:
        return _easeOutElastic(c);
      case EasingType.easeOutBounce:
        return _easeOutBounce(c);
      case EasingType.spring:
        return _spring(c);
    }
  }

  static double _easeInQuad(double t) => t * t;
  static double _easeOutQuad(double t) => 1 - (1 - t) * (1 - t);
  static double _easeInOutQuad(double t) =>
      t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2).toDouble() / 2;

  static double _easeOutElastic(double t) {
    const c4 = (2 * pi) / 3;
    if (t == 0) return 0;
    if (t == 1) return 1;
    return pow(2, -10 * t).toDouble() * sin((t * 10 - 0.75) * c4) + 1;
  }

  static double _easeOutBounce(double t) {
    const n1 = 7.5625;
    const d1 = 2.75;
    if (t < 1 / d1) {
      return n1 * t * t;
    } else if (t < 2 / d1) {
      return n1 * (t -= 1.5 / d1) * t + 0.75;
    } else if (t < 2.5 / d1) {
      return n1 * (t -= 2.25 / d1) * t + 0.9375;
    }
    return n1 * (t -= 2.625 / d1) * t + 0.984375;
  }

  static double _spring(double t) {
    // Critically damped spring approximation
    const damping = 0.8;
    const frequency = 3.0;
    return 1 - (exp(-damping * t) * cos(frequency * t));
  }

  /// Cubic bezier interpolation with control points (cx1, cy1, cx2, cy2)
  static double cubicBezier(double t, double cx1, double cy1, double cx2, double cy2) {
    // Newton-Raphson to solve for x given t, then evaluate y
    double x = t;
    for (int i = 0; i < 8; i++) {
      final x2 = x * x;
      final x3 = x2 * x;
      final fx = 3 * cx1 * x2 * (1 - x) + 3 * cx2 * x * (1 - x) * (1 - x) + x3 - t;
      if (fx.abs() < 1e-6) break;
      final dfx = 3 * cx1 * (2 * x * (1 - x) - x2) +
          3 * cx2 * ((1 - x) * (1 - x) - 2 * x * (1 - x)) +
          3 * x2;
      if (dfx.abs() < 1e-6) break;
      x -= fx / dfx;
    }
    x = x.clamp(0.0, 1.0);
    final x2 = x * x;
    final x3 = x2 * x;
    final omx = 1 - x;
    final omx2 = omx * omx;
    final omx3 = omx2 * omx;
    return 3 * cy1 * x2 * omx + 3 * cy2 * x * omx2 + x3;
  }
}
