import 'package:Readme/core/network/readme_supabase.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/blog_detail/data/datasource/blog_comment_datasource.dart';
import 'package:Readme/features/blog_detail/domain/entities/blog_comment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

Future<void> showBlogReplySheet({
  required BuildContext context,
  required String blogId,
  required BlogComment parentComment,
  required VoidCallback onReplyPosted,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (sheetContext) {
      return _BlogReplySheet(
        blogId: blogId,
        parentComment: parentComment,
        onReplyPosted: () {
          Navigator.of(sheetContext).pop();
          onReplyPosted();
        },
      );
    },
  );
}

class _BlogReplySheet extends StatefulWidget {
  const _BlogReplySheet({
    required this.blogId,
    required this.parentComment,
    required this.onReplyPosted,
  });

  final String blogId;
  final BlogComment parentComment;
  final VoidCallback onReplyPosted;

  @override
  State<_BlogReplySheet> createState() => _BlogReplySheetState();
}

class _BlogReplySheetState extends State<_BlogReplySheet> {
  final _controller = TextEditingController();
  final _datasource = BlogCommentDatasource(ReadmeSupabase.client);
  bool _submitting = false;
  String? _avatarUrl;

  static const _maxLength = 2000;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAvatar();
  }

  Future<void> _loadCurrentUserAvatar() async {
    final user = ReadmeSupabase.client.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await ReadmeSupabase.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      if (!mounted) return;
      setState(() => _avatarUrl = profile?['avatar_url'] as String?);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _submitting) return;

    final user = ReadmeSupabase.client.auth.currentUser;
    if (user == null) {
      if (mounted) context.push('/signin');
      return;
    }

    setState(() => _submitting = true);
    try {
      await _datasource.postReply(
        blogId: widget.blogId,
        parentId: widget.parentComment.id,
        userId: user.id,
        body: body,
      );
      widget.onReplyPosted();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, bottomInset + 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.borderGrey,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Post your reply',
                  style: textStyle_16BoldBlack().copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, size: 22.sp, color: AppColors.black),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _ParentCommentPreview(comment: widget.parentComment),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: imageProviderFromSource(_avatarUrl),
                child: _avatarUrl == null
                    ? Icon(Icons.person, size: 18.r, color: Colors.grey)
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderGrey),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
                  child: TextField(
                    controller: _controller,
                    maxLines: 4,
                    minLines: 3,
                    maxLength: _maxLength,
                    decoration: InputDecoration(
                      hintText: 'Write a reply',
                      hintStyle: textStyle_14RegularGrey().copyWith(
                        fontSize: 14.sp,
                        color: AppColors.lightGrey,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      counterText: '',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.linkBlue,
                disabledBackgroundColor: AppColors.linkBlue.withOpacity(0.5),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: _submitting
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Reply',
                      style: textStyle_14RegularBlack().copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentCommentPreview extends StatelessWidget {
  const _ParentCommentPreview({required this.comment});

  final BlogComment comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: imageProviderFromSource(comment.author.avatarUrl),
            child: comment.author.avatarUrl == null
                ? Icon(Icons.person, size: 16.r, color: Colors.grey)
                : null,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.author.name,
                  style: textStyle_14RegularBlack().copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  comment.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle_14RegularGrey().copyWith(
                    fontSize: 14.sp,
                    color: AppColors.subtitles,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
