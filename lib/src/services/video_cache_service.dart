import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoCacheService {
  VideoCacheService._();
  static final VideoCacheService instance = VideoCacheService._();

  static const String _kVideoCacheKey = 'video_cache_key';

  final CacheManager _cacheManager = CacheManager(
    Config(
      _kVideoCacheKey,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: _kVideoCacheKey),
      fileService: HttpFileService(),
    ),
  );

  /// Returns the local cached video file for a network URL.
  /// If the URL is already a local path, it directly returns the File object.
  Future<File> getFile(String url) async {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      try {
        final File file = await _cacheManager.getSingleFile(url);
        return file;
      } catch (e) {
        debugPrint('VideoCacheService: Failed to cache video: $e');
        rethrow;
      }
    }
    return File(url);
  }
  
  /// Helper to check if a network URL is already cached.
  Future<bool> isCached(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return true;
    }
    final fileInfo = await _cacheManager.getFileFromCache(url);
    return fileInfo != null;
  }
}
