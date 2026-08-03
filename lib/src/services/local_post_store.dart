import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';
import '../models/user.dart';

class LocalPostStore {
  LocalPostStore._();

  static final LocalPostStore instance = LocalPostStore._();

  static const _prefsKey = 'local_posts_v1';

  Future<List<Post>> load({required AppUser currentUser}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final item in list.cast<Map<String, dynamic>>())
          Post(
            id: item['id'] as String,
            author: currentUser,
            imageUrl: item['path'] as String,
            caption: (item['caption'] as String?) ?? '',
            createdAt: DateTime.parse(item['createdAt'] as String),
          ),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> add(Post post) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    List<dynamic> list = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        list = jsonDecode(raw) as List;
      } catch (_) {}
    }
    list.insert(
      0,
      {
        'id': post.id,
        'path': post.imageUrl,
        'caption': post.caption,
        'createdAt': post.createdAt.toIso8601String(),
      },
    );
    await prefs.setString(_prefsKey, jsonEncode(list));
  }

  Future<void> delete(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .where((item) => item['id'] != postId)
          .toList();
      await prefs.setString(_prefsKey, jsonEncode(list));
    } catch (_) {}
  }

  static bool isLocalPath(String path) =>
      path.startsWith('/') || path.startsWith('file://');
}
