import 'package:flutter/material.dart';
import '../../../adaptive_colors.dart';
import '../../../services/feed_service.dart';
import '../widgets/postTitle.dart';
import 'bookmarks_view_model.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key, required this.feedService});

  final FeedService feedService;

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late final BookmarksViewModel _viewModel;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _viewModel = BookmarksViewModel(feedService: widget.feedService);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    // Fetch bookmarks when screen is opened
    _viewModel.loadBookmarks();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_viewModel.isFetchingMore && _viewModel.hasMore) {
        _viewModel.loadBookmarks(loadMore: true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        title: const Text(
          'Saved',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.bookmarks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.error != null && _viewModel.bookmarks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _viewModel.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _viewModel.loadBookmarks(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final bookmarks = _viewModel.bookmarks;

          if (bookmarks.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => _viewModel.loadBookmarks(loadMore: false),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 150),
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No bookmarks yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => _viewModel.loadBookmarks(loadMore: false),
                child: GridView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 4, bottom: 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) => PostTile(
                    feedService: widget.feedService,
                    post: bookmarks[index],
                    posts: bookmarks,
                    heroTag: 'bookmarks_${bookmarks[index].id}',
                  ),
                ),
              ),
              if (_viewModel.isFetchingMore)
                const Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
