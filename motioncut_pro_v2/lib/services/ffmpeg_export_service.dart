import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import '../models/clip_model.dart';
import '../models/effect_model.dart';
import '../models/filter_model.dart';
import '../models/layer_model.dart';
import '../models/project_model.dart';
import '../models/velocity_model.dart';

class FFmpegExportService {
  /// Export project to video file.
  Future<String?> exportProject(ProjectModel project, {void Function(double)? onProgress}) async {
    final docs = await getApplicationDocumentsDirectory();
    final outputPath = '${docs.path}/exports/${project.id}_${DateTime.now().millisecondsSinceEpoch}.mp4';
    await Directory('${docs.path}/exports').create(recursive: true);

    final inputs = <String>[];
    final filters = <String>[];
    final overlays = <String>[];
    var inputIndex = 0;

    for (int li = 0; li < project.layers.length; li++) {
      final layer = project.layers[li];
      if (!layer.visible) continue;

      for (final clip in layer.clips) {
        if (clip.sourceType == ClipSourceType.video || clip.sourceType == ClipSourceType.image) {
          inputs.add('-i "${clip.sourcePath}"');
          final filter = _buildClipFilter(clip, inputIndex, layer, project);
          filters.add(filter);
          inputIndex++;
        }
      }
    }

    if (inputs.isEmpty) return null;

    final filterComplex = filters.join(';');
    final cmd = '-y ${inputs.join(' ')} '
        '-filter_complex "$filterComplex" '
        '-c:v libx264 -preset fast -crf 23 '
        '-pix_fmt yuv420p '
        '-r ${project.fps} '
        '-s ${project.resolution.width}x${project.resolution.height} '
        '"$outputPath"';

    final session = await FFmpegKit.execute(cmd);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    }
    return null;
  }

  String _buildClipFilter(ClipModel clip, int inputIdx, LayerModel layer, ProjectModel project) {
    final parts = <String>[];
    parts.add('[$inputIdx:v]');

    // Apply velocity/speed
    if (clip.velocity.curveType != VelocityCurveType.constant || clip.velocity.baseSpeed != 1.0) {
      final setpts = clip.velocity.baseSpeed != 1.0 ? 'setpts=PTS/${clip.velocity.baseSpeed}' : '';
      if (setpts.isNotEmpty) parts.add(setpts);
    }

    // Apply filters
    for (final filter in layer.filters.where((f) => f.enabled)) {
      parts.add(_filterToFFmpeg(filter));
    }

    // Apply effects
    for (final effect in layer.effects.where((e) => e.enabled)) {
      parts.add(_effectToFFmpeg(effect));
    }

    // Scale to project resolution
    parts.add('scale=${project.resolution.width}:${project.resolution.height}:force_original_aspect_ratio=decrease,pad=${project.resolution.width}:${project.resolution.height}:(ow-iw)/2:(oh-ih)/2');

    parts.add('vout$inputIdx');
    return parts.join(',');
  }

  String _filterToFFmpeg(FilterModel filter) {
    switch (filter.preset) {
      case FilterPreset.grayscale:
        return 'format=gray';
      case FilterPreset.sepia:
        return 'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131';
      case FilterPreset.brightness:
        return 'eq=brightness=${filter.intensity - 1.0}';
      case FilterPreset.contrast:
        return 'eq=contrast=${filter.intensity}';
      case FilterPreset.saturation:
        return 'eq=saturation=${filter.intensity}';
      case FilterPreset.vintage:
        return 'curves=vintage';
      case FilterPreset.cinematic:
        return 'eq=contrast=1.2:saturation=0.8';
      default:
        return '';
    }
  }

  String _effectToFFmpeg(EffectModel effect) {
    switch (effect.type) {
      case EffectType.blur:
        return 'boxblur=${effect.radius}:${effect.radius}';
      case EffectType.vignette:
        return 'vignette=PI/${4 - effect.intensity * 3}';
      case EffectType.shake:
        return 'crop=in_w*0.9:in_h*0.9';
      case EffectType.pixelate:
        return 'pixelize=w=${(effect.intensity * 20).toInt()}:h=${(effect.intensity * 20).toInt()}';
      default:
        return '';
    }
  }
}
