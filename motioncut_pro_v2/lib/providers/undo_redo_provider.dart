import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/undo_redo_manager.dart';

final undoRedoManagerProvider = Provider<UndoRedoManager>((ref) => UndoRedoManager());
