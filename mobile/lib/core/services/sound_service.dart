import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SoundType {
  move,
  capture,
  dame,
  oops,
  coudou,
  win,
  fail,
}

class SoundService {
  static final SoundService _instance = SoundService._();
  static SoundService get instance => _instance;
  SoundService._();

  final Map<SoundType, AudioPlayer> _players = {};
  bool _muted = false;
  bool _initialized = false;

  bool get isMuted => _muted;

  static const Map<SoundType, String> _files = {
    SoundType.move: 'sounds/move.mp3',
    SoundType.capture: 'sounds/coinpickup.mp3',
    SoundType.dame: 'sounds/levelup.mp3',
    SoundType.oops: 'sounds/wrong.mp3',
    SoundType.coudou: 'sounds/crowd.mp3',
    SoundType.win: 'sounds/fanfare.mp3',
    SoundType.fail: 'sounds/fail.mp3',
  };

  static const Map<SoundType, double> _volumes = {
    SoundType.move: 0.55,
    SoundType.capture: 0.55,
    SoundType.dame: 0.55,
    SoundType.oops: 0.55,
    SoundType.coudou: 0.7,
    SoundType.win: 0.7,
    SoundType.fail: 0.7,
  };

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    _muted = prefs.getBool('sound_muted') ?? false;

    for (final type in SoundType.values) {
      final player = AudioPlayer();
      await player.setSource(AssetSource(_files[type]!));
      await player.setVolume(_volumes[type] ?? 0.55);
      await player.setReleaseMode(ReleaseMode.stop);
      _players[type] = player;
    }
  }

  Future<void> play(SoundType type) async {
    if (_muted) return;
    final player = _players[type];
    if (player == null) return;
    try {
      await player.stop();
      await player.seek(Duration.zero);
      await player.resume();
    } catch (_) {}
  }

  Future<void> setMuted(bool value) async {
    _muted = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_muted', _muted);
  }

  Future<void> toggleMute() async {
    await setMuted(!_muted);
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
    _initialized = false;
  }
}
