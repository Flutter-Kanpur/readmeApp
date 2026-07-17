import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:Readme/features/profile_page/data/datasource/profile_remote_datasource.dart';
import 'package:Readme/features/profile_page/presentation/utils/open_author_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthorFollowCard extends StatefulWidget {
  const AuthorFollowCard({super.key, required this.author});

  final Author author;

  @override
  State<AuthorFollowCard> createState() => _AuthorFollowCardState();
}

class _AuthorFollowCardState extends State<AuthorFollowCard> {
  late final ProfileRemoteDatasource _datasource;

  bool _isLoading = true;
  bool _isFollowing = false;
  bool _actionLoading = false;
  bool _isSelf = false;

  @override
  void initState() {
    super.initState();
    _datasource = ProfileRemoteDatasource(Supabase.instance.client);
    _loadFollowState();
  }

  Future<void> _loadFollowState() async {
    final authorId = widget.author.id;
    if (authorId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isSelf = false;
          _isLoading = false;
        });
      }
      return;
    }

    if (user.id == authorId) {
      if (mounted) {
        setState(() {
          _isSelf = true;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final isFollowing = await _datasource.isFollowingAuthor(
        followerId: user.id,
        authorId: authorId,
      );
      if (!mounted) return;
      setState(() {
        _isFollowing = isFollowing;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final authorId = widget.author.id;
    if (authorId == null || _actionLoading) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.push('/signin');
      return;
    }

    final wasFollowing = _isFollowing;
    setState(() {
      _isFollowing = !wasFollowing;
      _actionLoading = true;
    });

    try {
      if (wasFollowing) {
        await _datasource.unfollowAuthor(
          followerId: user.id,
          authorId: authorId,
        );
      } else {
        await _datasource.followAuthor(followerId: user.id, authorId: authorId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFollowing = wasFollowing);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.author.id == null || _isSelf || _isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => openAuthorProfile(context, widget.author),
                child: CircleAvatar(
                  radius: 32.r,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: imageProviderFromSource(
                    widget.author.avatarUrl,
                  ),
                  child: widget.author.avatarUrl == null
                      ? Text(
                          widget.author.name.isNotEmpty
                              ? widget.author.name[0].toUpperCase()
                              : '?',
                          style: textStyle_16BoldBlack().copyWith(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  widget.author.name,
                  style: textStyle_16BoldBlack().copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 48.h,
            child: _isFollowing
                ? OutlinedButton(
                    onPressed: _actionLoading ? null : _toggleFollow,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.black,
                      side: const BorderSide(color: AppColors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      _actionLoading ? 'Updating…' : 'Following',
                      style: textStyle_16BoldBlack().copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _actionLoading ? null : _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      _actionLoading ? 'Updating…' : 'Follow Author',
                      style: textStyle_16BoldBlack().copyWith(
                        fontSize: 14.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
