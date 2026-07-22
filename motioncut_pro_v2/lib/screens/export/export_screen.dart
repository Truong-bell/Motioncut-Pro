import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_theme.dart';
import '../../models/project_model.dart';
import '../../providers/project_provider.dart';
import '../../services/ffmpeg_export_service.dart';
import '../../widgets/common/gradient_button.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _isExporting = false;
  double _progress = 0.0;
  String? _outputPath;

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Export'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${project.resolution.width}x${project.resolution.height} • ${project.fps}fps • ${project.layers.length} layers',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            const Text(
              'Resolution',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildResolutionSelector(project),
            const SizedBox(height: 32),
            if (_isExporting) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text('Exporting...', style: TextStyle(color: AppColors.textSecondary)),
            ] else if (_outputPath != null) ...[
              const Icon(Icons.check_circle, color: AppColors.primary, size: 48),
              const SizedBox(height: 16),
              const Text('Export complete!', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
              const SizedBox(height: 8),
              Text(_outputPath!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ] else ...[
              GradientButton(
                text: 'Export Video',
                onPressed: () => _startExport(project),
                width: double.infinity,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionSelector(ProjectModel project) {
    return Row(
      children: [
        _buildResChip('720p', ExportResolution.r720p, project.resolution),
        const SizedBox(width: 8),
        _buildResChip('1080p', ExportResolution.r1080p, project.resolution),
        const SizedBox(width: 8),
        _buildResChip('4K', ExportResolution.r4k, project.resolution),
      ],
    );
  }

  Widget _buildResChip(String label, ExportResolution res, ExportResolution current) {
    final isSelected = current == res;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceLight,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      onSelected: (_) {
        ref.read(projectProvider.notifier).setResolution(res);
      },
    );
  }

  Future<void> _startExport(ProjectModel project) async {
    setState(() {
      _isExporting = true;
      _progress = 0.0;
    });

    final service = FFmpegExportService();
    final path = await service.exportProject(
      project,
      onProgress: (p) => setState(() => _progress = p),
    );

    setState(() {
      _isExporting = false;
      _outputPath = path;
    });
  }
}
