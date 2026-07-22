import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimelineUiState {
  final int playheadMs;
  final double pixelsPerMs;
  final bool isSnapEnabled;
  final bool isBeatSnapEnabled;
  final String? selectedLayerId;
  final String? selectedClipId;
  final String? selectedEffectId;
  final String? selectedFilterId;
  final bool isPlaying;

  const TimelineUiState({
    this.playheadMs = 0,
    this.pixelsPerMs = 0.08,
    this.isSnapEnabled = true,
    this.isBeatSnapEnabled = false,
    this.selectedLayerId,
    this.selectedClipId,
    this.selectedEffectId,
    this.selectedFilterId,
    this.isPlaying = false,
  });

  TimelineUiState copyWith({
    int? playheadMs,
    double? pixelsPerMs,
    bool? isSnapEnabled,
    bool? isBeatSnapEnabled,
    String? selectedLayerId,
    String? selectedClipId,
    String? selectedEffectId,
    String? selectedFilterId,
    bool? isPlaying,
  }) =>
      TimelineUiState(
        playheadMs: playheadMs ?? this.playheadMs,
        pixelsPerMs: pixelsPerMs ?? this.pixelsPerMs,
        isSnapEnabled: isSnapEnabled ?? this.isSnapEnabled,
        isBeatSnapEnabled: isBeatSnapEnabled ?? this.isBeatSnapEnabled,
        selectedLayerId: selectedLayerId ?? this.selectedLayerId,
        selectedClipId: selectedClipId ?? this.selectedClipId,
        selectedEffectId: selectedEffectId ?? this.selectedEffectId,
        selectedFilterId: selectedFilterId ?? this.selectedFilterId,
        isPlaying: isPlaying ?? this.isPlaying,
      );
}

class TimelineUiNotifier extends StateNotifier<TimelineUiState> {
  TimelineUiNotifier() : super(const TimelineUiState());

  void seekTo(int ms) => state = state.copyWith(playheadMs: ms);
  void zoom(double pixelsPerMs) => state = state.copyWith(pixelsPerMs: pixelsPerMs);
  void toggleSnap() => state = state.copyWith(isSnapEnabled: !state.isSnapEnabled);
  void toggleBeatSnap() => state = state.copyWith(isBeatSnapEnabled: !state.isBeatSnapEnabled);
  void selectLayer(String? id) => state = state.copyWith(selectedLayerId: id);
  void selectClip(String? id) => state = state.copyWith(selectedClipId: id);
  void selectEffect(String? id) => state = state.copyWith(selectedEffectId: id);
  void selectFilter(String? id) => state = state.copyWith(selectedFilterId: id);
  void setPlaying(bool playing) => state = state.copyWith(isPlaying: playing);
}

final timelineUiProvider = StateNotifierProvider<TimelineUiNotifier, TimelineUiState>((ref) => TimelineUiNotifier());
