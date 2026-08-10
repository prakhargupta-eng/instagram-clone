import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/feed_service.dart';
import '../../widgets/avatar.dart';

class CommentsSheet extends StatefulWidget {
  const CommentsSheet({
    super.key,
    required this.feedService,
    required this.post,
    required this.currentUser,
    this.isDark = false,
  });

  final FeedService feedService;
  final Post post;
  final AppUser currentUser;
  final bool isDark;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.feedService.getPost(widget.post.id);
    final dividerColor = widget.isDark ? Colors.white12 : AppColors.border;
    final textColor = widget.isDark ? Colors.white : AppColors.textPrimary;
    final subTextColor = widget.isDark ? Colors.white54 : AppColors.textSecondary;
    final sheetBgColor = widget.isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputBgColor = widget.isDark ? const Color(0xFF2E2E2E) : AppColors.background;

    return Container(
      color: sheetBgColor,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white24 : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.comments,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor),
          ),
          Divider(height: 16, color: dividerColor),
          Flexible(
            child: post.comments.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      AppStrings.noCommentsYet,
                      style: TextStyle(color: subTextColor),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: post.comments.length,
                    itemBuilder: (context, index) {
                      final comment = post.comments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                                      style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      comment.text,
                                      style: TextStyle(color: textColor, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMM d, h:mm a').format(comment.createdAt),
                                      style: TextStyle(color: subTextColor, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide(color: dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide(color: dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide(color: widget.isDark ? Colors.white38 : AppColors.primary),
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: _submit,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: () => _submit(_controller.text),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom > 0 ? 0 : 8),
        ],
      ),
    );
  }

  void _submit(String text) {
    widget.feedService.addComment(widget.post.id, widget.currentUser, text);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }
}

Future<void> showCommentsSheet(
  BuildContext context, {
  required FeedService feedService,
  required Post post,
  required AppUser currentUser,
  bool isDark = false,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => CommentsSheet(
      feedService: feedService,
      post: post,
      currentUser: currentUser,
      isDark: isDark,
    ),
  );
}
