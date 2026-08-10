import '../models/post.dart';
import '../models/user.dart';
import 'sql_database_helper.dart';

class LocalPostStore {
  LocalPostStore._();

  static final LocalPostStore instance = LocalPostStore._();

  Future<List<Post>> load({required AppUser currentUser}) async {
    try {
      return await SqlDatabaseHelper.instance.getLocalPosts(currentUser);
    } catch (_) {
      return [];
    }
  }

  Future<void> add(Post post) async {
    try {
      await SqlDatabaseHelper.instance.insertLocalPost(post);
    } catch (_) {}
  }

  Future<void> delete(String postId) async {
    try {
      await SqlDatabaseHelper.instance.deleteLocalPost(postId);
    } catch (_) {}
  }

  Future<void> saveAll(List<Post> posts) async {
    try {
      await SqlDatabaseHelper.instance.saveAllLocalPosts(posts);
    } catch (_) {}
  }

  static bool isLocalPath(String path) =>
      !path.startsWith('http://') && !path.startsWith('https://');
}
