import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/color_filter_utils.dart';
import '../../../models/clip_model.dart';
import '../../../models/effect_model.dart';
import '../../../models/filter_model.dart';
import '../../../models/keyframe_model.dart';
import '../../../models/layer_model.dart';
import '../../../models/vector_shape_model.dart';
import '../../../providers/project_provider.dart';
import '../../../providers/timeline_provider.dart';

/// Preview canvas with full support for effects, filters, vector shapes,
/// velocity curves, shake, and transforms.
class PreviewCanvas extends ConsumerWidget {
  const PreviewCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider);
    final playheadMs = ref.watch(timelineUiProvider.select((s) => s.playheadMs));
    final aspectRatio = project.resolution.width / project.resolution.height;

    return RepaintBoundary(
      child: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              border: Border.all(color: AppColors.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                for (final layer in project.layers.reversed)
                  if (layer.visible)
                    _LayerPreview(
                      key: ValueKey(layer.id),
                      layer: layer,
                      timeMs: playheadMs,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LayerPreview extends StatefulWidget {
  final LayerModel layer;
  final int timeMs;

  const _LayerPreview({super.key, required this.layer, required this.timeMs});

  @override
  State<_LayerPreview> createState() => _LayerPreviewState();
}

class _LayerPreviewState extends State<_LayerPreview> {
  final Map<String, VideoPlayerController> _controllers = {};
  String? _activeKey;

  ClipModel? get _activeClip {
    for (final clip in widget.layer.clips) {
      if (widget.timeMs >= clip.timelineStartMs && widget.timeMs < clip.timelineEndMs) {
        return clip;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _syncVideoController();
  }

  @override
  void didUpdateWidget(covariant _LayerPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncVideoController();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  void _syncVideoController() {
    final active = _activeClip;
    final newKey = active == null ? null : '${active.id}::${active.sourcePath}';

    if (newKey == _activeKey) {
      _seekActiveController();
      return;
    }
    _activeKey = newKey;

    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    if (active != null && active.sourceType == ClipSourceType.video) {
      _initController(active);
    }
  }

  Future<void> _initController(ClipModel clip) async {
    final controller = VideoPlayerController.file(File(clip.sourcePath));
    _controllers[clip.id] = controller;
    try {
      await controller.initialize();
      await controller.pause();
      await controller.setVolume(clip.volume.clamp(0.0, 1.0));

      if (!mounted || _activeKey != '${clip.id}::${clip.sourcePath}') {
        controller.dispose();
        _controllers.remove(clip.id);
        return;
      }

      _seekController(controller, clip, force: true);
      if (mounted) setState(() {});
    } catch (_) {
      _controllers.remove(clip.id);
      if (mounted) setState(() {});
    }
  }

  void _seekActiveController() {
    final active = _activeClip;
    if (active == null || active.sourceType != ClipSourceType.video) return;
    final controller = _controllers[active.id];
    if (controller == null || !controller.value.isInitialized) return;
    _seekController(controller, active);
  }

  void _seekController(VideoPlayerController controller, ClipModel clip, {bool force = false}) {
    final sourceMs = clip.sourceTimeAt(widget.timeMs);
    final clampedMs = sourceMs.clamp(clip.inPointMs, clip.outPointMs);
    final target = Duration(milliseconds: clampedMs);
    final current = controller.value.position;

    if (force || (target - current).inMilliseconds.abs() > 33) {
      controller.seekTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clip = _activeClip;
    if (clip == null && widget.layer.type != LayerType.vector) {
      return const SizedBox.shrink();
    }

    // Get interpolated transform values
    final x = widget.layer.valueAt(KeyframeProperty.positionX, widget.timeMs);
    final y = widget.layer.valueAt(KeyframeProperty.positionY, widget.timeMs);
    final scale = widget.layer.valueAt(KeyframeProperty.scale, widget.timeMs);
    final rotationDeg = widget.layer.valueAt(KeyframeProperty.rotation, widget.timeMs);
    final opacity = widget.layer.valueAt(KeyframeProperty.opacity, widget.timeMs);
    final skewX = widget.layer.valueAt(KeyframeProperty.skewX, widget.timeMs);
    final skewY = widget.layer.valueAt(KeyframeProperty.skewY, widget.timeMs);

    // Get active effects and filters
    final activeEffects = widget.layer.activeEffectsAt(widget.timeMs);
    final activeFilters = widget.layer.activeFiltersAt(widget.timeMs);

    // Apply shake if present
    var shakeOffset = Offset.zero;
    final shakeEffect = activeEffects.where((e) => e.type == EffectType.shake).isEmpty ? null : activeEffects.where((e) => e.type == EffectType.shake).first;
    if (shakeEffect != null) {
      shakeOffset = _calculateShake(shakeEffect, widget.timeMs);
    }

    // Build color filter
    ColorFilter? colorFilter;
    for (final filter in activeFilters) {
      final cf = ColorFilterUtils.buildFilter(filter.preset, intensity: filter.intensity);
      if (cf != null) {
        colorFilter = cf; // For simplicity, use last filter; in production compose them
      }
    }

    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(x, y) + shakeOffset,
        child: Transform.rotate(
          angle: rotationDeg * pi / 180,
          child: Transform.scale(
            scale: scale,
            child: Transform(
              transform: Matrix4.skewX(skewX * pi / 180)..skewY(skewY * pi / 180),
              alignment: Alignment.center,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: _buildEffectsWrapper(
                  activeEffects,
                  _buildFilterWrapper(
                    colorFilter,
                    RepaintBoundary(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (clip != null) _buildClipContent(clip),
                          if (widget.layer.type == LayerType.vector || widget.layer.vectorShapes.isNotEmpty)
                            ...widget.layer.vectorShapes.map((shape) => _buildVectorShape(shape)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Offset _calculateShake(EffectModel effect, int timeMs) {
    final seed = timeMs ~/ 50; // Update every 50ms
    final random = Random(seed);
    final intensity = effect.intensity * 20;
    return Offset(
      (random.nextDouble() - 0.5) * intensity,
      (random.nextDouble() - 0.5) * intensity,
    );
  }

  Widget _buildEffectsWrapper(List<EffectModel> effects, Widget child) {
    Widget result = child;

    for (final effect in effects) {
      switch (effect.type) {
        case EffectType.blur:
          result = ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: effect.radius, sigmaY: effect.radius),
            child: result,
          );
        case EffectType.glow:
          result = Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcATop),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: effect.radius * 2, sigmaY: effect.radius * 2),
                  child: result,
                ),
              ),
              result,
            ],
          );
        case EffectType.vignette:
          result = Stack(
            fit: StackFit.expand,
            children: [
              result,
              CustomPaint(
                painter: _VignettePainter(intensity: effect.intensity),
                size: Size.infinite,
              ),
            ],
          );
        case EffectType.pixelate:
          result = ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: effect.intensity * 5, sigmaY: effect.intensity * 5),
            child: result,
          );
        case EffectType.rgbShift:
          result = _RGBShiftWidget(intensity: effect.intensity, child: result);
        case EffectType.chromaticAberration:
          result = _ChromaticAberrationWidget(intensity: effect.intensity, child: result);
        default:
          break;
      }
    }

    return result;
  }

  Widget _buildFilterWrapper(ColorFilter? filter, Widget child) {
    if (filter == null) return child;
    return ColorFiltered(colorFilter: filter, child: child);
  }

  Widget _buildClipContent(ClipModel clip) {
    switch (clip.sourceType) {
      case ClipSourceType.text:
        return Center(
          child: Text(
            clip.textContent ?? '',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontFamily: clip.fontFamily,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case ClipSourceType.video:
        final controller = _controllers[clip.id];
        if (controller == null || !controller.value.isInitialized) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        );
      case ClipSourceType.image:
        return Image.file(
          File(clip.sourcePath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, color: AppColors.textSecondary, size: 48),
          ),
        );
      case ClipSourceType.audio:
      case ClipSourceType.sticker:
        return const SizedBox.shrink();
    }
  }

  Widget _buildVectorShape(VectorShapeModel shape) {
    return CustomPaint(
      painter: _VectorShapePainter(shape: shape),
      size: Size.infinite,
    );
  }
}

// ===== Custom Painters & Widgets =====

class _VignettePainter extends CustomPainter {
  final double intensity;
  _VignettePainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = RadialGradient(
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(intensity * 0.8),
      ],
      stops: const [0.6, 1.0],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _VectorShapePainter extends CustomPainter {
  final VectorShapeModel shape;
  _VectorShapePainter({required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2 + shape.position.x,
      size.height / 2 + shape.position.y,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(shape.rotation * pi / 180);
    canvas.scale(shape.scale);

    final path = _buildPath();

    // Fill
    if (shape.fillType != VectorFillType.none) {
      final paint = Paint();
      if (shape.fillType == VectorFillType.gradientLinear && shape.fillColor2 != null) {
        paint.shader = LinearGradient(
          colors: [Color(shape.fillColor), Color(shape.fillColor2!)],
        ).createShader(Rect.fromCenter(center: Offset.zero, width: 200, height: 200));
      } else if (shape.fillType == VectorFillType.gradientRadial && shape.fillColor2 != null) {
        paint.shader = RadialGradient(
          colors: [Color(shape.fillColor), Color(shape.fillColor2!)],
        ).createShader(Rect.fromCenter(center: Offset.zero, width: 200, height: 200));
      } else {
        paint.color = Color(shape.fillColor).withOpacity(shape.fillOpacity);
      }
      canvas.drawPath(path, paint);
    }

    // Stroke
    if (shape.hasStroke) {
      final strokePaint = Paint()
        ..color = Color(shape.strokeColor)
        ..strokeWidth = shape.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = _getStrokeCap();
      canvas.drawPath(path, strokePaint);
    }

    canvas.restore();
  }

  Path _buildPath() {
    final path = Path();
    switch (shape.shapeType) {
      case VectorShapeType.rectangle:
        path.addRect(const Rect.fromCenter(center: Offset.zero, width: 100, height: 60));
      case VectorShapeType.roundedRectangle:
        path.addRRect(RRect.fromRectAndRadius(
          const Rect.fromCenter(center: Offset.zero, width: 100, height: 60),
          Radius.circular(shape.cornerRadius),
        ));
      case VectorShapeType.circle:
        path.addOval(const Rect.fromCenter(center: Offset.zero, width: 80, height: 80));
      case VectorShapeType.ellipse:
        path.addOval(const Rect.fromCenter(center: Offset.zero, width: 120, height: 80));
      case VectorShapeType.line:
        if (shape.points.length >= 2) {
          path.moveTo(shape.points[0].x, shape.points[0].y);
          path.lineTo(shape.points[1].x, shape.points[1].y);
        }
      case VectorShapeType.polygon:
        _drawPolygon(path, shape.sides, 50);
      case VectorShapeType.star:
        _drawStar(path, shape.sides, 50, shape.innerRadius);
      case VectorShapeType.heart:
        _drawHeart(path, 40);
      case VectorShapeType.arrow:
        _drawArrow(path, 60, 30);
      case VectorShapeType.path:
        if (shape.points.isNotEmpty) {
          path.moveTo(shape.points[0].x, shape.points[0].y);
          for (int i = 1; i < shape.points.length; i++) {
            path.lineTo(shape.points[i].x, shape.points[i].y);
          }
          if (shape.closed) path.close();
        }
    }
    return path;
  }

  void _drawPolygon(Path path, int sides, double radius) {
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2;
      final x = radius * cos(angle);
      final y = radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
  }

  void _drawStar(Path path, int points, double outerRadius, double innerRatio) {
    final innerRadius = outerRadius * innerRatio;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * pi / points) - pi / 2;
      final r = i.isEven ? outerRadius : innerRadius;
      final x = r * cos(angle);
      final y = r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
  }

  void _drawHeart(Path path, double size) {
    final s = size;
    path.moveTo(0, s * 0.3);
    path.cubicTo(-s * 0.5, -s * 0.3, -s, s * 0.1, 0, s * 0.8);
    path.cubicTo(s, s * 0.1, s * 0.5, -s * 0.3, 0, s * 0.3);
    path.close();
  }

  void _drawArrow(Path path, double w, double h) {
    path.moveTo(-w / 2, -h / 4);
    path.lineTo(w / 4, -h / 4);
    path.lineTo(w / 4, -h / 2);
    path.lineTo(w / 2, 0);
    path.lineTo(w / 4, h / 2);
    path.lineTo(w / 4, h / 4);
    path.lineTo(-w / 2, h / 4);
    path.close();
  }

  StrokeCap _getStrokeCap() {
    switch (shape.strokeCap) {
      case VectorStrokeCap.butt:
        return StrokeCap.butt;
      case VectorStrokeCap.round:
        return StrokeCap.round;
      case VectorStrokeCap.square:
        return StrokeCap.square;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RGBShiftWidget extends StatelessWidget {
  final double intensity;
  final Widget child;
  const _RGBShiftWidget({required this.intensity, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
          child: Transform.translate(
            offset: Offset(-intensity * 5, 0),
            child: child,
          ),
        ),
        ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.blue, BlendMode.srcIn),
          child: Transform.translate(
            offset: Offset(intensity * 5, 0),
            child: child,
          ),
        ),
        child,
      ],
    );
  }
}

class _ChromaticAberrationWidget extends StatelessWidget {
  final double intensity;
  final Widget child;
  const _ChromaticAberrationWidget({required this.intensity, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            1, 0, 0, 0, 0,
            0, 0, 0, 0, 0,
            0, 0, 0, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: Transform.translate(
            offset: Offset(-intensity * 8, 0),
            child: child,
          ),
        ),
        ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0, 0, 0, 0, 0,
            0, 0, 0, 0, 0,
            0, 0, 1, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: Transform.translate(
            offset: Offset(intensity * 8, 0),
            child: child,
          ),
        ),
        child,
      ],
    );
  }
}


