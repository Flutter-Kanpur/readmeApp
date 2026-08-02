import 'package:Readme/core/cache/blog_engagement_store.dart';
import 'package:Readme/core/cache/blog_like_cache.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/features/blog_detail/data/datasource/blog_like_datasource.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/communities/data/datasource/community_remote_datasource.dart';
import 'package:Readme/features/communities/data/models/community_article_model.dart';
import 'package:Readme/features/communities/data/models/community_newsletter_models.dart';
import 'package:Readme/features/communities/domain/entities/community.dart';
import 'package:Readme/features/communities/presentation/widgets/community_blog_card.dart';
import 'package:Readme/features/communities/presentation/widgets/community_detail_shimmer.dart';
import 'package:Readme/features/communities/presentation/widgets/community_newsletter_subscribe_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Readme/core/network/readme_supabase.dart';

class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({super.key, required this.slug, this.community});

  final String slug;
  final Community? community;

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  late final CommunityRemoteDatasource _datasource;

  Community? _community;
  CommunityStats? _stats;
  List<CommunityArticle> _articles = [];
  bool _isMember = false;
  String? _userRole;
  bool _isFollowing = false;
  bool _followActionLoading = false;
  bool _followAvailable = true;
  bool _isLoading = true;
  String? _error;
  CommunityNewsletterStats? _newsletterStats;

  @override
  void initState() {
    super.initState();
    _datasource = CommunityRemoteDatasource(ReadmeSupabase.client);
    _community = widget.community;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final community =
          _community ?? await _datasource.fetchCommunityBySlug(widget.slug);

      if (community == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Community not found';
          _isLoading = false;
        });
        return;
      }

      final stats = await _datasource.fetchCommunityStats(community.id);
      final articles = await _datasource.fetchCommunityArticles(community.id);

      final user = ReadmeSupabase.client.auth.currentUser;
      final userId = user?.id;
      var isMember = false;
      String? userRole;
      var isFollowing = false;
      var followAvailable = true;
      if (userId != null) {
        isMember = await _datasource.isCommunityMember(community.id, userId);
        userRole = await _datasource.fetchUserRole(community.id, userId);
        try {
          isFollowing = await _datasource.isFollowingCommunity(
            communityId: community.id,
            userId: userId,
          );
        } catch (_) {
          followAvailable = false;
        }
      }

      // Newsletter stats are best-effort — if the table doesn't exist yet on
      // this environment we don't want to break the screen.
      CommunityNewsletterStats? newsletterStats;
      try {
        newsletterStats = await _datasource.fetchNewsletterStats(
          communityId: community.id,
          viewerEmail: user?.email,
        );
      } catch (_) {
        newsletterStats = null;
      }

      if (!mounted) return;
      BlogEngagementStore.instance.seedAll(articles.map((a) => a.blog));
      setState(() {
        _community = community;
        _stats = stats;
        _articles = articles;
        _isMember = isMember;
        _userRole = userRole;
        _isFollowing = isFollowing;
        _followAvailable = followAvailable;
        _newsletterStats = newsletterStats;
        _isLoading = false;
      });
      if (userId != null && articles.isNotEmpty) {
        await BlogLikeCache.instance.preload(
          userId: userId,
          blogIds: articles.map((a) => a.blog.id).toList(),
          datasource: BlogLikeDatasource(ReadmeSupabase.client),
        );
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const CommunityDetailShimmer()
            : _error != null
            ? _ErrorView(message: _error!, onBack: () => context.pop())
            : RefreshIndicator(
                onRefresh: _loadDetail,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBackLink(),
                            SizedBox(height: 20.h),
                            _buildHeader(),
                            SizedBox(height: 24.h),
                            _buildActions(context),
                            SizedBox(height: 24.h),
                            Divider(color: Colors.grey.shade200, height: 1),
                            SizedBox(height: 24.h),
                            if (_newsletterStats != null) ...[
                              CommunityNewsletterSubscribeCard(
                                community: _community!,
                                stats: _newsletterStats!,
                                datasource: _datasource,
                                onSubscribed: _loadDetail,
                              ),
                              SizedBox(height: 24.h),
                              Divider(color: Colors.grey.shade200, height: 1),
                              SizedBox(height: 24.h),
                            ],
                            Text(
                              'Published articles',
                              style: textStyle_16BoldBlack().copyWith(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 16.h),
                          ],
                        ),
                      ),
                    ),
                    if (_articles.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Text(
                            'No published articles yet.',
                            style: textStyle_14RegularGrey().copyWith(
                              fontSize: 14.sp,
                              color: AppColors.subtitles,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 32.h),
                        sliver: SliverList.separated(
                          itemCount: _articles.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            return CommunityBlogCard(
                              article: _articles[index],
                              community: _community!,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBackLink() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back, size: 18.sp, color: AppColors.linkBlue),
          SizedBox(width: 6.w),
          Text(
            'Back to Communities',
            style: textStyle_14RegularBlack().copyWith(
              fontSize: 14.sp,
              color: AppColors.linkBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final community = _community!;
    final stats = _stats;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: AppImage(
            source: community.logoUrl,
            width: 88.w,
            height: 88.w,
            fit: BoxFit.cover,
            placeholder: Container(
              width: 88.w,
              height: 88.w,
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: Icon(
                Icons.groups_outlined,
                size: 36.sp,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                community.name,
                style: textStyle_24BoldBlack().copyWith(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              if (community.description != null &&
                  community.description!.trim().isNotEmpty) ...[
                SizedBox(height: 8.h),
                Text(
                  community.description!,
                  style: textStyle_14RegularGrey().copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.40,
                    color: AppColors.greyText,
                  ),
                ),
              ],
              if (stats != null) ...[
                SizedBox(height: 10.h),
                Text(
                  _formatCommunityStats(stats),
                  style: textStyle_12RegularGrey().copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatCommunityStats(CommunityStats stats) {
    final contributorLabel = stats.memberCount == 1
        ? '1 Contributor'
        : '${stats.memberCount} Contributors';
    final followerLabel = stats.followerCount == 1
        ? '1 Follower'
        : '${stats.followerCount} Followers';
    final publishedLabel = stats.publishedCount == 1
        ? '1 Article'
        : '${stats.publishedCount} Articles';

    return '$contributorLabel · $followerLabel · $publishedLabel';
  }

  Future<void> _toggleFollow() async {
    final user = ReadmeSupabase.client.auth.currentUser;
    if (user == null) {
      context.push('/signin');
      return;
    }

    if (_community == null || _followActionLoading) return;

    final wasFollowing = _isFollowing;
    setState(() {
      _isFollowing = !wasFollowing;
      _followActionLoading = true;
      if (_stats != null) {
        _stats = CommunityStats(
          memberCount: _stats!.memberCount,
          followerCount: wasFollowing
              ? (_stats!.followerCount - 1).clamp(0, 1 << 30)
              : _stats!.followerCount + 1,
          publishedCount: _stats!.publishedCount,
        );
      }
    });

    try {
      if (wasFollowing) {
        await _datasource.unfollowCommunity(
          communityId: _community!.id,
          userId: user.id,
        );
      } else {
        await _datasource.followCommunity(
          communityId: _community!.id,
          userId: user.id,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFollowing = wasFollowing;
        if (_stats != null) {
          _stats = CommunityStats(
            memberCount: _stats!.memberCount,
            followerCount: wasFollowing
                ? _stats!.followerCount + 1
                : (_stats!.followerCount - 1).clamp(0, 1 << 30),
            publishedCount: _stats!.publishedCount,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _followActionLoading = false);
    }
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            onPressed: () => context.push(
              '/community/${_community!.slug}/dashboard',
              extra: _community,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              'Community dashboard',
              style: textStyle_16BoldBlack().copyWith(
                fontSize: 14.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: OutlinedButton(
            onPressed: _isMember
                ? () => context.push('/create')
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'You need to be a community member to write for this community.',
                        ),
                      ),
                    );
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.black,
              side: const BorderSide(color: AppColors.black),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              'Write for community',
              style: textStyle_16BoldBlack().copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (_followAvailable) ...[
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
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
                      _followActionLoading ? 'Updating…' : 'Follow Community',
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
