import 'package:equatable/equatable.dart';
import 'clip_model.dart';
import 'effect_model.dart';
import 'filter_model.dart';
import 'keyframe_model.dart';
import 'vector_shape_model.dart';

enum LayerType { video, image, text, audio, sticker, adjustment, vector }

enum BlendMode { normal, multiply, screen, overlay, darken, lighten, add, subtract, difference }

enum MaskType { none, rectangle, ellipse, linear, custom }

class LayerModel extends Equatable {
  final String id;
  final String name;
  final LayerType type;
  final bool visible;
  final bool locked;
  final double baseOpacity;
  final BlendMode blendMode;
  final MaskType maskType;
  final List<ClipModel> clips;
  final Map<KeyframeProperty, KeyframeTrack> keyframeTracks;
  // NEW: effects, filters, vector shapes
  final List<EffectModel> effects;
  final List<FilterModel> filters;
  final List<VectorShapeModel> vectorShapes;

  const LayerModel({
    required this.id,
    required this.name,
    required this.type,
    this.visible = true,
    this.locked = false,
    this.baseOpacity = 1.0,
    this.blendMode = BlendMode.normal,
    this.maskType = MaskType.none,
    this.clips = const [],
    this.keyframeTracks = const {},
    this.effects = const [],
    this.filters = const [],
    this.vectorShapes = const [],
  });

  int get durationMs {
    if (clips.isEmpty) return 0;
    return clips.map((c) => c.timelineEndMs).reduce((a, b) => a > b ? a : b);
  }

  LayerModel copyWith({
    String? name,
    bool? visible,
    bool? locked,
    double? baseOpacity,
    BlendMode? blendMode,
    MaskType? maskType,
    List<ClipModel>? clips,
    Map<KeyframeProperty, KeyframeTrack>? keyframeTracks,
    List<EffectModel>? effects,
    List<FilterModel>? filters,
    List<VectorShapeModel>? vectorShapes,
  }) =>
      LayerModel(
        id: id,
        name: name ?? this.name,
        type: type,
        visible: visible ?? this.visible,
        locked: locked ?? this.locked,
        baseOpacity: baseOpacity ?? this.baseOpacity,
        blendMode: blendMode ?? this.blendMode,
        maskType: maskType ?? this.maskType,
        clips: clips ?? this.clips,
        keyframeTracks: keyframeTracks ?? this.keyframeTracks,
        effects: effects ?? this.effects,
        filters: filters ?? this.filters,
        vectorShapes: vectorShapes ?? this.vectorShapes,
      );

  LayerModel withKeyframe(KeyframeProperty property, Keyframe keyframe) {
    final current = List<Keyframe>.of(keyframeTracks[property] ?? const []);
    final existingIndex = current.indexWhere((k) => k.timeMs == keyframe.timeMs);
    if (existingIndex >= 0) {
      current[existingIndex] = keyframe;
    } else {
      current.add(keyframe);
      current.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    }
    final updated = Map<KeyframeProperty, KeyframeTrack>.of(keyframeTracks);
    updated[property] = current;
    return copyWith(keyframeTracks: updated);
  }

  LayerModel removeKeyframe(KeyframeProperty property, String keyframeId) {
    final current = keyframeTracks[property];
    if (current == null) return this;
    final updatedTrack = current.where((k) => k.id != keyframeId).toList();
    final updated = Map<KeyframeProperty, KeyframeTrack>.of(keyframeTracks);
    if (updatedTrack.isEmpty) {
      updated.remove(property);
    } else {
      updated[property] = updatedTrack;
    }
    return copyWith(keyframeTracks: updated);
  }

  double valueAt(KeyframeProperty property, int timeMs) {
    final fallback = switch (property) {
      KeyframeProperty.scale => 1.0,
      KeyframeProperty.opacity => baseOpacity,
      KeyframeProperty.positionX || KeyframeProperty.positionY => 0.0,
      KeyframeProperty.rotation => 0.0,
      KeyframeProperty.anchorX || KeyframeProperty.anchorY => 0.0,
      KeyframeProperty.skewX || KeyframeProperty.skewY => 0.0,
      KeyframeProperty.blur => 0.0,
      KeyframeProperty.brightness => 1.0,
      KeyframeProperty.contrast => 1.0,
      KeyframeProperty.saturation => 1.0,
    };
    final track = keyframeTracks[property];
    if (track == null || track.isEmpty) return fallback;
    return KeyframeInterpolator.valueAt(track, timeMs, fallback: fallback);
  }

  /// Get active effects at given time
  List<EffectModel> activeEffectsAt(int timeMs) =>
      effects.where((e) => e.isActiveAt(timeMs)).toList();

  /// Get active filters at given time
  List<FilterModel> activeFiltersAt(int timeMs) =>
      filters.where((f) => f.isActiveAt(timeMs)).toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'visible': visible,
        'locked': locked,
        'baseOpacity': baseOpacity,
        'blendMode': blendMode.name,
        'maskType': maskType.name,
        'clips': clips.map((c) => c.toJson()).toList(),
        'keyframeTracks': keyframeTracks.map((k, v) =>
            MapEntry(k.name, v.map((kf) => kf.toJson()).toList())),
        'effects': effects.map((e) => e.toJson()).toList(),
        'filters': filters.map((f) => f.toJson()).toList(),
        'vectorShapes': vectorShapes.map((v) => v.toJson()).toList(),
      };

  factory LayerModel.fromJson(Map<String, dynamic> json) => LayerModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Layer',
        type: LayerType.values.byName(json['type'] as String? ?? 'video'),
        visible: json['visible'] as bool? ?? true,
        locked: json['locked'] as bool? ?? false,
        baseOpacity: (json['baseOpacity'] as num?)?.toDouble() ?? 1.0,
        blendMode: BlendMode.values.byName(json['blendMode'] as String? ?? 'normal'),
        maskType: MaskType.values.byName(json['maskType'] as String? ?? 'none'),
        clips: (json['clips'] as List<dynamic>?)
                ?.map((c) => ClipModel.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        keyframeTracks: _parseKeyframeTracks(json['keyframeTracks']),
        effects: (json['effects'] as List<dynamic>?)
                ?.map((e) => EffectModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        filters: (json['filters'] as List<dynamic>?)
                ?.map((f) => FilterModel.fromJson(f as Map<String, dynamic>))
                .toList() ??
            [],
        vectorShapes: (json['vectorShapes'] as List<dynamic>?)
                ?.map((v) => VectorShapeModel.fromJson(v as Map<String, dynamic>))
                .toList() ??
            [],
      );

  static Map<KeyframeProperty, KeyframeTrack> _parseKeyframeTracks(dynamic raw) {
    if (raw is! Map<String, dynamic>) return {};
    final result = <KeyframeProperty, KeyframeTrack>{};
    raw.forEach((key, value) {
      try {
        final prop = KeyframeProperty.values.byName(key);
        final track = (value as List<dynamic>)
            .map((k) => Keyframe.fromJson(k as Map<String, dynamic>))
            .toList();
        result[prop] = track;
      } catch (_) {
        // Skip unknown properties
      }
    });
    return result;
  }

  @override
  List<Object?> get props => [
        id, name, type, visible, locked, baseOpacity,
        blendMode, maskType, clips, keyframeTracks,
        effects, filters, vectorShapes
      ];
}
