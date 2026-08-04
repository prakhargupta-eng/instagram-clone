import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../constants.dart';

class MusicPickerScreen extends StatefulWidget {
  const MusicPickerScreen({super.key});

  @override
  State<MusicPickerScreen> createState() => _MusicPickerScreenState();
}

class _MusicPickerScreenState extends State<MusicPickerScreen> {
  final _controller = TextEditingController();
  List<dynamic> _songs = [];
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller.text = 'Trending';
    _searchMusic('Trending');
  }

  @override
  void dispose() {
    _controller.dispose();
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
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(term)}&entity=song&limit=10');
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 10));
      final response = await request.close().timeout(const Duration(seconds: 10));

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Select Music',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
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
                        const Icon(Icons.error_outline, size: 36, color: AppColors.error),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                    final trackName = song['trackName'] as String? ?? 'Unknown Song';
                    final artistName = song['artistName'] as String? ?? 'Unknown Artist';
                    final artworkUrl = song['artworkUrl60'] as String?;

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
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      onTap: () {
                        Navigator.of(context).pop('$trackName - $artistName');
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
