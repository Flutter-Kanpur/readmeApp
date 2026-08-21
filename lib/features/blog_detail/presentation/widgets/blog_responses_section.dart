import 'package:Readme/core/providers/datasource_providers.dart';
import 'package:Readme/core/providers/supabase_providers.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/blog_detail/data/datasource/blog_comment_datasource.dart';
import 'package:Readme/features/blog_detail/domain/entities/blog_comment.dart';
import 'package:Readme/features/blog_detail/presentation/widgets/blog_comment_tile.dart';
import 'package:Readme/features/blog_detail/presentation/widgets/blog_reply_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class BlogResponsesSection extends ConsumerStatefulWidget {
  const BlogResponsesSection({super.key, required this.blogId});

  final String blogId;

  @override
  ConsumerState<BlogResponsesSection> createState() =>
      _BlogResponsesSectionState();
}

class _BlogResponsesSectionState extends ConsumerState<BlogResponsesSection> {
  final _composerController = TextEditingController();
  late final BlogCommentDatasource _datasource;

  List<BlogComment> _comments = [];
  bool _loading = true;
  bool _posting = false;

  static const _maxLength = 2000;

  @override
  void initState() {
    super.initState();
    _datasource = ref.read(blogCommentDatasourceProvider);
    _loadComments();
  }

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  List<String> _collectCommentIds(List<BlogComment> comments) {
    final ids = <String>[];
    for (final comment in comments) {
      ids.add(comment.id);
      for (final reply in comment.replies) {
        ids.add(reply.id);
      }
    }
    return ids;
  }

  List<BlogComment> _applyLikedState(
    List<BlogComment> comments,
    Set<String> likedIds,
  ) {
    return comments
        .map(
          (comment) => comment.copyWith(
            isLiked: likedIds.contains(comment.id),
            replies: comment.replies
                .map(
                  (reply) => reply.copyWith(
                    isLiked: likedIds.contains(reply.id),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    try {
      final comments = await _datasource.fetchComments(widget.blogId);
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final likedIds = await _datasource.fetchLikedCommentIds(
          userId: user.id,
          commentIds: _collectCommentIds(comments),
        );
        if (!mounted) return;
        setState(() {
          _comments = _applyLikedState(comments, likedIds);
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _comments = comments;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _updateCommentLike(String commentId, bool isLiked, int likeCount) {
    setState(() {
      _comments = _comments.map((comment) {
        if (comment.id == commentId) {
          return comment.copyWith(isLiked: isLiked, likeCount: likeCount);
        }
        final updatedReplies = comment.replies.map((reply) {
          if (reply.id == commentId) {
            return reply.copyWith(isLiked: isLiked, likeCount: likeCount);
          }
          return reply;
        }).toList();
        if (comment.replies.any((reply) => reply.id == commentId)) {
          return comment.copyWith(replies: updatedReplies);
        }
        return comment;
      }).toList();
    });
  }

  Future<void> _postTopLevelComment() async {
    final body = _composerController.text.trim();
    if (body.isEmpty || _posting) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) context.push('/signin');
      return;
    }

    setState(() => _posting = true);
    try {
      await _datasource.postComment(
        blogId: widget.blogId,
        userId: user.id,
        body: body,
      );
      _composerController.clear();
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  void _openReplySheet(BlogComment parentComment) {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.push('/signin');
      return;
    }

    showBlogReplySheet(
      context: context,
      blogId: widget.blogId,
      parentComment: parentComment,
      onReplyPosted: _loadComments,
    );
  }

  void _showInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comments'),
        content: const Text(
          'Share thoughtful feedback and join the conversation. '
          'Please be respectful to authors and other readers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(currentUserProvider) != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, thickness: 1, color: AppColors.borderGrey),
        SizedBox(height: 24.h),
        Row(
          children: [
            Text(
              'Comments',
              style: textStyle_16BoldBlack().copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8.w),
            InkWell(
              onTap: _showInfoDialog,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 14.sp,
                  color: AppColors.subtitles,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        _TopLevelComposer(
          controller: _composerController,
          posting: _posting,
          maxLength: _maxLength,
          isLoggedIn: isLoggedIn,
          onSubmit: _postTopLevelComment,
          onTapWhenLoggedOut: () => context.push('/signin'),
        ),
        SizedBox(height: 24.h),
        if (_loading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_comments.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Text(
              'No responses yet. Share your thoughts.',
              style: textStyle_14RegularGrey().copyWith(
                fontSize: 15.sp,
                color: AppColors.subtitles,
              ),
            ),
          )
        else
          ..._comments.map(
            (comment) => Padding(
              padding: EdgeInsets.only(bottom: 24.h),
              child: BlogCommentTile(
                comment: comment,
                onLikeChanged: _updateCommentLike,
                onReplyTap: () => _openReplySheet(comment),
              ),
            ),
          ),
      ],
    );
  }
}

class _TopLevelComposer extends StatelessWidget {
  const _TopLevelComposer({
    required this.controller,
    required this.posting,
    required this.maxLength,
    required this.isLoggedIn,
    required this.onSubmit,
    required this.onTapWhenLoggedOut,
  });

  final TextEditingController controller;
  final bool posting;
  final int maxLength;
  final bool isLoggedIn;
  final VoidCallback onSubmit;
  final VoidCallback onTapWhenLoggedOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGrey),
        borderRadius: BorderRadius.circular(16.r),
      ),
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            maxLines: 4,
            minLines: 3,
            maxLength: maxLength,
            enabled: isLoggedIn && !posting,
            onTap: isLoggedIn ? null : onTapWhenLoggedOut,
            decoration: InputDecoration(
              hintText: 'Write a reply.',
              hintStyle: textStyle_14RegularGrey().copyWith(
                fontSize: 15.sp,
                color: AppColors.lightGrey,
              ),
              border: InputBorder.none,
              isDense: true,
              counterText: '',
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: posting || !isLoggedIn ? null : onSubmit,
              child: posting
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Post',
                      style: textStyle_14RegularBlack().copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.linkBlue,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
