import '../../models/post.dart';
import '../../models/user.dart';

class ProfileState {
  final AppUser user;
  final List<Post> posts;
  final bool isLoading;
  final String? errorMessage;
  final bool isCurrentUser;

  const ProfileState({
    required this.user,
    this.posts = const [],
    this.isLoading = true,
    this.errorMessage,
    this.isCurrentUser = false,
  });

  ProfileState copyWith({
    AppUser? user,
    List<Post>? posts,
    bool? isLoading,
    String? errorMessage,
    bool? isCurrentUser,
  }) {
    return ProfileState(
      user: user ?? this.user,
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}
