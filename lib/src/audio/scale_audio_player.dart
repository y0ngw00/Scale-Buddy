import 'package:flutter/services.dart';

class ScaleAudioPlayer {
  static const MethodChannel _channel = MethodChannel('scale_buddy/audio');

  Future<void> playTone({
    required double frequency,
    required Duration duration,
  }) {
    return _channel.invokeMethod<void>('playTone', {
      'frequency': frequency,
      'durationMs': duration.inMilliseconds,
    });
  }

  Future<void> dispose() {
    return _channel.invokeMethod<void>('stop');
  }
}
