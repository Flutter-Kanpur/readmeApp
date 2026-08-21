import 'package:Readme/core/state/blog_engagement_provider.dart';
import 'package:Readme/core/state/blog_feed_provider.dart';
import 'package:Readme/core/state/blog_like_provider.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:Readme/features/home_page/presentation/state/article_category_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:Readme/features/home_page/presentation/widgets/blog_card.dart';
import 'package:Readme/features/home_page/presentation/widgets/blog_card_shimmer.dart';
import 'package:Readme/features/home_page/presentation/widgets/home_articles_section.dart';
import 'package:Readme/features/home_page/presentation/widgets/home_hero_section.dart';

import '../../../../shared/widgets/category_filter_bottom_sheet.dart';
import '../../../../shared/widgets/gradient_background.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  ArticleCategoryFilter _selectedFilter = ArticleCategoryFilter.forYou;

  @override
  void initState() {
    super.initState();
    // The feed is a shared, non-autoDispose provider: only refetch if the
    // cached list has gone stale (5-min TTL), otherwise reuse it.
    ref.read(blogFeedProvider.notifier).refreshIfStale();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshBlogs() => ref.read(blogFeedProvider.notifier).refresh();

  Future<void> _preloadLikeState(List<Blog> blogs) async {
    if (blogs.isEmpty) return;
    await ref
        .read(blogLikeProvider.notifier)
        .preload(blogs.map((blog) => blog.id).toList());
  }

  List<Blog> _filtered(List<Blog> blogs) {
    return blogs
        .where(
          (blog) => matchesArticleCategoryFilter(
            blogCategory: blog.category,
            communityId: blog.communityId,
            filter: _selectedFilter,
          ),
        )
        .toList();
  }

  Future<void> _showCategoryFilters() async {
    final result = await showCategoryFilterBottomSheet(
      context,
      selected: _selectedFilter,
    );
    if (result != null && mounted) {
      setState(() => _selectedFilter = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Seed engagement counts + preload liked-state whenever the shared feed
    // yields a new list (initial fetch or pull-to-refresh). The providers are
    // persistent stores, so cards on other screens stay in sync.
    ref.listen<AsyncValue<List<Blog>>>(blogFeedProvider, (prev, next) {
      final blogs = next.value;
      if (blogs == null || identical(prev?.value, blogs)) return;
      ref.read(blogEngagementProvider.notifier).seedAll(blogs);
      _preloadLikeState(blogs);
    });

    final feedState = ref.watch(blogFeedProvider);
    final blogs = feedState.value ?? const <Blog>[];
    final isLoadingBlogs = feedState.isLoading && !feedState.hasValue;
    final filteredBlogs = _filtered(blogs);

    final topInset = MediaQuery.paddingOf(context).top;
    // final blend = _statusBarBlend;
    final statusBarStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      // statusBarBrightness: blend > 0.5 ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarStyle,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 0,
                  ),
                  child: RefreshIndicator(
                    onRefresh: _refreshBlogs,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(child: SizedBox(height: 40.h)),
                        SliverToBoxAdapter(
                          child: HomeHeroSection(
                            onStartWriting: () => context.push('/create'),
                            onExploreTopics: () => context.go('/search'),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: HomeArticlesSection(
                            onSearchTap: () => context.go('/search'),
                            onForYouTap: () {
                              setState(() {
                                _selectedFilter = ArticleCategoryFilter.forYou;
                              });
                            },
                            onFiltersTap: _showCategoryFilters,
                            isForYouSelected: _selectedFilter.isForYou,
                            hasActiveFilter: !_selectedFilter.isForYou,
                          ),
                        ),
                        if (isLoadingBlogs)
                          SliverList.separated(
                            itemCount: 5,
                            separatorBuilder: (_, __) => SizedBox(height: 16.h),
                            itemBuilder: (_, __) => const BlogCardShimmer(),
                          )
                        else if (filteredBlogs.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                'No blogs found',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          )
                        else
                          SliverList.separated(
                            itemCount: filteredBlogs.length,
                            separatorBuilder: (_, __) => SizedBox(height: 16.h),
                            itemBuilder: (context, index) {
                              return BlogCard(blog: filteredBlogs[index]);
                            },
                          ),
                        SliverToBoxAdapter(child: SizedBox(height: 80.h)),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: topInset,
                child: IgnorePointer(
                  // child: ColoredBox(
                  //   color: Colors.white.withValues(alpha: blend),
                  // ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
