import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/id_generator.dart';
import '../../../models/keyframe_model.dart';
import '../../../models/layer_model.dart';
import '../../../providers/project_provider.dart';
import '../../../providers/timeline_provider.dart';

class KeyframeEditorPanel extends ConsumerWidget {
  const KeyframeEditorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLayerId = ref.watch(timelineUiProvider.select((s) => s.selectedLayerId));
    final playheadMs = ref.watch(timelineUiProvider.select((s) => s.playheadMs));

    if (selectedLayerId == null) {
      return const Center(
        child: Text('Select a layer to edit keyframes', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final layer = ref.watch(projectProvider.select((p) =>
        p.layers.firstWhere((l) => l.id == selectedLayerId, orElse: () => LayerModel(id: '', name: '', type: LayerType.video))));

    if (layer.id.isEmpty) {
      return const Center(
        child: Text('Layer not found', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surfaceLight,
          child: Row(
            children: [
              Text(
                'Keyframes: ${layer.name}',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                'At ${playheadMs}ms',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        // Property list
        Expanded(
          child: ListView(
            children: [
              for (final property in KeyframeProperty.values)
                _PropertyRow(
                  property: property,
                  layer: layer,
                  playheadMs: playheadMs,
                  onAddKeyframe: (value) {
                    final keyframe = Keyframe(
                      id: IdGenerator.next(),
                      timeMs: playheadMs,
                      value: value,
                    );
                    ref.read(projectProvider.notifier).addKeyframe(selectedLayerId, property, keyframe);
                  },
                  onUpdateKeyframe: (keyframeId, value) {
                    final keyframe = Keyframe(
                      id: keyframeId,
                      timeMs: playheadMs,
                      value: value,
                    );
                    ref.read(projectProvider.notifier).addKeyframe(selectedLayerId, property, keyframe);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PropertyRow extends StatelessWidget {
  final KeyframeProperty property;
  final LayerModel layer;
  final int playheadMs;
  final ValueChanged<double> onAddKeyframe;
  final void Function(String keyframeId, double value) onUpdateKeyframe;

  const _PropertyRow({
    required this.property,
    required this.layer,
    required this.playheadMs,
    required this.onAddKeyframe,
    required this.onUpdateKeyframe,
  });

  @override
  Widget build(BuildContext context) {
    final currentValue = layer.valueAt(property, playheadMs);
    final track = layer.keyframeTracks[property] ?? [];
    final hasKeyframe = track.any((k) => (k.timeMs - playheadMs).abs() < 50);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              property.name,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          Expanded(
            child: Slider(
              value: _normalizeValue(currentValue),
              min: _minValue(),
              max: _maxValue(),
              onChanged: (v) {
                final denorm = _denormalizeValue(v);
                if (hasKeyframe) {
                  final keyframe = track.firstWhere((k) => (k.timeMs - playheadMs).abs() < 50);
                  onUpdateKeyframe(keyframe.id, denorm);
                }
              },
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              currentValue.toStringAsFixed(2),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
          IconButton(
            icon: Icon(
              hasKeyframe ? Icons.circle : Icons.circle_outlined,
              size: 16,
              color: hasKeyframe ? AppColors.keyframe : AppColors.textSecondary,
            ),
            onPressed: () {
              if (!hasKeyframe) {
                onAddKeyframe(currentValue);
              }
            },
          ),
        ],
      ),
    );
  }

  double _normalizeValue(double v) {
    switch (property) {
      case KeyframeProperty.opacity:
        return v.clamp(0.0, 1.0);
      case KeyframeProperty.scale:
        return v.clamp(0.1, 5.0);
      case KeyframeProperty.rotation:
        return ((v % 360) + 360) % 360;
      case KeyframeProperty.positionX:
      case KeyframeProperty.positionY:
        return v.clamp(-1000.0, 1000.0);
      default:
        return v;
    }
  }

  double _denormalizeValue(double v) => v;

  double _minValue() {
    switch (property) {
      case KeyframeProperty.opacity:
        return 0.0;
      case KeyframeProperty.scale:
        return 0.1;
      case KeyframeProperty.rotation:
        return -360.0;
      default:
        return -500.0;
    }
  }

  double _maxValue() {
    switch (property) {
      case KeyframeProperty.opacity:
        return 1.0;
      case KeyframeProperty.scale:
        return 5.0;
      case KeyframeProperty.rotation:
        return 360.0;
      default:
        return 500.0;
    }
  }
}
