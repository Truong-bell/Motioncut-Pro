abstract class EditCommand {
  String get label;
  void execute();
  void undo();
}

class UndoRedoManager {
  final List<EditCommand> _undoStack = [];
  final List<EditCommand> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void execute(EditCommand cmd) {
    cmd.execute();
    _undoStack.add(cmd);
    _redoStack.clear();
  }

  void undo() {
    if (!canUndo) return;
    final cmd = _undoStack.removeLast();
    cmd.undo();
    _redoStack.add(cmd);
  }

  void redo() {
    if (!canRedo) return;
    final cmd = _redoStack.removeLast();
    cmd.execute();
    _undoStack.add(cmd);
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
