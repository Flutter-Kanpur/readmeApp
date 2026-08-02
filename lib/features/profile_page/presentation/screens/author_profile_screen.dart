import 'package:Readme/core/cache/blog_engagement_store.dart';
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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Readme/core/network/readme_supabase.dart';

class AuthorProfileScreen extends StatefulWidget {
  const AuthorProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AuthorProfileScreen> createState() => _AuthorProfileScreenState();
}

class _AuthorProfileScreenState extends State<AuthorProfileScreen> {
  final _supabase = ReadmeSupabase.client;
  late final _blogRepository = BlogRepositoryImpl(
    BlogRemoteDatasource(_supabase),
  );
  late final _profileDatasource = ProfileRemoteDatasource(_supabase);

  Map<String, dynamic>? _profileData;
  List<Blog> _publishedBlogs = [];
  UserFollowStats _followStats = const UserFollowStats(
    followers: 0,
    following: 0,
  );
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _followActionLoading = false;
  String? _error;

  bool get _isSelf => _supabase.auth.currentUser?.id == widget.userId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profileData = await _profileDatasource.fetchProfileById(
        widget.userId,
      );
      if (profileData == null) {
        if (!mounted) return;
        setState(() {
          _error = 'User not found';
          _isLoading = false;
        });
        return;
      }

      final publishedBlogs = await _blogRepository.getBlogsByAuthor(
        widget.userId,
      );
      final followStats = await _profileDatasource.fetchFollowStats(
        widget.userId,
      );

      var isFollowing = false;
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null && currentUser.id != widget.userId) {
        isFollowing = await _profileDatasource.isFollowingAuthor(
          followerId: currentUser.id,
          authorId: widget.userId,
        );
      }

      if (!mounted) return;
      BlogEngagementStore.instance.seedAll(publishedBlogs);
      setState(() {
        _profileData = profileData;
        _publishedBlogs = publishedBlogs;
        _followStats = followStats;
        _isFollowing = isFollowing;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_isSelf || _followActionLoading) return;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      context.push('/signin');
      return;
    }

    final wasFollowing = _isFollowing;
    setState(() {
      _isFollowing = !wasFollowing;
      _followActionLoading = true;
      _followStats = UserFollowStats(
        followers: wasFollowing
            ? (_followStats.followers - 1).clamp(0, 1 << 30)
            : _followStats.followers + 1,
        following: _followStats.following,
      );
    });

    try {
      if (wasFollowing) {
        await _profileDatasource.unfollowAuthor(
          followerId: user.id,
          authorId: widget.userId,
        );
      } else {
        await _profileDatasource.followAuthor(
          followerId: user.id,
          authorId: widget.userId,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFollowing = wasFollowing;
        _followStats = UserFollowStats(
          followers: wasFollowing
              ? _followStats.followers + 1
              : (_followStats.followers - 1).clamp(0, 1 << 30),
          following: _followStats.following,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _followActionLoading = false);
    }
  }

  String get _userName =>
      _profileData?['name'] ??
      _profileData?['full_name'] ??
      _profileData?['username'] ??
      'User';

  String get _subtitle {
    final headline = _profileData?['headline'] as String?;
    final bio = _profileData?['bio'] as String?;
    if (headline != null && headline.trim().isNotEmpty) return headline.trim();
    if (bio != null && bio.trim().isNotEmpty) return bio.trim();
    return '';
  }

  String? get _avatarUrl => _profileData?['avatar_url'] as String?;

  DateTime? get _memberSince {
    final createdAt = _profileData?['created_at'];
    if (createdAt == null) return null;
    if (createdAt is DateTime) return createdAt;
    return DateTime.tryParse(createdAt.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorView(message: _error!, onBack: () => context.pop())
            : RefreshIndicator(
                onRefresh: _loadProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 40.h),
                  child: Column(
                    children: [
                      _buildBackLink(),
                      SizedBox(height: 24.h),
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
        if (_subtitle.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: textStyle_14RegularGrey().copyWith(
              fontSize: 14.sp,
              height: 1.5,
              color: AppColors.subtitles,
            ),
          ),
        ],
        if (!_isSelf) ...[
          SizedBox(height: 20.h),
          SizedBox(
            width: 160.w,
            height: 44.h,
            child: _isFollowing
                ? OutlinedButton(
                    onPressed: _followActionLoading ? null : _toggleFollow,
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
                    onPressed: _followActionLoading ? null : _toggleFollow,
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
              return ProfileBlogCard(blog: _publishedBlogs[index]);
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
