import 'dart:async';

import 'package:Readme/core/cache/blog_feed_cache.dart';
import 'package:Readme/core/cache/blog_like_cache.dart';
import 'package:Readme/features/blog_detail/data/datasource/blog_like_datasource.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/home_page/data/datasource/blog_remote_datasource.dart';
import 'package:Readme/features/home_page/data/repositories/blog_repository_impl.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:Readme/features/profile_page/data/datasource/profile_remote_datasource.dart';
import 'package:Readme/features/profile_page/presentation/widgets/profile_blog_card.dart';
import 'package:Readme/features/profile_page/presentation/widgets/user_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/widgets/gradient_background.dart';
import 'package:Readme/core/network/readme_supabase.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = ReadmeSupabase.client;
  late final _blogRepository = BlogRepositoryImpl(
    BlogRemoteDatasource(_supabase),
  );

  late final _profileDatasource = ProfileRemoteDatasource(_supabase);

  User? _user;
  Map<String, dynamic>? _profileData;
  List<Blog> _publishedBlogs = [];
  UserFollowStats _followStats = const UserFollowStats(
    followers: 0,
    following: 0,
  );
  bool _isLoading = true;
  String? _appVersionLabel;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadProfile();
    // Host apps mint the ReadMe session asynchronously after this screen mounts.
    _authSub = _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated) {
        _loadProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        if (!mounted) return;
        setState(() {
          _user = null;
          _profileData = null;
          _publishedBlogs = [];
          _followStats = const UserFollowStats(followers: 0, following: 0);
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersionLabel = '${info.version} (${info.buildNumber})';
    });
  }

  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _user = null;
          _profileData = null;
          _publishedBlogs = [];
          _followStats = const UserFollowStats(followers: 0, following: 0);
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = true;
      });
    }

    try {
      final profileData = await _profileDatasource.fetchProfileById(user.id);
      final publishedBlogs = await _blogRepository.getBlogsByAuthor(user.id);
      final followStats = await _profileDatasource.fetchFollowStats(user.id);

      if (!mounted) return;
      setState(() {
        _profileData = profileData;
        _publishedBlogs = publishedBlogs;
        _followStats = followStats;
        _isLoading = false;
      });
      await _preloadLikeState(publishedBlogs);
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _preloadLikeState(List<Blog> blogs) async {
    final user = _supabase.auth.currentUser;
    if (user == null || blogs.isEmpty || !mounted) return;

    await BlogLikeCache.instance.preload(
      userId: user.id,
      blogIds: blogs.map((blog) => blog.id).toList(),
      datasource: BlogLikeDatasource(_supabase),
    );

    if (mounted) setState(() {});
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
      BlogLikeCache.instance.invalidate();
      BlogFeedCache.instance.invalidate();
      await _supabase.auth.signOut();
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

  String get _userName {
    final candidates = <dynamic>[
      _profileData?['name'],
      _profileData?['full_name'],
      _profileData?['username'],
      _user?.userMetadata?['full_name'],
      _user?.userMetadata?['name'],
      _user?.userMetadata?['username'],
      _user?.email,
    ];
    for (final value in candidates) {
      if (value is String && value.trim().isNotEmpty && value.trim() != 'null') {
        return value.trim();
      }
    }
    return 'User';
  }

  String get _subtitle {
    final headline = _profileData?['headline'] as String?;
    final bio = _profileData?['bio'] as String?;
    if (headline != null && headline.trim().isNotEmpty) return headline.trim();
    if (bio != null && bio.trim().isNotEmpty) return bio.trim();
    return '';
  }

  String? get _avatarUrl =>
      _profileData?['avatar_url'] ?? _user?.userMetadata?['avatar_url'];

  DateTime? get _memberSince {
    final createdAt = _profileData?['created_at'];
    if (createdAt == null) return null;
    if (createdAt is DateTime) return createdAt;
    return DateTime.tryParse(createdAt.toString());
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 100.h),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        SizedBox(height: 32.h),
                        Divider(color: Colors.grey.shade200, height: 1),
                        SizedBox(height: 24.h),
                        _buildPublishedSection(),
                        SizedBox(height: 32.h),
                        UserStatsCard(
                          memberSince: _memberSince,
                          followers: _followStats.followers,
                          following: _followStats.following,
                          totalArticles: _publishedBlogs.length,
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
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 52.r,
          backgroundColor: Colors.grey.shade100,
          backgroundImage: imageProviderFromSource(_avatarUrl),
          child: _avatarUrl == null
              ? Icon(Icons.person, size: 52.r, color: Colors.grey.shade400)
              : null,
        ),
        SizedBox(height: 16.h),
        Text(
          _userName,
          textAlign: TextAlign.center,
          style: textStyle_24BoldBlack().copyWith(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          _subtitle,
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

  Widget _buildPublishedSection() {
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
        if (_publishedBlogs.isEmpty)
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
            itemCount: _publishedBlogs.length,
            separatorBuilder: (_, __) => SizedBox(height: 16.h),
            itemBuilder: (context, index) {
              final blog = _publishedBlogs[index];
              return ProfileBlogCard(
                blog: blog,
                onEdit: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Blog editing coming soon')),
                  );
                },
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
