import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_theme.dart';
import '../../../models/layer_model.dart';
import '../../../providers/project_provider.dart';
import '../../../providers/timeline_provider.dart';
import 'layer_track_widget.dart';

class TimelineWidget extends ConsumerWidget {
  const TimelineWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider);
    final playheadMs = ref.watch(timelineUiProvider.select((s) => s.playheadMs));
    final pixelsPerMs = ref.watch(timelineUiProvider.select((s) => s.pixelsPerMs));
    final isSnapEnabled = ref.watch(timelineUiProvider.select((s) => s.isSnapEnabled));

    final totalWidth = project.totalDurationMs * pixelsPerMs;

    return Container(
      color: AppColors.timelineBg,
      child: Column(
        children: [
          // Ruler
          _TimelineRuler(
            totalDurationMs: project.totalDurationMs,
            pixelsPerMs: pixelsPerMs,
            playheadMs: playheadMs,
          ),
          // Playhead
          SizedBox(
            height: 2,
            child: Stack(
              children: [
                Positioned(
                  left: playheadMs * pixelsPerMs,
                  child: Container(
                    width: AppDimens.playheadWidth,
                    height: 2,
                    color: AppColors.playhead,
                  ),
                ),
              ],
            ),
          ),
          // Layer tracks
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _syncController(ref),
              child: SizedBox(
                width: totalWidth + 100,
                child: Column(
                  children: [
                    for (int i = 0; i < project.layers.length; i++)
                      LayerTrackWidget(
                        layer: project.layers[i],
                        layerIndex: i,
                        pixelsPerMs: pixelsPerMs,
                        playheadMs: playheadMs,
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Controls
          Container(
            height: 36,
            color: AppColors.surface,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isSnapEnabled ? Icons.magnet_on : Icons.magnet,
                    size: 18,
                    color: isSnapEnabled ? AppColors.primary : AppColors.textSecondary,
                  ),
                  onPressed: () => ref.read(timelineUiProvider.notifier).toggleSnap(),
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_in, size: 18, color: AppColors.textSecondary),
                  onPressed: () => ref.read(timelineUiProvider.notifier).zoom(pixelsPerMs * 1.2),
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_out, size: 18, color: AppColors.textSecondary),
                  onPressed: () => ref.read(timelineUiProvider.notifier).zoom(pixelsPerMs / 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ScrollController _syncController(WidgetRef ref) {
    // In production, sync horizontal scroll with playhead position
    return ScrollController();
  }
}

class _TimelineRuler extends StatelessWidget {
  final int totalDurationMs;
  final double pixelsPerMs;
  final int playheadMs;

  const _TimelineRuler({
    required this.totalDurationMs,
    required this.pixelsPerMs,
    required this.playheadMs,
  });

  @override
  Widget build(BuildContext context) {
    final totalWidth = totalDurationMs * pixelsPerMs;
    final intervalMs = _calculateInterval();

    return Container(
      height: 24,
      color: AppColors.surface,
      child: CustomPaint(
        size: Size(totalWidth + 100, 24),
        painter: _RulerPainter(
          pixelsPerMs: pixelsPerMs,
          intervalMs: intervalMs,
          totalDurationMs: totalDurationMs,
        ),
      ),
    );
  }

  int _calculateInterval() {
    if (pixelsPerMs > 0.5) return 1000;      // 1 second
    if (pixelsPerMs > 0.2) return 2000;      // 2 seconds
    if (pixelsPerMs > 0.1) return 5000;      // 5 seconds
    if (pixelsPerMs > 0.05) return 10000;    // 10 seconds
    return 30000;                             // 30 seconds
  }
}

class _RulerPainter extends CustomPainter {
  final double pixelsPerMs;
  final int intervalMs;
  final int totalDurationMs;

  _RulerPainter({
    required this.pixelsPerMs,
    required this.intervalMs,
    required this.totalDurationMs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 1;

    final textStyle = const TextStyle(color: AppColors.textSecondary, fontSize: 10);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int ms = 0; ms <= totalDurationMs; ms += intervalMs) {
      final x = ms * pixelsPerMs;
      canvas.drawLine(Offset(x, 16), Offset(x, 24), paint);

      final seconds = ms ~/ 1000;
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      final label = '$minutes:${secs.toString().padLeft(2, '0')}';

      textPainter.text = TextSpan(text: label, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 2, 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
