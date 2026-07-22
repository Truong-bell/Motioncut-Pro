import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/playback_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/timeline_provider.dart';
import '../../services/project_storage_service.dart';
import 'widgets/preview_canvas.dart';
import 'widgets/timeline_widget.dart';
import 'widgets/toolbar_widget.dart';
import 'widgets/keyframe_editor_panel.dart';
import '../export/export_screen.dart';
import '../media_picker/media_picker_screen.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final _storage = ProjectStorageService();
  bool _showKeyframePanel = false;
  bool _showEffectsPanel = false;

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider);
    final isPlaying = ref.watch(playbackProvider);
    final playheadMs = ref.watch(timelineUiProvider.select((s) => s.playheadMs));
    final selectedLayerId = ref.watch(timelineUiProvider.select((s) => s.selectedLayerId));

    final duration = Duration(milliseconds: playheadMs);
    final timeStr =
        '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}.${(duration.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(project.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await _storage.saveProject(project);
            if (mounted) Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              await _storage.saveProject(project);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project saved')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () {}, // TODO: implement undo
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: () {}, // TODO: implement redo
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview Area
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  const PreviewCanvas(),
                  // Playback controls overlay
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildControlButton(
                          Icons.skip_previous,
                          () => ref.read(timelineUiProvider.notifier).seekTo(0),
                        ),
                        const SizedBox(width: 16),
                        _buildControlButton(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          () => ref.read(playbackProvider.notifier).togglePlay(),
                          size: 56,
                        ),
                        const SizedBox(width: 16),
                        _buildControlButton(
                          Icons.skip_next,
                          () => ref.read(timelineUiProvider.notifier).seekTo(project.totalDurationMs),
                        ),
                      ],
                    ),
                  ),
                  // Time display
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        timeStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Toolbar
          ToolbarWidget(
            onAddMedia: () => _showMediaPicker(),
            onToggleKeyframe: () => setState(() => _showKeyframePanel = !_showKeyframePanel),
            onToggleEffects: () => setState(() => _showEffectsPanel = !_showEffectsPanel),
            onExport: () => _showExportScreen(),
          ),

          // Effect/Keyframe panels
          if (_showEffectsPanel || _showKeyframePanel)
            Container(
              height: 200,
              color: AppColors.surface,
              child: _showKeyframePanel
                  ? const KeyframeEditorPanel()
                  : _buildEffectsPanel(selectedLayerId),
            ),

          // Timeline
          const Expanded(
            flex: 2,
            child: TimelineWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onTap, {double size = 40}) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }

  Widget _buildEffectsPanel(String? layerId) {
    if (layerId == null) {
      return const Center(
        child: Text('Select a layer to edit effects', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return const Center(
      child: Text('Effects Panel - Use toolbar buttons', style: TextStyle(color: AppColors.textSecondary)),
    );
  }

  void _showMediaPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MediaPickerScreen()),
    );
  }

  void _showExportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExportScreen()),
    );
  }
}
