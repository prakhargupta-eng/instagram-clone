import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../constants.dart';
import '../../services/music_service.dart';

class MusicPickerScreen extends StatefulWidget {
  const MusicPickerScreen({super.key});

  @override
  State<MusicPickerScreen> createState() => _MusicPickerScreenState();
}

class _MusicPickerScreenState extends State<MusicPickerScreen> {
  final _controller = TextEditingController();
  dynamic _selectedSong;
  List<dynamic> _songs = [];
  bool _loading = false;
  String? _errorMessage;
  StreamSubscription<PlayerState>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _controller.text = 'Trending';
    _searchMusic('Trending');
    _stateSubscription = MusicService.instance.onPlayerStateChanged.listen((
      state,
    ) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _stateSubscription?.cancel();
    MusicService.instance.stop();
    super.dispose();
  }

  Future<void> _searchMusic(String query) async {
    final term = query.trim().isEmpty ? 'Trending' : query.trim();

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(term)}&entity=song&limit=10',
      );
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 10));
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];

        if (mounted) {
          setState(() {
            _songs = results;
            _loading = false;
          });
        }
      } else {
        throw HttpException('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _songs = [];
          _loading = false;
          _errorMessage = _getFriendlyError(e);
        });
      }
    } finally {
      client.close();
    }
  }

  String _getFriendlyError(dynamic e) {
    if (e is SocketException) {
      return 'No internet connection. Please check your network.';
    } else if (e is HttpException) {
      return e.message;
    } else if (e is FormatException) {
      return 'Received invalid response from server.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  void _togglePlayPause(dynamic song) async {
    final previewUrl = song['previewUrl'] as String?;
    if (previewUrl == null || previewUrl.isEmpty) return;

    if (MusicService.instance.player.state == PlayerState.playing &&
        MusicService.instance.currentUrl == previewUrl) {
      await MusicService.instance.pause();
      setState(() {});
    } else {
      await MusicService.instance.play(previewUrl);
      setState(() {});
    }
  }

  void _selectAndPlay(dynamic song) async {
    setState(() {
      _selectedSong = song;
    });
    final previewUrl = song['previewUrl'] as String?;
    if (previewUrl == null || previewUrl.isEmpty) {
      await MusicService.instance.stop();
      return;
    }

    await MusicService.instance.play(previewUrl);
  }

  void _confirmSelection(dynamic song) {
    MusicService.instance.stop();
    final trackName = song['trackName'] as String? ?? 'Unknown Song';
    final artistName = song['artistName'] as String? ?? 'Unknown Artist';
    final previewUrl = song['previewUrl'] as String? ?? '';
    Navigator.of(context).pop('$trackName - $artistName');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            MusicService.instance.stop();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Select Music',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_selectedSong != null)
            IconButton(
              icon: const Icon(Icons.check, color: AppColors.primary),
              onPressed: () {
                _confirmSelection(_selectedSong);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _controller,
                onChanged: _searchMusic,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search for music',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _controller.clear();
                            _searchMusic('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 36,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_songs.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    final trackName =
                        song['trackName'] as String? ?? 'Unknown Song';
                    final artistName =
                        song['artistName'] as String? ?? 'Unknown Artist';
                    final artworkUrl = song['artworkUrl60'] as String?;
                    final previewUrl = song['previewUrl'] as String?;
                    final isSelected =
                        _selectedSong != null &&
                        (_selectedSong['trackId'] == song['trackId'] ||
                            (_selectedSong['trackName'] == song['trackName'] &&
                                _selectedSong['artistName'] ==
                                    song['artistName']));
                    final isCurrentPlaying =
                        MusicService.instance.player.state ==
                            PlayerState.playing &&
                        isSelected &&
                        previewUrl == MusicService.instance.currentUrl;

                    return ListTile(
                      leading: artworkUrl != null && artworkUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                artworkUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, e, st) => Container(
                                  width: 40,
                                  height: 40,
                                  color: AppColors.border,
                                  child: const Icon(Icons.music_note, size: 20),
                                ),
                              ),
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.music_note, size: 20),
                            ),
                      title: Text(
                        trackName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (previewUrl != null && previewUrl.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                isCurrentPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: 28,
                              ),
                              onPressed: () {
                                if (isSelected) {
                                  _togglePlayPause(song);
                                } else {
                                  _selectAndPlay(song);
                                }
                              },
                            ),
                          if (isSelected)
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 28,
                              ),
                              onPressed: () {
                                _confirmSelection(song);
                              },
                            ),
                        ],
                      ),
                      onTap: () {
                        if (isSelected) {
                          _togglePlayPause(song);
                        } else {
                          _selectAndPlay(song);
                        }
                      },
                    );
                  },
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text(
                    'No songs found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
