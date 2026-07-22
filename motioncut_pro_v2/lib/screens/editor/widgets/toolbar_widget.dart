import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/id_generator.dart';
import '../../../models/effect_model.dart';
import '../../../models/filter_model.dart';
import '../../../models/layer_model.dart';
import '../../../models/vector_shape_model.dart';
import '../../../models/velocity_model.dart';
import '../../../providers/project_provider.dart';
import '../../../providers/timeline_provider.dart';

class ToolbarWidget extends ConsumerWidget {
  final VoidCallback onAddMedia;
  final VoidCallback onToggleKeyframe;
  final VoidCallback onToggleEffects;
  final VoidCallback onExport;

  const ToolbarWidget({
    super.key,
    required this.onAddMedia,
    required this.onToggleKeyframe,
    required this.onToggleEffects,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLayerId = ref.watch(timelineUiProvider.select((s) => s.selectedLayerId));
    final selectedClipId = ref.watch(timelineUiProvider.select((s) => s.selectedClipId));

    return Container(
      height: AppDimens.toolbarHeight + 8,
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            _buildToolButton(Icons.add_photo_alternate, 'Media', AppColors.primary, onAddMedia),
            _buildDivider(),
            _buildToolButton(Icons.animation, 'Keyframe', AppColors.keyframe, onToggleKeyframe),
            _buildDivider(),
            _buildToolButton(Icons.auto_fix_high, 'Effects', AppColors.effect, () => _showEffectsMenu(context, ref, selectedLayerId)),
            _buildToolButton(Icons.filter_b_and_w, 'Filter', AppColors.filter, () => _showFilterMenu(context, ref, selectedLayerId)),
            _buildToolButton(Icons.speed, 'Velocity', AppColors.velocity, () => _showVelocityDialog(context, ref, selectedLayerId, selectedClipId)),
            _buildToolButton(Icons.vibration, 'Shake', AppColors.shake, () => _addShakeEffect(context, ref, selectedLayerId)),
            _buildToolButton(Icons.shape_line, 'Vector', AppColors.vector, () => _showVectorMenu(context, ref, selectedLayerId)),
            _buildDivider(),
            _buildToolButton(Icons.text_fields, 'Text', AppColors.textPrimary, () {}),
            _buildToolButton(Icons.audiotrack, 'Audio', AppColors.textPrimary, () {}),
            _buildDivider(),
            _buildToolButton(Icons.share, 'Export', AppColors.accent, onExport),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: color, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.divider,
    );
  }

  void _showEffectsMenu(BuildContext context, WidgetRef ref, String? layerId) {
    if (layerId == null) {
      _showToast(context, 'Select a layer first');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Add Effect', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildEffectChip('Blur', EffectType.blur, layerId, ref),
                _buildEffectChip('Glow', EffectType.glow, layerId, ref),
                _buildEffectChip('Shadow', EffectType.dropShadow, layerId, ref),
                _buildEffectChip('Vignette', EffectType.vignette, layerId, ref),
                _buildEffectChip('Pixelate', EffectType.pixelate, layerId, ref),
                _buildEffectChip('RGB Shift', EffectType.rgbShift, layerId, ref),
                _buildEffectChip('Chromatic', EffectType.chromaticAberration, layerId, ref),
                _buildEffectChip('Pulse', EffectType.pulse, layerId, ref),
                _buildEffectChip('Glitch', EffectType.glitch, layerId, ref),
                _buildEffectChip('Wave', EffectType.wave, layerId, ref),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectChip(String label, EffectType type, String layerId, WidgetRef ref) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      backgroundColor: AppColors.surfaceLight,
      onPressed: () {
        final effect = EffectModel(
          id: IdGenerator.next(),
          type: type,
          intensity: 0.5,
        );
        ref.read(projectProvider.notifier).addEffect(layerId, effect);
        Navigator.of(context).pop();
      },
    );
  }

  void _showFilterMenu(BuildContext context, WidgetRef ref, String? layerId) {
    if (layerId == null) {
      _showToast(context, 'Select a layer first');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Add Filter', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(context, 'Grayscale', FilterPreset.grayscale, layerId, ref),
                _buildFilterChip(context, 'Sepia', FilterPreset.sepia, layerId, ref),
                _buildFilterChip(context, 'Invert', FilterPreset.invert, layerId, ref),
                _buildFilterChip(context, 'Brightness', FilterPreset.brightness, layerId, ref),
                _buildFilterChip(context, 'Contrast', FilterPreset.contrast, layerId, ref),
                _buildFilterChip(context, 'Saturation', FilterPreset.saturation, layerId, ref),
                _buildFilterChip(context, 'Vintage', FilterPreset.vintage, layerId, ref),
                _buildFilterChip(context, 'Cinematic', FilterPreset.cinematic, layerId, ref),
                _buildFilterChip(context, 'Dramatic', FilterPreset.dramatic, layerId, ref),
                _buildFilterChip(context, 'Warm', FilterPreset.warm, layerId, ref),
                _buildFilterChip(context, 'Cool', FilterPreset.cool, layerId, ref),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, FilterPreset preset, String layerId, WidgetRef ref) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      backgroundColor: AppColors.surfaceLight,
      onPressed: () {
        final filter = FilterModel(
          id: IdGenerator.next(),
          preset: preset,
          intensity: 1.0,
        );
        ref.read(projectProvider.notifier).addFilter(layerId, filter);
        Navigator.of(context).pop();
      },
    );
  }

  void _showVelocityDialog(BuildContext context, WidgetRef ref, String? layerId, String? clipId) {
    if (layerId == null || clipId == null) {
      _showToast(context, 'Select a clip first');
      return;
    }
    showDialog(
      context: context,
      builder: (_) => _VelocityDialog(layerId: layerId, clipId: clipId),
    );
  }

  void _addShakeEffect(BuildContext context, WidgetRef ref, String? layerId) {
    if (layerId == null) {
      _showToast(context, 'Select a layer first');
      return;
    }
    final effect = EffectModel(
      id: IdGenerator.next(),
      type: EffectType.shake,
      intensity: 0.5,
    );
    ref.read(projectProvider.notifier).addEffect(layerId, effect);
    _showToast(context, 'Shake effect added');
  }

  void _showVectorMenu(BuildContext context, WidgetRef ref, String? layerId) {
    if (layerId == null) {
      _showToast(context, 'Select a layer first');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Add Vector Shape', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildVectorChip(context, 'Rectangle', VectorShapeType.rectangle, layerId, ref),
                _buildVectorChip(context, 'Circle', VectorShapeType.circle, layerId, ref),
                _buildVectorChip(context, 'Star', VectorShapeType.star, layerId, ref),
                _buildVectorChip(context, 'Heart', VectorShapeType.heart, layerId, ref),
                _buildVectorChip(context, 'Arrow', VectorShapeType.arrow, layerId, ref),
                _buildVectorChip(context, 'Polygon', VectorShapeType.polygon, layerId, ref),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVectorChip(BuildContext context, String label, VectorShapeType type, String layerId, WidgetRef ref) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      backgroundColor: AppColors.surfaceLight,
      onPressed: () {
        final shape = VectorShapeModel(
          id: IdGenerator.next(),
          shapeType: type,
          fillColor: 0xFF00D4AA,
        );
        ref.read(projectProvider.notifier).addVectorShape(layerId, shape);
        Navigator.of(context).pop();
      },
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

class _VelocityDialog extends ConsumerStatefulWidget {
  final String layerId;
  final String clipId;

  const _VelocityDialog({required this.layerId, required this.clipId});

  @override
  ConsumerState<_VelocityDialog> createState() => _VelocityDialogState();
}

class _VelocityDialogState extends ConsumerState<_VelocityDialog> {
  VelocityCurveType _curveType = VelocityCurveType.constant;
  double _baseSpeed = 1.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Velocity', style: TextStyle(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<VelocityCurveType>(
            value: _curveType,
            dropdownColor: AppColors.surfaceLight,
            style: const TextStyle(color: AppColors.textPrimary),
            items: VelocityCurveType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.name, style: const TextStyle(color: AppColors.textPrimary)),
              );
            }).toList(),
            onChanged: (v) => setState(() => _curveType = v!),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Speed:', style: TextStyle(color: AppColors.textSecondary)),
              Expanded(
                child: Slider(
                  value: _baseSpeed,
                  min: 0.1,
                  max: 3.0,
                  divisions: 29,
                  label: '${_baseSpeed.toStringAsFixed(1)}x',
                  onChanged: (v) => setState(() => _baseSpeed = v),
                ),
              ),
              Text('${_baseSpeed.toStringAsFixed(1)}x', style: const TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            final velocity = VelocityModel(
              curveType: _curveType,
              baseSpeed: _baseSpeed,
            );
            ref.read(projectProvider.notifier).updateClipVelocity(widget.layerId, widget.clipId, velocity);
            Navigator.pop(context);
          },
          child: const Text('Apply', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }
}
