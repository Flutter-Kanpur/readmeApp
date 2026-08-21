import 'package:Readme/core/providers/supabase_providers.dart';
import 'package:Readme/core/state/blog_engagement_provider.dart';
import 'package:Readme/core/state/blog_like_provider.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/communities/data/models/community_article_model.dart';
import 'package:Readme/features/communities/presentation/state/community_detail_provider.dart';
import 'package:Readme/features/communities/presentation/widgets/community_blog_card.dart';
import 'package:Readme/features/communities/presentation/widgets/community_detail_shimmer.dart';
import 'package:Readme/features/communities/presentation/widgets/community_newsletter_subscribe_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class CommunityDetailScreen extends ConsumerStatefulWidget {
  const CommunityDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  bool _followActionLoading = false;

  String get _slug => widget.slug;

  Future<void> _onFollowTap() async {
    if (_followActionLoading) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.push('/signin');
      return;
    }

    setState(() => _followActionLoading = true);
    try {
      await ref.read(communityDetailProvider(_slug).notifier).toggleFollow();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _followActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Seed shared engagement counts and preload liked state whenever the article
    // list changes (initial load / refresh). Done here rather than in the
    // provider's build() so we never mutate other providers during a build.
    ref.listen(communityDetailProvider(_slug), (prev, next) {
      final articles = next.value?.articles;
      if (articles == null || identical(prev?.value?.articles, articles)) {
        return;
      }
      final blogs = articles.map((a) => a.blog).toList();
      ref.read(blogEngagementProvider.notifier).seedAll(blogs);
      ref
          .read(blogLikeProvider.notifier)
          .preload(blogs.map((b) => b.id).toList());
    });

    final async = ref.watch(communityDetailProvider(_slug));
    final state = async.value;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: (async.isLoading && state == null)
            ? const CommunityDetailShimmer()
            : (async.hasError && state == null)
            ? _ErrorView(
                message: async.error.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
                onBack: () => context.pop(),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(communityDetailProvider(_slug).notifier).refresh(),
                child: _buildContent(state!),
              ),
      ),
    );
  }

  Widget _buildContent(CommunityDetailState state) {
    final community = state.community;
    final articles = state.articles;

    return CustomScrollView(
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
                _buildHeader(state),
                SizedBox(height: 24.h),
                _buildActions(state),
                SizedBox(height: 24.h),
                Divider(color: Colors.grey.shade200, height: 1),
                SizedBox(height: 24.h),
                if (state.newsletterStats != null) ...[
                  CommunityNewsletterSubscribeCard(
                    community: community,
                    stats: state.newsletterStats!,
                    onSubscribed: () => ref
                        .read(communityDetailProvider(_slug).notifier)
                        .refresh(),
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
        if (articles.isEmpty)
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
              itemCount: articles.length,
              separatorBuilder: (_, _) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                return CommunityBlogCard(
                  article: articles[index],
                  community: community,
                );
              },
            ),
          ),
      ],
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

  Widget _buildHeader(CommunityDetailState state) {
    final community = state.community;
    final stats = state.stats;

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

  Widget _buildActions(CommunityDetailState state) {
    final community = state.community;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            onPressed: () => context.push(
              '/community/${community.slug}/dashboard',
              extra: community,
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
            onPressed: state.isMember
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
        if (state.followAvailable) ...[
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: state.isFollowing
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
