import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'project_provider.dart';
import 'timeline_provider.dart';

class PlaybackNotifier extends StateNotifier<bool> {
  final Ref _ref;
  Timer? _ticker;
  Stopwatch? _stopwatch;
  int _startPlayheadMs = 0;

  static const _tickInterval = Duration(milliseconds: 16);

  PlaybackNotifier(this._ref) : super(false);

  bool get isPlaying => state;

  void play() {
    if (state) return;
    final totalMs = _ref.read(projectProvider).totalDurationMs;
    if (totalMs <= 0) return;

    state = true;
    _ref.read(timelineUiProvider.notifier).setPlaying(true);
    _startPlayheadMs = _ref.read(timelineUiProvider).playheadMs;
    _stopwatch = Stopwatch()..start();
    _ticker = Timer.periodic(_tickInterval, (_) => _onTick());
  }

  void pause() {
    state = false;
    _ref.read(timelineUiProvider.notifier).setPlaying(false);
    _ticker?.cancel();
    _ticker = null;
    _stopwatch?.stop();
    _stopwatch = null;
  }

  void togglePlay() => state ? pause() : play();

  void _onTick() {
    if (_stopwatch == null) return;
    final elapsedMs = _stopwatch!.elapsedMilliseconds;
    final timelineNotifier = _ref.read(timelineUiProvider.notifier);
    final totalMs = _ref.read(projectProvider).totalDurationMs;

    final nextMs = _startPlayheadMs + elapsedMs;
    if (nextMs >= totalMs) {
      timelineNotifier.seekTo(0);
      pause();
      return;
    }
    timelineNotifier.seekTo(nextMs);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch?.stop();
    super.dispose();
  }
}

final playbackProvider = StateNotifierProvider<PlaybackNotifier, bool>((ref) => PlaybackNotifier(ref));
