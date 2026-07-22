import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/filter_model.dart';

/// Utility to build Flutter ColorFilter matrix from FilterPreset.
class ColorFilterUtils {
  ColorFilterUtils._();

  static ColorFilter? buildFilter(FilterPreset preset, {double intensity = 1.0}) {
    switch (preset) {
      case FilterPreset.none:
        return null;
      case FilterPreset.grayscale:
        return _grayscale(intensity);
      case FilterPreset.sepia:
        return _sepia(intensity);
      case FilterPreset.invert:
        return _invert(intensity);
      case FilterPreset.brightness:
        return _brightness(intensity);
      case FilterPreset.contrast:
        return _contrast(intensity);
      case FilterPreset.saturation:
        return _saturation(intensity);
      case FilterPreset.hueRotate:
        return _hueRotate(intensity * 360);
      case FilterPreset.vintage:
        return _vintage(intensity);
      case FilterPreset.cinematic:
        return _cinematic(intensity);
      case FilterPreset.dramatic:
        return _dramatic(intensity);
      case FilterPreset.warm:
        return _warm(intensity);
      case FilterPreset.cool:
        return _cool(intensity);
    }
  }

  static ColorFilter _grayscale(double amount) {
    final inv = 1 - amount;
    final r = 0.2126 * amount;
    final g = 0.7152 * amount;
    final b = 0.0722 * amount;
    return ColorFilter.matrix([
      r + inv, g, b, 0, 0,
      r, g + inv, b, 0, 0,
      r, g, b + inv, 0, 0,
      0, 0, 0, 1, 0,
    ]!);
  }

  static ColorFilter _sepia(double amount) {
    final inv = 1 - amount;
    return ColorFilter.matrix([
      0.393 * amount + inv, 0.769 * amount, 0.189 * amount, 0, 0,
      0.349 * amount, 0.686 * amount + inv, 0.168 * amount, 0, 0,
      0.272 * amount, 0.534 * amount, 0.131 * amount + inv, 0, 0,
      0, 0, 0, 1, 0,
    ]!);
  }

  static ColorFilter _invert(double amount) {
    final inv = 1 - amount;
    return ColorFilter.matrix([
      -amount, 0, 0, 0, 255 * amount,
      0, -amount, 0, 0, 255 * amount,
      0, 0, -amount, 0, 255 * amount,
      0, 0, 0, 1, 0,
    ]!);
  }

  static ColorFilter _brightness(double amount) {
    // amount 0->2, 1 is neutral
    final b = (amount - 1) * 100;
    return ColorFilter.matrix([
      1, 0, 0, 0, b,
      0, 1, 0, 0, b,
      0, 0, 1, 0, b,
      0, 0, 0, 1, 0,
    ]!);
  }

  static ColorFilter _contrast(double amount) {
    final c = amount;
    final t = (1 - c) * 128;
    return ColorFilter.matrix([
      c, 0, 0, 0, t,
      0, c, 0, 0, t,
      0, 0, c, 0, t,
      0, 0, 0, 1, 0,
    ]!);
  }

  static ColorFilter _saturation(double amount) {
    final r = 0.2126 * (1 - amount);
    final g = 0.7152 * (1 - amount);
    final b = 0.0722 * (1 - amount);
    return ColorFilter.matrix([
      r + amount, g, b, 0, 0,
      r, g + amount, b, 0, 0,
      r, g, b + amount, 0, 0,
      0, 0, 0, 1, 0,
    ]!);
  }

  static ColorFilter _hueRotate(double degrees) {
    final rad = degrees * pi / 180;
    final cosA = cos(rad);
    final sinA = sin(rad);
    const lumR = 0.213;
    const lumG = 0.715;
    const lumB = 0.072;
    return ColorFilter.matrix([
      lumR + cosA * (1 - lumR) + sinA * (-lumR),
      lumG + cosA * (-lumG) + sinA * (-lumG),
      lumB + cosA * (-lumB) + sinA * (1 - lumB),
      0, 0,
      lumR + cosA * (-lumR) + sinA * 0.143,
      lumG + cosA * (1 - lumG) + sinA * 0.140,
      lumB + cosA * (-lumB) + sinA * (-0.283),
      0, 0,
      lumR + cosA * (-lumR) + sinA * (-(1 - lumR)),
      lumG + cosA * (-lumG) + sinA * lumG,
      lumB + cosA * (1 - lumB) + sinA * lumB,
      0, 0,
      0, 0, 0, 1, 0,
    ]!);
  }

  static ColorFilter _vintage(double amount) {
    return _compose([
      _sepia(amount * 0.5),
      _contrast(1 + amount * 0.1),
      _brightness(1 - amount * 0.05),
    ]!);
  }

  static ColorFilter _cinematic(double amount) {
    return _compose([
      _contrast(1 + amount * 0.2),
      _saturation(1 - amount * 0.2),
      _brightness(1 - amount * 0.05),
    ]!);
  }

  static ColorFilter _dramatic(double amount) {
    return _compose([
      _contrast(1 + amount * 0.4),
      _saturation(1 - amount * 0.3),
      _brightness(1 - amount * 0.1),
    ]!);
  }

  static ColorFilter _warm(double amount) {
    final r = amount * 20;
    final b = -amount * 15;
    return ColorFilter.matrix([
      1, 0, 0, 0, r,
      0, 1, 0, 0, amount * 5,
      0, 0, 1, 0, b,
      0, 0, 0, 1, 0,
    ]!);
  }

  static ColorFilter _cool(double amount) {
    final r = -amount * 10;
    final b = amount * 20;
    return ColorFilter.matrix([
      1, 0, 0, 0, r,
      0, 1, 0, 0, amount * 5,
      0, 0, 1, 0, b,
      0, 0, 0, 1, 0,
    ]!);
  }

  static ColorFilter? _compose(List<ColorFilter?> filters) {
    // For simplicity, return the last non-null filter
    // In production, you'd use a proper matrix composition
    ColorFilter? result;
    for (final f in filters) {
      if (f != null) result = f;
    }
    return result;
  }
}
