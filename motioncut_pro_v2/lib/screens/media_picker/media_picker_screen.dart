import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/id_generator.dart';
import '../../models/clip_model.dart';
import '../../models/layer_model.dart';
import '../../providers/project_provider.dart';
import '../../services/media_import_service.dart';

class MediaPickerScreen extends ConsumerStatefulWidget {
  const MediaPickerScreen({super.key});

  @override
  ConsumerState<MediaPickerScreen> createState() => _MediaPickerScreenState();
}

class _MediaPickerScreenState extends ConsumerState<MediaPickerScreen> {
  final _importService = MediaImportService();
  List<ClipModel> _selectedClips = [];
  bool _isLoading = false;

  Future<void> _pickVideos() async {
    setState(() => _isLoading = true);
    final clips = await _importService.pickVideos();
    setState(() {
      _selectedClips = clips;
      _isLoading = false;
    });
  }

  Future<void> _pickImages() async {
    setState(() => _isLoading = true);
    final clips = await _importService.pickImages();
    setState(() {
      _selectedClips = clips;
      _isLoading = false;
    });
  }

  void _addToProject() {
    if (_selectedClips.isEmpty) return;

    final projectNotifier = ref.read(projectProvider.notifier);
    final project = ref.read(projectProvider);

    // Create a new layer for the imported media
    final layer = LayerModel(
      id: IdGenerator.next(),
      name: 'Layer ${project.layers.length + 1}',
      type: _selectedClips.first.sourceType == ClipSourceType.video
          ? LayerType.video
          : LayerType.image,
      clips: _selectedClips,
    );

    projectNotifier.addLayer(layer);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Import Media'),
        actions: [
          if (_selectedClips.isNotEmpty)
            TextButton(
              onPressed: _addToProject,
              child: const Text('Add', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildImportButton(
                    Icons.videocam,
                    'Videos',
                    AppColors.primary,
                    _pickVideos,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImportButton(
                    Icons.image,
                    'Images',
                    AppColors.accent,
                    _pickImages,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_selectedClips.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Select media to import',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _selectedClips.length,
                itemBuilder: (context, index) {
                  final clip = _selectedClips[index];
                  return ListTile(
                    leading: Icon(
                      clip.sourceType == ClipSourceType.video ? Icons.videocam : Icons.image,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      clip.sourcePath.split('/').last,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      '${clip.timelineDurationMs}ms',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImportButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
