import 'dart:math';

/// Simple energy-based beat detection for audio analysis.
class BeatDetectionService {
  /// Detect beat timestamps (in ms) from audio amplitude data.
  /// [sampleRate] in Hz, [samples] is PCM amplitude data.
  List<int> detectBeats(List<double> samples, int sampleRate, {double threshold = 0.5}) {
    final beats = <int>[];
    final windowSize = sampleRate ~/ 10; // 100ms windows
    final energyHistory = <double>[];
    const historySize = 43; // ~4.3 seconds of history

    for (int i = 0; i < samples.length; i += windowSize) {
      final end = (i + windowSize).clamp(0, samples.length);
      double energy = 0;
      for (int j = i; j < end; j++) {
        energy += samples[j] * samples[j];
      }
      energy /= (end - i);
      energy = sqrt(energy);

      energyHistory.add(energy);
      if (energyHistory.length > historySize) energyHistory.removeAt(0);

      if (energyHistory.length >= historySize) {
        final avgEnergy = energyHistory.reduce((a, b) => a + b) / energyHistory.length;
        final variance = energyHistory.map((e) => (e - avgEnergy) * (e - avgEnergy))
            .reduce((a, b) => a + b) / energyHistory.length;
        final c = (-0.0025714 * variance) + 1.5142857;
        final beatThreshold = c * avgEnergy;

        if (energy > beatThreshold && energy > threshold) {
          final timeMs = (i * 1000 ~/ sampleRate);
          if (beats.isEmpty || timeMs - beats.last > 200) {
            beats.add(timeMs);
          }
        }
      }
    }
    return beats;
  }
}
