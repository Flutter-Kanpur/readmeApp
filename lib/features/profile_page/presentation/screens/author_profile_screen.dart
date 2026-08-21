import 'package:Readme/core/providers/supabase_providers.dart';
import 'package:Readme/core/state/blog_engagement_provider.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/profile_page/presentation/state/author_profile_provider.dart';
import 'package:Readme/features/profile_page/presentation/widgets/profile_blog_card.dart';
import 'package:Readme/features/profile_page/presentation/widgets/user_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AuthorProfileScreen extends ConsumerStatefulWidget {
  const AuthorProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AuthorProfileScreen> createState() =>
      _AuthorProfileScreenState();
}

class _AuthorProfileScreenState extends ConsumerState<AuthorProfileScreen> {
  bool _followActionLoading = false;

  String get _userId => widget.userId;

  Future<void> _onFollowTap() async {
    if (_followActionLoading) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.push('/signin');
      return;
    }

    setState(() => _followActionLoading = true);
    try {
      await ref.read(authorProfileProvider(_userId).notifier).toggleFollow();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _followActionLoading = false);
    }
  }

  String _userName(AuthorProfileState profile) =>
      profile.profileData?['name'] ??
      profile.profileData?['full_name'] ??
      profile.profileData?['username'] ??
      'User';

  String _subtitle(AuthorProfileState profile) {
    final headline = profile.profileData?['headline'] as String?;
    final bio = profile.profileData?['bio'] as String?;
    if (headline != null && headline.trim().isNotEmpty) return headline.trim();
    if (bio != null && bio.trim().isNotEmpty) return bio.trim();
    return '';
  }

  String? _avatarUrl(AuthorProfileState profile) =>
      profile.profileData?['avatar_url'] as String?;

  DateTime? _memberSince(AuthorProfileState profile) {
    final createdAt = profile.profileData?['created_at'];
    if (createdAt == null) return null;
    if (createdAt is DateTime) return createdAt;
    return DateTime.tryParse(createdAt.toString());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authorProfileProvider(_userId), (prev, next) {
      final blogs = next.value?.publishedBlogs;
      if (blogs == null || identical(prev?.value?.publishedBlogs, blogs)) {
        return;
      }
      ref.read(blogEngagementProvider.notifier).seedAll(blogs);
    });

    final async = ref.watch(authorProfileProvider(_userId));
    final profile = async.value;
    final isSelf = ref.watch(currentUserProvider)?.id == _userId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: (async.isLoading && profile == null)
            ? const Center(child: CircularProgressIndicator())
            : (async.hasError && profile == null)
            ? _ErrorView(
                message: async.error.toString().replaceFirst('Exception: ', ''),
                onBack: () => context.pop(),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(authorProfileProvider(_userId).notifier).refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 40.h),
                  child: Column(
                    children: [
                      _buildBackLink(),
                      SizedBox(height: 24.h),
                      _buildProfileHeader(
                        profile ?? const AuthorProfileState(),
                        isSelf,
                      ),
                      SizedBox(height: 32.h),
                      Divider(color: Colors.grey.shade200, height: 1),
                      SizedBox(height: 24.h),
                      _buildPublishedSection(
                        profile ?? const AuthorProfileState(),
                      ),
                      SizedBox(height: 32.h),
                      UserStatsCard(
                        memberSince: _memberSince(
                          profile ?? const AuthorProfileState(),
                        ),
                        followers:
                            (profile ?? const AuthorProfileState())
                                .followStats
                                .followers,
                        following:
                            (profile ?? const AuthorProfileState())
                                .followStats
                                .following,
                        totalArticles:
                            (profile ?? const AuthorProfileState())
                                .publishedBlogs
                                .length,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBackLink() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, size: 18.sp, color: AppColors.linkBlue),
            SizedBox(width: 6.w),
            Text(
              'Back',
              style: textStyle_14RegularBlack().copyWith(
                fontSize: 14.sp,
                color: AppColors.linkBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AuthorProfileState profile, bool isSelf) {
    final avatarUrl = _avatarUrl(profile);
    final subtitle = _subtitle(profile);
    return Column(
      children: [
        CircleAvatar(
          radius: 52.r,
          backgroundColor: Colors.grey.shade100,
          backgroundImage: imageProviderFromSource(avatarUrl),
          child: avatarUrl == null
              ? Icon(Icons.person, size: 52.r, color: Colors.grey.shade400)
              : null,
        ),
        SizedBox(height: 16.h),
        Text(
          _userName(profile),
          textAlign: TextAlign.center,
          style: textStyle_24BoldBlack().copyWith(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: textStyle_14RegularGrey().copyWith(
              fontSize: 14.sp,
              height: 1.5,
              color: AppColors.subtitles,
            ),
          ),
        ],
        if (!isSelf) ...[
          SizedBox(height: 20.h),
          SizedBox(
            width: 160.w,
            height: 44.h,
            child: profile.isFollowing
                ? OutlinedButton(
                    onPressed: _followActionLoading ? null : _onFollowTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.black,
                      side: const BorderSide(color: AppColors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      _followActionLoading ? 'Updating…' : 'Following',
                      style: textStyle_16BoldBlack().copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _followActionLoading ? null : _onFollowTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      _followActionLoading ? 'Updating…' : 'Follow',
                      style: textStyle_16BoldBlack().copyWith(
                        fontSize: 14.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildPublishedSection(AuthorProfileState profile) {
    final publishedBlogs = profile.publishedBlogs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PUBLISHED',
          style: textStyle_12RegularGrey().copyWith(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.subtitles,
          ),
        ),
        SizedBox(height: 16.h),
        if (publishedBlogs.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 32.h),
            child: Center(
              child: Text(
                'No published articles yet',
                style: textStyle_14RegularGrey().copyWith(fontSize: 14.sp),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: publishedBlogs.length,
            separatorBuilder: (_, _) => SizedBox(height: 16.h),
            itemBuilder: (context, index) {
              return ProfileBlogCard(blog: publishedBlogs[index]);
            },
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: textStyle_14RegularGrey(),
          ),
          SizedBox(height: 16.h),
          OutlinedButton(onPressed: onBack, child: const Text('Go back')),
        ],
      ),
    );
  }
}
