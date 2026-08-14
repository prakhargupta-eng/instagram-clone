import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../app.dart';
import '../../constants.dart';
import '../../data/mock_data.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/feed_service.dart';
import '../../widgets/avatar.dart';
import '../../widgets/ui_skeletons.dart';

class CommentsSheet extends StatefulWidget {
  const CommentsSheet({
    super.key,
    required this.feedService,
    required this.post,
    required this.currentUser,
    this.isDark,
    this.onCommentAdded,
  });

  final FeedService feedService;
  final Post post;
  final AppUser currentUser;
  final bool? isDark;
  final void Function(Comment)? onCommentAdded;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  late final TextEditingController _controller = TextEditingController();
  bool _hasText = false;
  late Post _localPost;

  @override
  void initState() {
    super.initState();
    _localPost = widget.post;
    _controller.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDark ?? isDark(context);
    final dividerColor = dark ? Colors.white12 : AppColors.border;
    final textColor = dark ? Colors.white : AppColors.textPrimary;
    final subTextColor = dark
        ? Colors.white54
        : AppColors.textSecondary;
    final sheetBgColor = dark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputBgColor = dark
        ? const Color(0xFF2E2E2E)
        : AppColors.background;

    return Container(
      color: sheetBgColor,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: dark ? Colors.white24 : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.comments,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: textColor,
            ),
          ),
          Divider(height: 16, color: dividerColor),
          Flexible(
            child: ListenableBuilder(
              listenable: widget.feedService,
              builder: (context, _) {
                final post =
                    widget.feedService.getPost(widget.post.id) ?? _localPost;
                final isLoading = widget.feedService.isLoading;
                if (isLoading && post.comments.isEmpty) {
                  return const Skeletonizer(
                    enabled: true,
                    enableSwitchAnimation: true,
                    child: CommentsSkeleton(),
                  );
                }
                final displayComments = post.comments;

                if (displayComments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      AppStrings.noCommentsYet,
                      style: TextStyle(color: subTextColor),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: displayComments.length,
                  itemBuilder: (context, index) {
                    final comment = displayComments[index];
                    return SlideFadeTransitionItem(
                      index: index,
                      createdAt: comment.createdAt,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Avatar(url: comment.author.avatarUrl, radius: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.author.username,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    comment.text,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat(
                                      'MMM d, h:mm a',
                                    ).format(comment.createdAt),
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1, color: dividerColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Avatar(url: widget.currentUser.avatarUrl, radius: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: AppStrings.addAComment,
                      hintStyle: TextStyle(color: subTextColor),
                      filled: true,
                      fillColor: inputBgColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                        borderSide: BorderSide(color: dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                        borderSide: BorderSide(color: dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                        borderSide: BorderSide(
                          color: dark
                              ? Colors.white38
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: _hasText ? _submit : null,
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _hasText ? 1.0 : 0.4,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 250),
                    scale: _hasText ? 1.0 : 0.85,
                    curve: Curves.easeOutBack,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: AppColors.primary),
                      onPressed: _hasText
                          ? () => _submit(_controller.text)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).viewPadding.bottom > 0 ? 0 : 8,
          ),
        ],
      ),
    );
  }

  void _submit(String text) {
    if (text.trim().isEmpty) return;
    widget.feedService.addComment(widget.post.id, widget.currentUser, text);
    
    final newComment = Comment(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      author: widget.currentUser,
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    
    final comments = List<Comment>.of(_localPost.comments);
    comments.add(newComment);
    
    setState(() {
      _localPost = _localPost.copyWith(comments: comments);
    });
    
    widget.onCommentAdded?.call(newComment);
    
    _controller.clear();
    FocusScope.of(context).unfocus();
  }
}

class SlideFadeTransitionItem extends StatefulWidget {
  const SlideFadeTransitionItem({
    super.key,
    required this.child,
    required this.index,
    required this.createdAt,
  });

  final Widget child;
  final int index;
  final DateTime createdAt;

  @override
  State<SlideFadeTransitionItem> createState() =>
      _SlideFadeTransitionItemState();
}

class _SlideFadeTransitionItemState extends State<SlideFadeTransitionItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));

    final isNew = DateTime.now().difference(widget.createdAt).inSeconds < 2;
    if (isNew) {
      _controller.forward();
    } else {
      final delay = Duration(
        milliseconds: (widget.index < 6 ? widget.index : 6) * 50,
      );
      Future.delayed(delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

Future<void> showCommentsSheet(
  BuildContext context, {
  required FeedService feedService,
  required Post post,
  required AppUser currentUser,
  bool? isDark,
  void Function(Comment)? onCommentAdded,
}) {
  final effectiveIsDark = isDark ?? AppScope.of(context).themeService.isDarkMode;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: effectiveIsDark ? const Color(0xFF1E1E1E) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => CommentsSheet(
      feedService: feedService,
      post: post,
      currentUser: currentUser,
      isDark: effectiveIsDark,
      onCommentAdded: onCommentAdded,
    ),
  );
}
