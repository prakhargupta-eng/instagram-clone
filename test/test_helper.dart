import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int textureId) async {}

  @override
  Future<int?> create(DataSource dataSource) async {
    return 1;
  }

  @override
  Future<void> setLooping(int textureId, bool looping) async {}

  @override
  Future<void> play(int textureId) async {}

  @override
  Future<void> pause(int textureId) async {}

  @override
  Future<void> setVolume(int textureId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {}

  @override
  Future<void> seekTo(int textureId, Duration position) async {}

  @override
  Future<Duration> getPosition(int textureId) async {
    return Duration.zero;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return Stream.value(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 10),
        size: const Size(1920, 1080),
      ),
    );
  }

  @override
  Widget buildView(int textureId) {
    return const SizedBox.shrink();
  }
}

void setupVideoPlayerMock() {
  VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
}

Future<void> setupTestHive() async {
  setupVideoPlayerMock();
}

Future<void> resetTestDatabase() async {}
