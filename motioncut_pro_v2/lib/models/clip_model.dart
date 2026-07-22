import 'package:equatable/equatable.dart';
import '../core/utils/id_generator.dart';
import 'velocity_model.dart';

enum ClipSourceType { video, image, audio, text, sticker }

enum TransitionType { none, fade, slideLeft, slideRight, slideUp, slideDown, zoomIn, zoomOut, spin, wipe }

class ClipModel extends Equatable {
  final String id;
  final String sourcePath;
  final ClipSourceType sourceType;
  final int inPointMs;
  final int outPointMs;
  final int timelineStartMs;
  final double speed;
  final TransitionType transitionIn;
  final TransitionType transitionOut;
  final String? textContent;
  final String? fontFamily;
  final double volume;           // NEW: audio volume 0.0-1.0
  final VelocityModel velocity;  // NEW: time remapping / speed curve

  const ClipModel({
    required this.id,
    required this.sourcePath,
    required this.sourceType,
    this.inPointMs = 0,
    this.outPointMs = 5000,
    this.timelineStartMs = 0,
    this.speed = 1.0,
    this.transitionIn = TransitionType.none,
    this.transitionOut = TransitionType.none,
    this.textContent,
    this.fontFamily,
    this.volume = 1.0,
    this.velocity = const VelocityModel(),
  });

  int get timelineDurationMs {
    final raw = outPointMs - inPointMs;
    if (raw <= 0) return 0;
    if (speed <= 0) return raw;
    return (raw / speed).round();
  }

  int get timelineEndMs => timelineStartMs + timelineDurationMs;

  /// Get effective source time at a given timeline position, accounting for velocity curve.
  int sourceTimeAt(int timelineMs) {
    if (timelineMs < timelineStartMs) return inPointMs;
    if (timelineMs >= timelineEndMs) return outPointMs;
    final localMs = timelineMs - timelineStartMs;
    final duration = timelineDurationMs;
    if (duration <= 0) return inPointMs;
    return inPointMs + velocity.mapTime(localMs, duration);
  }

  ClipModel copyWith({
    String? sourcePath,
    ClipSourceType? sourceType,
    int? inPointMs,
    int? outPointMs,
    int? timelineStartMs,
    double? speed,
    TransitionType? transitionIn,
    TransitionType? transitionOut,
    String? textContent,
    String? fontFamily,
    double? volume,
    VelocityModel? velocity,
  }) =>
      ClipModel(
        id: id,
        sourcePath: sourcePath ?? this.sourcePath,
        sourceType: sourceType ?? this.sourceType,
        inPointMs: inPointMs ?? this.inPointMs,
        outPointMs: outPointMs ?? this.outPointMs,
        timelineStartMs: timelineStartMs ?? this.timelineStartMs,
        speed: speed ?? this.speed,
        transitionIn: transitionIn ?? this.transitionIn,
        transitionOut: transitionOut ?? this.transitionOut,
        textContent: textContent ?? this.textContent,
        fontFamily: fontFamily ?? this.fontFamily,
        volume: volume ?? this.volume,
        velocity: velocity ?? this.velocity,
      );

  (ClipModel left, ClipModel right)? split(int atTimelineMs) {
    if (atTimelineMs <= timelineStartMs + 200) return null;
    if (atTimelineMs >= timelineEndMs - 200) return null;

    final splitOffsetMs = ((atTimelineMs - timelineStartMs) * speed).round();
    final splitSourceMs = inPointMs + splitOffsetMs;

    final left = copyWith(outPointMs: splitSourceMs);
    final right = ClipModel(
      id: IdGenerator.next(),
      sourcePath: sourcePath,
      sourceType: sourceType,
      inPointMs: splitSourceMs,
      outPointMs: outPointMs,
      timelineStartMs: atTimelineMs,
      speed: speed,
      textContent: textContent,
      fontFamily: fontFamily,
      volume: volume,
      velocity: velocity,
    );
    return (left, right);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourcePath': sourcePath,
        'sourceType': sourceType.name,
        'inPointMs': inPointMs,
        'outPointMs': outPointMs,
        'timelineStartMs': timelineStartMs,
        'speed': speed,
        'transitionIn': transitionIn.name,
        'transitionOut': transitionOut.name,
        'textContent': textContent,
        'fontFamily': fontFamily,
        'volume': volume,
        'velocity': velocity.toJson(),
      };

  factory ClipModel.fromJson(Map<String, dynamic> json) => ClipModel(
        id: json['id'] as String? ?? '',
        sourcePath: json['sourcePath'] as String? ?? '',
        sourceType: ClipSourceType.values.byName(json['sourceType'] as String? ?? 'video'),
        inPointMs: (json['inPointMs'] as num?)?.toInt() ?? 0,
        outPointMs: (json['outPointMs'] as num?)?.toInt() ?? 5000,
        timelineStartMs: (json['timelineStartMs'] as num?)?.toInt() ?? 0,
        speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
        transitionIn: TransitionType.values.byName(json['transitionIn'] as String? ?? 'none'),
        transitionOut: TransitionType.values.byName(json['transitionOut'] as String? ?? 'none'),
        textContent: json['textContent'] as String?,
        fontFamily: json['fontFamily'] as String?,
        volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
        velocity: json['velocity'] != null
            ? VelocityModel.fromJson(json['velocity'] as Map<String, dynamic>)
            : const VelocityModel(),
      );

  @override
  List<Object?> get props => [
        id, sourcePath, sourceType, inPointMs, outPointMs,
        timelineStartMs, speed, transitionIn, transitionOut,
        textContent, fontFamily, volume, velocity
      ];
}
