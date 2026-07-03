import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

/// Plays the scan-success feedback: a short beep sound + a device vibration.
///
/// ## Why this exists (first-principles)
///
/// Flutter ships two built-in feedback APIs that look sufficient but are
/// **broken on Android in practice**:
///
/// 1. `SystemSound.play(SystemSoundType.click)` — a known, open Flutter bug
///    ([flutter/flutter#57531]). The docs say "if the sound is not present
///    on the system, the call is ignored", and Android devices ship no
///    matching system click resource, so the call is a silent no-op.
///
/// 2. `HapticFeedback.vibrate()` / `heavyImpact()` — these route through
///    Flutter's platform-channel `Vibrator` wrapper, which several OEM ROMs
///    (notably Xiaomi/MIUI) ignore or throttle. It is also gated behind the
///    device's system "vibrate on tap" setting, which MIUI turns off by
///    default.
///
/// This service bypasses both abstractions and talks to the platform
/// directly:
///   - **Sound**: `audioplayers` opens a real `AudioTrack` and plays a
///     bundled `scan_beep.wav` (880 Hz, 150 ms) — works on every Android
///     device with a media volume > 0.
///   - **Haptic**: `vibration` calls the Android `Vibrator` service with an
///     explicit duration, which is honoured even when MIUI's "tap" haptics
///    are disabled (it only needs the `VIBRATE` permission).
///
/// [flutter/flutter#57531]: https://github.com/flutter/flutter/issues/57531
class ScanFeedback {
  ScanFeedback._();

  static final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop)
    ..setVolume(1.0);

  /// Whether the device has a vibrator. Cached after the first probe.
  /// Null until probed; false if the probe fails or returns false.
  static bool? _hasVibrator;

  /// Plays the success feedback.
  ///
  /// Safe to call from any isolate; failures (no vibrator, muted player) are
  /// swallowed so a scan never breaks because feedback failed. Sound and
  /// vibration are fired concurrently (neither awaits the other) so the user
  /// perceives them as a single instantaneous cue.
  static Future<void> playSuccess() async {
    debugPrint('[ScanFeedback] playSuccess invoked');
    // Vibration — fire-and-forget, but probe capability once.
    unawaited(_vibrate());

    // Sound — play the bundled beep.
    try {
      await _player.resume();
      await _player.play(AssetSource('sounds/scan_beep.wav'));
      debugPrint('[ScanFeedback] beep played');
    } catch (e) {
      debugPrint('[ScanFeedback] sound failed: $e');
    }
  }

  static Future<void> _vibrate() async {
    try {
      _hasVibrator ??= await Vibration.hasVibrator();
      if (_hasVibrator != true) {
        debugPrint('[ScanFeedback] device has no vibrator, skipping');
        return;
      }
      // 200ms is a short, unmistakable buzz. amplitude -1 = default.
      await Vibration.vibrate(duration: 200);
      debugPrint('[ScanFeedback] vibration fired');
    } catch (e) {
      debugPrint('[ScanFeedback] vibration failed: $e');
    }
  }

  /// Releases the audio player resources (call on app dispose if desired).
  static Future<void> dispose() async {
    await _player.dispose();
  }
}
