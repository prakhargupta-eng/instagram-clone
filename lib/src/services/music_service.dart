import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

class MusicService {
  MusicService._() {
    _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      _triggerReplayBreak();
    });
  }
  static final MusicService instance = MusicService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentUrl;
  bool _isMuted = false;
  bool _userPaused = false;

  Timer? _replaylistTimer;
  StreamSubscription? _completeSubscription;

  AudioPlayer get player => _audioPlayer;
  String? get currentUrl => _currentUrl;
  bool get isMuted => _isMuted;
  bool get userPaused => _userPaused;

  Stream<PlayerState> get onPlayerStateChanged => _audioPlayer.onPlayerStateChanged;
  Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;
  Stream<Duration> get onDurationChanged => _audioPlayer.onDurationChanged;

  Future<void> play(String url) async {
    if (_currentUrl == url && _audioPlayer.state == PlayerState.playing) {
      return;
    }
    _replaylistTimer?.cancel();
    await _audioPlayer.stop();
    _currentUrl = url;
    await _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
    await _audioPlayer.play(UrlSource(url));
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    if (_currentUrl != null) {
      await _audioPlayer.resume();
    }
  }

  Future<void> stop() async {
    _replaylistTimer?.cancel();
    await _audioPlayer.stop();
    _currentUrl = null;
  }

  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    await _audioPlayer.setVolume(muted ? 0.0 : 1.0);
  }

  Future<void> toggleMuted() async {
    await setMuted(!_isMuted);
  }

  // --- Post Music Logic (Shared between Feed and Profile Detail Screens) ---
  
  Future<void> playPostMusic(String? musicStr, {String? previewUrl}) async {
    _replaylistTimer?.cancel();

    if (musicStr == null || musicStr.isEmpty) {
      await stop();
      return;
    }

    String url = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'; // Fallback
    if (previewUrl != null && previewUrl.isNotEmpty) {
      url = previewUrl;
    } else if (musicStr.contains('|\$\$\$|')) {
      final parts = musicStr.split('|\$\$\$|');
      if (parts.length > 1 && parts[1].isNotEmpty) {
        url = parts[1];
      }
    }

    _userPaused = false;
    await play(url);
  }

  Future<void> pausePostMusic() async {
    _userPaused = true;
    _replaylistTimer?.cancel();
    await pause();
  }

  Future<void> resumePostMusic() async {
    _userPaused = false;
    if (_currentUrl != null) {
      await resume();
    }
  }

  void _triggerReplayBreak() {
    _replaylistTimer?.cancel();
    if (!_userPaused && _currentUrl != null) {
      final breakSeconds = 3 + math.Random().nextInt(8); // 3 to 10 seconds
      final urlToReplay = _currentUrl;
      _replaylistTimer = Timer(Duration(seconds: breakSeconds), () async {
        if (!_userPaused && _currentUrl == urlToReplay) {
          await play(urlToReplay!);
        }
      });
    }
  }

  void dispose() {
    _replaylistTimer?.cancel();
    _completeSubscription?.cancel();
    _audioPlayer.dispose();
  }
}
