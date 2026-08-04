import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/relative_time.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/blog_detail/domain/entities/blog_comment.dart';
import 'package:Readme/features/blog_detail/presentation/widgets/blog_comment_like_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BlogCommentTile extends StatefulWidget {
  const BlogCommentTile({
    super.key,
    required this.comment,
    required this.onLikeChanged,
    required this.onReplyTap,
    this.showReplyAction = true,
    this.isReply = false,
  });

  final BlogComment comment;
  final void Function(String commentId, bool isLiked, int likeCount) onLikeChanged;
  final VoidCallback? onReplyTap;
  final bool showReplyAction;
  final bool isReply;

  @override
  State<BlogCommentTile> createState() => _BlogCommentTileState();
}

class _BlogCommentTileState extends State<BlogCommentTile> {
  bool _repliesExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isReply) {
      return _CommentBody(
        comment: widget.comment,
        onLikeChanged: widget.onLikeChanged,
      );
    }

    final comment = widget.comment;
    final hasReplies = comment.replyCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentBody(
          comment: comment,
          onLikeChanged: widget.onLikeChanged,
          onReplyTap: widget.showReplyAction ? widget.onReplyTap : null,
          showReplyCount: widget.showReplyAction,
        ),
        if (hasReplies) ...[
          SizedBox(height: 8.h),
          TextButton(
            onPressed: () => setState(() => _repliesExpanded = !_repliesExpanded),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _repliesExpanded
                  ? 'Hide replies'
                  : 'Show replies (${comment.replyCount})',
              style: textStyle_14RegularBlack().copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.linkBlue,
              ),
            ),
          ),
        ],
        if (hasReplies && _repliesExpanded) ...[
          SizedBox(height: 8.h),
          ...comment.replies.map(
            (reply) => Padding(
              padding: EdgeInsets.only(left: 28.w, bottom: 16.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 2.w,
                    margin: EdgeInsets.only(right: 12.w, top: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.borderGrey,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    constraints: BoxConstraints(minHeight: 48.h),
                  ),
                  Expanded(
                    child: BlogCommentTile(
                      comment: reply,
                      onLikeChanged: widget.onLikeChanged,
                      isReply: true,
                      showReplyAction: false, onReplyTap: () {  },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CommentBody extends StatelessWidget {
  const _CommentBody({
    required this.comment,
    required this.onLikeChanged,
    this.onReplyTap,
    this.showReplyCount = false,
  });

  final BlogComment comment;
  final void Function(String commentId, bool isLiked, int likeCount) onLikeChanged;
  final VoidCallback? onReplyTap;
  final bool showReplyCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: imageProviderFromSource(comment.author.avatarUrl),
              child: comment.author.avatarUrl == null
                  ? Icon(Icons.person, size: 20.r, color: Colors.grey)
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.author.name,
                          style: textStyle_16BoldBlack().copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        formatRelativeTime(comment.createdAt),
                        style: textStyle_12RegularGrey().copyWith(
                          fontSize: 13.sp,
                          color: AppColors.lightGrey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    comment.body,
                    style: textStyle_14RegularBlack().copyWith(
                      fontSize: 15.sp,
                      height: 1.45,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      BlogCommentLikeButton(
                        commentId: comment.id,
                        initialLikeCount: comment.likeCount,
                        initialIsLiked: comment.isLiked,
                        onChanged: (isLiked, likeCount) =>
                            onLikeChanged(comment.id, isLiked, likeCount),
                      ),
                      if (showReplyCount) ...[
                        SizedBox(width: 16.w),
                        InkWell(
                          onTap: onReplyTap,
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 4.h,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 18.sp,
                                  color: AppColors.subtitles,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  formatEngagementCount(comment.replyCount),
                                  style: textStyle_12RegularGrey().copyWith(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.subtitles,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
