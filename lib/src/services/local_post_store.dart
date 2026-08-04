import 'dart:convert';
import 'package:hive/hive.dart';

import '../models/post.dart';
import '../models/user.dart';

class LocalPostStore {
  LocalPostStore._();

  static final LocalPostStore instance = LocalPostStore._();

  static const _boxName = 'posts_box';
  static const _prefsKey = 'local_posts_v1';

  Future<List<Post>> load({required AppUser currentUser}) async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get(_prefsKey) as String?;
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return [
        for (final item in list.cast<Map<String, dynamic>>())
          Post.fromJson(item, author: currentUser)
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> add(Post post) async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get(_prefsKey) as String?;
      List<dynamic> list = [];
      if (raw != null && raw.isNotEmpty) {
        try {
          list = jsonDecode(raw) as List;
        } catch (_) {}
      }
      list.insert(0, post.toJson());
      await box.put(_prefsKey, jsonEncode(list));
    } catch (_) {}
  }

  Future<void> delete(String postId) async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get(_prefsKey) as String?;
      if (raw == null || raw.isEmpty) return;
      final list = (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .where((item) => item['id'] != postId)
          .toList();
      await box.put(_prefsKey, jsonEncode(list));
    } catch (_) {}
  }

  Future<void> saveAll(List<Post> posts) async {
    try {
      final box = await Hive.openBox(_boxName);
      final list = posts.map((p) => p.toJson()).toList();
      await box.put(_prefsKey, jsonEncode(list));
    } catch (_) {}
  }

  static bool isLocalPath(String path) =>
      path.startsWith('/') || path.startsWith('file://');
}
