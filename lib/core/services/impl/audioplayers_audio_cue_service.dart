import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../constants/app_constants.dart';
import '../audio_cue_service.dart';

/// [AudioPlayers]-backed [AudioCueService].
///
/// Each cue has a dedicated [AudioPlayer] to support overlapping playback
/// (low-latency mixing mode).
class AudioplayersAudioCueService implements AudioCueService {
  AudioplayersAudioCueService() {
    AudioPlayer.global.setAudioContext(
      const AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioMode: AndroidAudioMode.normal,
        ),
      ),
    );
  }

  final Map<AudioCueEvent, AudioPlayer> _players = {};

  /// Returns (and lazily creates) the player for [event].
  AudioPlayer _player(AudioCueEvent event) =>
      _players.putIfAbsent(event, AudioPlayer.new);

  @override
  Future<void> play(AudioCueEvent event) async {
    final source = AssetSource(_assetPath(event));
    try {
      await _player(event).play(source);
    } catch (e) {
      debugPrint('[AudioCue] Failed to play $event: $e');
    }
  }

  @override
  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  String _assetPath(AudioCueEvent event) {
    switch (event) {
      case AudioCueEvent.beep:
        return AppAudioAssets.beep.replaceFirst('assets/', '');
      case AudioCueEvent.success:
        return AppAudioAssets.success.replaceFirst('assets/', '');
      case AudioCueEvent.modeSwitch:
        return AppAudioAssets.modeSwitch.replaceFirst('assets/', '');
      case AudioCueEvent.error:
        return AppAudioAssets.error.replaceFirst('assets/', '');
    }
  }
}
