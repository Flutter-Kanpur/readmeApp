import 'package:Readme/core/config/readme_host.dart';
import 'package:Readme/core/providers/supabase_providers.dart';
import 'package:Readme/core/state/blog_engagement_provider.dart';
import 'package:Readme/core/state/blog_feed_provider.dart';
import 'package:Readme/core/state/blog_like_provider.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/profile_page/presentation/state/profile_provider.dart';
import 'package:Readme/features/profile_page/presentation/widgets/profile_blog_card.dart';
import 'package:Readme/features/profile_page/presentation/widgets/user_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../shared/widgets/gradient_background.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _appVersionLabel;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    // Profile data loads reactively via [profileProvider], which watches the
    // current user — no manual auth subscription needed.
  }

  Future<void> _loadAppVersion() async {
    if (!ReadmeHost.showAccountLifecycleActions) return;
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersionLabel = '${info.version} (${info.buildNumber})';
    });
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    try {
      // Clear session-scoped caches; profileProvider clears itself once the
      // current user becomes null.
      ref.invalidate(blogLikeProvider);
      ref.invalidate(blogFeedProvider);
      ref.invalidate(blogEngagementProvider);
      await ref.read(supabaseClientProvider).auth.signOut();
      if (!mounted) return;
      context.go('/welcome');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to log out. Please try again.\n$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _userName(ProfileState profile) {
    final candidates = <dynamic>[
      profile.profileData?['name'],
      profile.profileData?['full_name'],
      profile.profileData?['username'],
      profile.user?.userMetadata?['full_name'],
      profile.user?.userMetadata?['name'],
      profile.user?.userMetadata?['username'],
      profile.user?.email,
    ];
    for (final value in candidates) {
      if (value is String &&
          value.trim().isNotEmpty &&
          value.trim() != 'null') {
        return value.trim();
      }
    }
    return 'User';
  }

  String _subtitle(ProfileState profile) {
    final headline = profile.profileData?['headline'] as String?;
    final bio = profile.profileData?['bio'] as String?;
    if (headline != null && headline.trim().isNotEmpty) return headline.trim();
    if (bio != null && bio.trim().isNotEmpty) return bio.trim();
    return '';
  }

  String? _avatarUrl(ProfileState profile) =>
      profile.profileData?['avatar_url'] ??
      profile.user?.userMetadata?['avatar_url'];

  DateTime? _memberSince(ProfileState profile) {
    final createdAt = profile.profileData?['created_at'];
    if (createdAt == null) return null;
    if (createdAt is DateTime) return createdAt;
    return DateTime.tryParse(createdAt.toString());
  }

  @override
  Widget build(BuildContext context) {
    // Seed engagement counts + preload liked-state whenever the published
    // list changes.
    ref.listen(profileProvider, (prev, next) {
      final blogs = next.value?.publishedBlogs;
      if (blogs == null || identical(prev?.value?.publishedBlogs, blogs)) {
        return;
      }
      ref.read(blogEngagementProvider.notifier).seedAll(blogs);
      if (blogs.isNotEmpty) {
        ref
            .read(blogLikeProvider.notifier)
            .preload(blogs.map((blog) => blog.id).toList());
      }
    });

    final asyncProfile = ref.watch(profileProvider);
    final profile = asyncProfile.value ?? const ProfileState();
    final isLoading = asyncProfile.isLoading && !asyncProfile.hasValue;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => ref.read(profileProvider.notifier).refresh(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 100.h),
                    child: Column(
                      children: [
                        _buildProfileHeader(profile),
                        SizedBox(height: 32.h),
                        Divider(color: Colors.grey.shade200, height: 1),
                        SizedBox(height: 24.h),
                        _buildPublishedSection(profile),
                        SizedBox(height: 32.h),
                        UserStatsCard(
                          memberSince: _memberSince(profile),
                          followers: profile.followStats.followers,
                          following: profile.followStats.following,
                          totalArticles: profile.publishedBlogs.length,
                        ),
                        SizedBox(height: 24.h),
                        Center(
                          child: TextButton(
                            onPressed: () => context.push('/privacy-policy'),
                            child: Text(
                              'Privacy Policy',
                              style: textStyle_14RegularBlack().copyWith(
                                fontSize: 14.sp,
                                color: AppColors.linkBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        if (ReadmeHost.showAccountLifecycleActions) ...[
                          Center(
                            child: TextButton(
                              onPressed: _confirmLogout,
                              child: Text(
                                'Log out',
                                style: textStyle_14RegularBlack().copyWith(
                                  fontSize: 14.sp,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          _buildVersionFooter(),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ProfileState profile) {
    final avatarUrl = _avatarUrl(profile);
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
        SizedBox(height: 12.h),
        Text(
          _subtitle(profile),
          textAlign: TextAlign.center,
          style: textStyle_14RegularGrey().copyWith(
            fontSize: 14.sp,
            height: 1.5,
            color: AppColors.greyText,
          ),
        ),
        SizedBox(height: 20.h),
        OutlinedButton(
          onPressed: () => context.go('/edit_profile'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.black,
            side: BorderSide(color: Colors.grey.shade200),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
          ),
          child: Text(
            'Edit Profile',
            style: textStyle_16BoldBlack().copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPublishedSection(ProfileState profile) {
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
              final blog = publishedBlogs[index];
              return ProfileBlogCard(
                blog: blog,
                onEdit: () => context.push('/edit/${blog.id}'),
              );
            },
          ),
      ],
    );
  }

  Widget _buildVersionFooter() {
    final label = _appVersionLabel;
    if (label == null) return const SizedBox.shrink();

    return Center(
      child: Text(
        'Version $label',
        style: textStyle_12RegularGrey().copyWith(
          fontSize: 12.sp,
          color: AppColors.subtitles,
        ),
      ),
    );
  }
}
