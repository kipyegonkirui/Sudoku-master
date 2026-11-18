import 'package:flutter/services.dart';

/// Central place for game feedback. Vibration works now. Sound effects are
/// placeholders, to be connected to an audio player later.
class SudokuFeedback {
  bool soundOn = true;
  bool vibrationOn = true;

  void correct() {
    _haptic(HapticFeedback.lightImpact);
    _sound('correct');
  }

  void mistake() {
    _haptic(HapticFeedback.heavyImpact);
    _sound('mistake');
  }

  void unitComplete() {
    _haptic(HapticFeedback.mediumImpact);
    _sound('unit_complete');
  }

  void hint() {
    _haptic(HapticFeedback.selectionClick);
    _sound('hint');
  }

  void win() {
    _haptic(HapticFeedback.heavyImpact);
    _sound('win');
  }

  void _haptic(Future<void> Function() effect) {
    if (vibrationOn) effect();
  }

  void _sound(String name) {
    if (!soundOn) return;
    // TODO: play assets/audio/$name.mp3 once the audio package is added.
  }
}