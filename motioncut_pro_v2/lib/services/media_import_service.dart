import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/clip_model.dart';

class MediaImportService {
  final ImagePicker _picker = ImagePicker();

  Future<List<ClipModel>> pickVideos() async {
    final files = await _picker.pickMultipleMedia();
    return _processFiles(files.where((f) => _isVideo(f.path)).toList(), ClipSourceType.video);
  }

  Future<List<ClipModel>> pickImages() async {
    final files = await _picker.pickMultipleMedia();
    return _processFiles(files.where((f) => !_isVideo(f.path)).toList(), ClipSourceType.image);
  }

  Future<ClipModel?> pickSingleVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return null;
    final copied = await _copyToAppDir(file.path);
    return ClipModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sourcePath: copied,
      sourceType: ClipSourceType.video,
      outPointMs: 5000,
    );
  }

  List<ClipModel> _processFiles(List<XFile> files, ClipSourceType type) {
    return files.map((f) => ClipModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_${files.indexOf(f)}',
      sourcePath: f.path,
      sourceType: type,
      outPointMs: type == ClipSourceType.video ? 5000 : 3000,
    )).toList();
  }

  Future<String> _copyToAppDir(String sourcePath) async {
    final docs = await getApplicationDocumentsDirectory();
    final fileName = p.basename(sourcePath);
    final dest = '${docs.path}/media/$fileName';
    await Directory('${docs.path}/media').create(recursive: true);
    await File(sourcePath).copy(dest);
    return dest;
  }

  bool _isVideo(String path) {
    final ext = p.extension(path).toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.wmv'].contains(ext);
  }
}
