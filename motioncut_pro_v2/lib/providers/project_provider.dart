import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/id_generator.dart';
import '../core/utils/undo_redo_manager.dart';
import '../models/clip_model.dart';
import '../models/effect_model.dart';
import '../models/filter_model.dart';
import '../models/keyframe_model.dart';
import '../models/layer_model.dart';
import '../models/project_model.dart';
import '../models/vector_shape_model.dart';
import '../models/velocity_model.dart';
import 'undo_redo_provider.dart';

class _AddLayerCommand implements EditCommand {
  final ProjectNotifier _notifier;
  final LayerModel _layer;
  _AddLayerCommand(this._notifier, this._layer);
  @override String get label => 'Thêm Layer';
  @override void execute() => _notifier._addLayerDirect(_layer);
  @override void undo() => _notifier._removeLayerDirect(_layer.id);
}

class _RemoveLayerCommand implements EditCommand {
  final ProjectNotifier _notifier;
  final LayerModel _layer;
  final int _oldIndex;
  _RemoveLayerCommand(this._notifier, this._layer, this._oldIndex);
  @override String get label => 'Xóa Layer';
  @override void execute() => _notifier._removeLayerDirect(_layer.id);
  @override void undo() => _notifier._insertLayerDirect(_oldIndex, _layer);
}

class _MoveClipCommand implements EditCommand {
  final ProjectNotifier _notifier;
  final String _layerId;
  final String _clipId;
  final int _oldStart;
  final int _newStart;
  _MoveClipCommand(this._notifier, this._layerId, this._clipId, this._oldStart, this._newStart);
  @override String get label => 'Di chuyển Clip';
  @override void execute() => _notifier._moveClipDirect(_layerId, _clipId, _newStart);
  @override void undo() => _notifier._moveClipDirect(_layerId, _clipId, _oldStart);
}

class ProjectNotifier extends StateNotifier<ProjectModel> {
  final Ref _ref;
  ProjectNotifier(this._ref, ProjectModel initial) : super(initial);

  UndoRedoManager get _undo => _ref.read(undoRedoManagerProvider);

  void _addLayerDirect(LayerModel layer) {
    state = state.copyWith(layers: [...state.layers, layer]);
  }

  void _removeLayerDirect(String layerId) {
    state = state.copyWith(layers: state.layers.where((l) => l.id != layerId).toList());
  }

  void _insertLayerDirect(int index, LayerModel layer) {
    final list = List<LayerModel>.of(state.layers);
    list.insert(index, layer);
    state = state.copyWith(layers: list);
  }

  void _moveClipDirect(String layerId, String clipId, int startMs) {
    _updateLayerDirect(layerId, (l) {
      final clips = [for (final c in l.clips) if (c.id == clipId) c.copyWith(timelineStartMs: startMs) else c];
      return l.copyWith(clips: clips);
    });
  }

  void _updateLayerDirect(String layerId, LayerModel Function(LayerModel) update) {
    state = state.copyWith(layers: [for (final l in state.layers) if (l.id == layerId) update(l) else l]);
  }

  void addLayer(LayerModel layer) => _undo.execute(_AddLayerCommand(this, layer));
  void removeLayer(String layerId) {
    final index = state.layers.indexWhere((l) => l.id == layerId);
    if (index == -1) return;
    _undo.execute(_RemoveLayerCommand(this, state.layers[index], index));
  }

  void reorderLayer(int oldIndex, int newIndex) {
    final layers = List.of(state.layers);
    if (newIndex > oldIndex) newIndex -= 1;
    final layer = layers.removeAt(oldIndex);
    layers.insert(newIndex, layer);
    state = state.copyWith(layers: layers);
  }

  void toggleLayerVisibility(String layerId) => updateLayer(layerId, (l) => l.copyWith(visible: !l.visible));
  void toggleLayerLock(String layerId) => updateLayer(layerId, (l) => l.copyWith(locked: !l.locked));

  void addClipToLayer(String layerId, ClipModel clip) =>
      updateLayer(layerId, (l) => l.copyWith(clips: [...l.clips, clip]));

  void moveClip(String layerId, String clipId, int newStartMs) {
    final layer = state.layers.firstWhere((l) => l.id == layerId);
    final clip = layer.clips.firstWhere((c) => c.id == clipId);
    final oldStart = clip.timelineStartMs;
    if (oldStart == newStartMs) return;
    _undo.execute(_MoveClipCommand(this, layerId, clipId, oldStart, newStartMs));
  }

  void removeClip(String layerId, String clipId) =>
      updateLayer(layerId, (l) => l.copyWith(clips: l.clips.where((c) => c.id != clipId).toList()));

  void updateLayer(String layerId, LayerModel Function(LayerModel) update) {
    state = state.copyWith(layers: [for (final l in state.layers) if (l.id == layerId) update(l) else l]);
  }

  void updateClip(String layerId, String clipId, ClipModel Function(ClipModel) update) {
    updateLayer(layerId, (l) => l.copyWith(
      clips: [for (final c in l.clips) if (c.id == clipId) update(c) else c],
    ));
  }

  void splitClip(String layerId, String clipId, int atMs) {
    final layer = state.layers.firstWhere((l) => l.id == layerId);
    final clip = layer.clips.firstWhere((c) => c.id == clipId);
    final result = clip.split(atMs);
    if (result == null) return;
    final (left, right) = result;
    updateLayer(layerId, (l) => l.copyWith(
      clips: [...l.clips.where((c) => c.id != clipId), left, right],
    ));
  }

  void addKeyframe(String layerId, KeyframeProperty property, Keyframe keyframe) {
    updateLayer(layerId, (l) => l.withKeyframe(property, keyframe));
  }

  void removeKeyframe(String layerId, KeyframeProperty property, String keyframeId) {
    updateLayer(layerId, (l) => l.removeKeyframe(property, keyframeId));
  }

  // ==== EFFECTS ====
  void addEffect(String layerId, EffectModel effect) {
    updateLayer(layerId, (l) => l.copyWith(effects: [...l.effects, effect]));
  }

  void removeEffect(String layerId, String effectId) {
    updateLayer(layerId, (l) => l.copyWith(effects: l.effects.where((e) => e.id != effectId).toList()));
  }

  void updateEffect(String layerId, String effectId, EffectModel Function(EffectModel) update) {
    updateLayer(layerId, (l) => l.copyWith(
      effects: [for (final e in l.effects) if (e.id == effectId) update(e) else e],
    ));
  }

  // ==== FILTERS ====
  void addFilter(String layerId, FilterModel filter) {
    updateLayer(layerId, (l) => l.copyWith(filters: [...l.filters, filter]));
  }

  void removeFilter(String layerId, String filterId) {
    updateLayer(layerId, (l) => l.copyWith(filters: l.filters.where((f) => f.id != filterId).toList()));
  }

  void updateFilter(String layerId, String filterId, FilterModel Function(FilterModel) update) {
    updateLayer(layerId, (l) => l.copyWith(
      filters: [for (final f in l.filters) if (f.id == filterId) update(f) else f],
    ));
  }

  // ==== VECTOR SHAPES ====
  void addVectorShape(String layerId, VectorShapeModel shape) {
    updateLayer(layerId, (l) => l.copyWith(vectorShapes: [...l.vectorShapes, shape]));
  }

  void removeVectorShape(String layerId, String shapeId) {
    updateLayer(layerId, (l) => l.copyWith(vectorShapes: l.vectorShapes.where((s) => s.id != shapeId).toList()));
  }

  void updateVectorShape(String layerId, String shapeId, VectorShapeModel Function(VectorShapeModel) update) {
    updateLayer(layerId, (l) => l.copyWith(
      vectorShapes: [for (final s in l.vectorShapes) if (s.id == shapeId) update(s) else s],
    ));
  }

  // ==== VELOCITY ====
  void updateClipVelocity(String layerId, String clipId, VelocityModel velocity) {
    updateClip(layerId, clipId, (c) => c.copyWith(velocity: velocity));
  }

  void setProjectName(String name) => state = state.copyWith(name: name);
  void setFps(int fps) => state = state.copyWith(fps: fps);
  void setResolution(ExportResolution res) => state = state.copyWith(resolution: res);
}

final projectProvider = StateNotifierProvider<ProjectNotifier, ProjectModel>((ref) {
  return ProjectNotifier(ref, ProjectModel.empty());
});
