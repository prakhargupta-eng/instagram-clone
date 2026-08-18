import 'package:flutter/foundation.dart';
import '../../../models/post.dart';
import '../../../services/feed_service.dart';

class BookmarksViewModel extends ChangeNotifier {
  final FeedService _feedService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isFetchingMore = false;
  bool get isFetchingMore => _isFetchingMore;

  String? _error;
  String? get error => _error;

  List<Post> get bookmarks => _feedService.bookmarkedPosts;
  bool get hasMore => _feedService.bookmarksHasMore;

  BookmarksViewModel({required FeedService feedService})
      : _feedService = feedService {
    _feedService.addListener(_onFeedServiceChanged);
  }

  void _onFeedServiceChanged() {
    // Notify the view whenever the feed service (and thus bookmarks) updates
    notifyListeners();
  }

  Future<void> loadBookmarks({bool loadMore = false}) async {
    if (loadMore && !hasMore) return;
    if (loadMore && _isFetchingMore) return;
    if (!loadMore && _isLoading) return;

    if (loadMore) {
      _isFetchingMore = true;
    } else {
      _isLoading = true;
    }
    _error = null;
    notifyListeners();

    try {
      await _feedService.fetchBookmarks(loadMore: loadMore);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (loadMore) {
        _isFetchingMore = false;
      } else {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _feedService.removeListener(_onFeedServiceChanged);
    super.dispose();
  }
}
