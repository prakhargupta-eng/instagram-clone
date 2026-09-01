import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/user.dart';
import '../../repositories/post_repository.dart';
import '../../repositories/user_repository.dart';
import '../../services/auth_service.dart';
import '../../services/feed_service.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserRepository _userRepository = UserRepository.instance;
  final PostRepository _postRepository = PostRepository.instance;
  final AuthService? _authService;
  final FeedService _feedService;
  final AppUser _initialUser;

  ProfileCubit({
    required AppUser initialUser,
    required FeedService feedService,
    AuthService? authService,
  })  : _initialUser = initialUser,
        _feedService = feedService,
        _authService = authService,
        super(ProfileState(
          user: initialUser,
          isCurrentUser: authService?.currentUser?.id == initialUser.id,
        ));

  Future<void> fetchProfile() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final bool isCurrent = state.isCurrentUser;
    final String? targetId = isCurrent ? null : _initialUser.id;
    
    final userResult = await _userRepository.getUserProfile(targetId);
    
    await userResult.fold(
      (failure) async {
        emit(state.copyWith(isLoading: false, errorMessage: failure.message));
      },
      (fetchedUser) async {
        _feedService.updateUser(fetchedUser);
        if (isCurrent) {
          _authService?.syncCurrentUser(fetchedUser);
        }

        final currentUserId = _authService?.currentUser?.id ?? '';
        final isFollowing = _feedService.isFollowing(currentUserId, fetchedUser.id);
        
        if (fetchedUser.isPrivate && !isCurrent && !isFollowing) {
          emit(state.copyWith(user: fetchedUser, isLoading: false));
          return;
        }

        final postsResult = await _postRepository.getUserPosts(targetId);
        
        postsResult.fold(
          (failure) {
            emit(state.copyWith(
              user: fetchedUser,
              isLoading: false,
              errorMessage: failure.message,
            ));
          },
          (posts) {
            emit(state.copyWith(
              user: fetchedUser,
              posts: posts,
              isLoading: false,
            ));
          },
        );
      },
    );
  }

  Future<void> refreshProfile() async {
    await fetchProfile();
    
    final currentUserId = _authService?.currentUser?.id ?? '';
    final isFollowing = _feedService.isFollowing(currentUserId, state.user.id);
    
    if (!state.user.isPrivate || state.isCurrentUser || isFollowing) {
      await _feedService.refreshFeed();
    }
  }
}
