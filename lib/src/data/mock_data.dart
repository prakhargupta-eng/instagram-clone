import '../models/post.dart';
import '../models/story.dart';
import '../models/user.dart';

class MockDatabase {
  MockDatabase._();

  /// Empty mock database tables (all production data is loaded dynamically from REST backend API)
  static final List<AppUser> users = <AppUser>[];
  static final List<Post> posts = <Post>[];
  static final List<Story> stories = <Story>[];

  /// Test helper users
  static final AppUser alice = AppUser(
    id: 'u1',
    username: 'alice',
    fullName: 'Alice Chen',
    email: 'alice@example.com',
    bio: '',
    avatarUrl: '',
  );

  static final AppUser marco = AppUser(
    id: 'u2',
    username: 'marco',
    fullName: 'Marco Silva',
    email: 'marco@example.com',
    bio: '',
    avatarUrl: '',
  );

  static final AppUser zoe = AppUser(
    id: 'u3',
    username: 'zoe',
    fullName: 'Zoe Vance',
    email: 'zoe@example.com',
    bio: '',
    avatarUrl: '',
  );

  /// Skeleton UI loading placeholders (used strictly by Skeletonizer during API fetch)
  static final List<Post> skeletonPosts = List.generate(
    6,
    (index) => Post(
      id: 'sk_$index',
      author: AppUser(
        id: 'sk_u_$index',
        username: 'username_placeholder',
        fullName: 'Loading User Name',
        email: '',
        bio: 'Loading bio placeholder text line...',
        avatarUrl: '',
      ),
      imageUrl: '',
      caption: 'Loading caption text placeholder line for skeleton loader widget...',
      createdAt: DateTime.now(),
      likedBy: const ['u1', 'u2'],
      comments: [
        Comment(
          id: 'sk_c_$index',
          author: AppUser(
            id: 'sk_u_c_$index',
            username: 'commenter',
            fullName: 'Commenter',
            email: '',
            bio: '',
            avatarUrl: '',
          ),
          text: 'Loading comment text placeholder...',
          createdAt: DateTime.now(),
        ),
      ],
    ),
  );

  static final List<Story> skeletonStories = List.generate(
    6,
    (index) => Story(
      id: 'sk_s_$index',
      user: AppUser(
        id: 'sk_su_$index',
        username: 'user_$index',
        fullName: 'User',
        email: '',
        bio: '',
        avatarUrl: '',
      ),
      imageUrl: '',
    ),
  );

  static final List<Comment> skeletonComments = List.generate(
    4,
    (index) => Comment(
      id: 'sk_cm_$index',
      author: AppUser(
        id: 'sk_cmu_$index',
        username: 'user_commenter',
        fullName: 'User Commenter',
        email: '',
        bio: '',
        avatarUrl: '',
      ),
      text: 'Loading comment text placeholder line...',
      createdAt: DateTime.now(),
    ),
  );
}
