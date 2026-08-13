import '../models/post.dart';
import '../models/user.dart';

class LocalPostStore {
  LocalPostStore._();

  static final LocalPostStore instance = LocalPostStore._();

  Future<List<Post>> load({required AppUser currentUser}) async {
    return [];
  }

  Future<void> add(Post post) async {}

  Future<void> delete(String postId) async {}

  Future<void> saveAll(List<Post> posts) async {}

  static bool isLocalPath(String path) =>
      !path.startsWith('http://') && !path.startsWith('https://');
}
