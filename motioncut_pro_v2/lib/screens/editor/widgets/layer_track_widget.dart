import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_theme.dart';
import '../../../models/clip_model.dart';
import '../../../models/layer_model.dart';
import '../../../providers/project_provider.dart';
import '../../../providers/timeline_provider.dart';

class LayerTrackWidget extends ConsumerWidget {
  final LayerModel layer;
  final int layerIndex;
  final double pixelsPerMs;
  final int playheadMs;

  const LayerTrackWidget({
    super.key,
    required this.layer,
    required this.layerIndex,
    required this.pixelsPerMs,
    required this.playheadMs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(timelineUiProvider.select((s) => s.selectedLayerId == layer.id));

    return GestureDetector(
      onTap: () => ref.read(timelineUiProvider.notifier).selectLayer(layer.id),
      child: Container(
        height: AppDimens.layerTrackHeight,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceLight : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Layer info
            Container(
              width: 120,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Icon(
                    layer.visible ? Icons.visibility : Icons.visibility_off,
                    size: 16,
                    color: layer.visible ? AppColors.textSecondary : AppColors.textSecondary.withOpacity(0.3),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      layer.name,
                      style: TextStyle(
                        color: layer.visible ? AppColors.textPrimary : AppColors.textSecondary.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (layer.locked)
                    const Icon(Icons.lock, size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
            // Clips
            Expanded(
              child: Stack(
                children: [
                  for (final clip in layer.clips)
                    _ClipWidget(
                      clip: clip,
                      pixelsPerMs: pixelsPerMs,
                      isSelected: ref.watch(timelineUiProvider.select((s) => s.selectedClipId == clip.id)),
                      onTap: () {
                        ref.read(timelineUiProvider.notifier).selectClip(clip.id);
                        ref.read(timelineUiProvider.notifier).selectLayer(layer.id);
                      },
                      onDragEnd: (newStartMs) {
                        ref.read(projectProvider.notifier).moveClip(layer.id, clip.id, newStartMs.round());
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClipWidget extends StatefulWidget {
  final ClipModel clip;
  final double pixelsPerMs;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<double> onDragEnd;

  const _ClipWidget({
    required this.clip,
    required this.pixelsPerMs,
    required this.isSelected,
    required this.onTap,
    required this.onDragEnd,
  });

  @override
  State<_ClipWidget> createState() => _ClipWidgetState();
}

class _ClipWidgetState extends State<_ClipWidget> {
  double _dragStartX = 0;
  double _dragStartMs = 0;

  @override
  Widget build(BuildContext context) {
    final left = widget.clip.timelineStartMs * widget.pixelsPerMs;
    final width = widget.clip.timelineDurationMs * widget.pixelsPerMs;

    return Positioned(
      left: left,
      top: 4,
      bottom: 4,
      width: width.clamp(20, double.infinity),
      child: GestureDetector(
        onTap: widget.onTap,
        onHorizontalDragStart: (details) {
          _dragStartX = details.globalPosition.dx;
          _dragStartMs = widget.clip.timelineStartMs.toDouble();
        },
        onHorizontalDragUpdate: (details) {
          final deltaPx = details.globalPosition.dx - _dragStartX;
          final deltaMs = deltaPx / widget.pixelsPerMs;
          setState(() {}); // Visual feedback during drag
        },
        onHorizontalDragEnd: (details) {
          final deltaPx = details.globalPosition.dx - _dragStartX;
          final deltaMs = deltaPx / widget.pixelsPerMs;
          widget.onDragEnd(_dragStartMs + deltaMs);
        },
        child: Container(
          decoration: BoxDecoration(
            color: _getClipColor().withOpacity(widget.isSelected ? 1.0 : 0.7),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: widget.isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(_getClipIcon(), size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getClipLabel(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getClipColor() {
    switch (widget.clip.sourceType) {
      case ClipSourceType.video:
        return const Color(0xFF3498DB);
      case ClipSourceType.image:
        return const Color(0xFF2ECC71);
      case ClipSourceType.audio:
        return const Color(0xFFE67E22);
      case ClipSourceType.text:
        return const Color(0xFF9B59B6);
      case ClipSourceType.sticker:
        return const Color(0xFF1ABC9C);
    }
  }

  IconData _getClipIcon() {
    switch (widget.clip.sourceType) {
      case ClipSourceType.video:
        return Icons.videocam;
      case ClipSourceType.image:
        return Icons.image;
      case ClipSourceType.audio:
        return Icons.audiotrack;
      case ClipSourceType.text:
        return Icons.text_fields;
      case ClipSourceType.sticker:
        return Icons.emoji_emotions;
    }
  }

  String _getClipLabel() {
    if (widget.clip.textContent != null && widget.clip.textContent!.isNotEmpty) {
      return widget.clip.textContent!;
    }
    final path = widget.clip.sourcePath.split('/').last;
    return path.length > 15 ? '...${path.substring(path.length - 12)}' : path;
  }
}
