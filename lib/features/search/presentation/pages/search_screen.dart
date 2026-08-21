import 'package:Readme/core/state/blog_engagement_provider.dart';
import 'package:Readme/core/state/blog_feed_provider.dart';
import 'package:Readme/core/state/blog_like_provider.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:Readme/features/home_page/presentation/state/article_category_filters.dart';
import 'package:Readme/features/home_page/presentation/widgets/blog_card.dart';
import 'package:Readme/features/home_page/presentation/widgets/blog_card_shimmer.dart';
import 'package:Readme/features/search/data/models/explore_article_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/category_filter_bottom_sheet.dart';
import '../../../../shared/widgets/gradient_background.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  ArticleCategoryFilter _selectedFilter = ArticleCategoryFilter.forYou;

  @override
  void initState() {
    super.initState();
    // Reuses the shared feed provider (same blogs as Home); only refetch when
    // the cached list is stale.
    ref.read(blogFeedProvider.notifier).refreshIfStale();
  }

  Future<void> _refresh() => ref.read(blogFeedProvider.notifier).refresh();

  Future<void> _preloadLikeState(List<Blog> blogs) async {
    if (blogs.isEmpty) return;
    await ref
        .read(blogLikeProvider.notifier)
        .preload(blogs.map((blog) => blog.id).toList());
  }

  ExploreArticle _toArticle(Blog blog) => ExploreArticle(
    blog: blog,
    authors: blog.allAuthors,
    communityName: blog.communityName,
    communityLogoUrl: blog.communityLogoUrl,
  );

  List<ExploreArticle> _filtered(List<ExploreArticle> articles) {
    return articles.where((article) {
      if (_selectedFilter.communitiesOnly) {
        return article.communityName != null &&
            article.communityName!.trim().isNotEmpty;
      }
      return matchesArticleCategoryFilter(
        blogCategory: article.blog.category,
        communityId: article.blog.communityId,
        filter: _selectedFilter,
      );
    }).toList();
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
    ref.listen<AsyncValue<List<Blog>>>(blogFeedProvider, (prev, next) {
      final blogs = next.value;
      if (blogs == null || identical(prev?.value, blogs)) return;
      ref.read(blogEngagementProvider.notifier).seedAll(blogs);
      _preloadLikeState(blogs);
    });

    final feedState = ref.watch(blogFeedProvider);
    final blogs = feedState.value ?? const <Blog>[];
    final isLoading = feedState.isLoading && !feedState.hasValue;
    final filteredArticles = _filtered(blogs.map(_toArticle).toList());

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BROWSE THE LIBRARY',
                          style: textStyle_12RegularGrey().copyWith(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: AppColors.subtitles,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Explore Articles',
                          style: textStyle_24BoldBlack().copyWith(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Discover stories, thinking, and expertise from writers across the community.',
                          style: textStyle_16RegularGrey().copyWith(
                            fontSize: 15.sp,
                            height: 1.5,
                            color: AppColors.subtitles,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          children: [
                            _FilterChip(
                              label: 'For You',
                              isSelected: _selectedFilter.isForYou,
                              onTap: () {
                                setState(() {
                                  _selectedFilter =
                                      ArticleCategoryFilter.forYou;
                                });
                              },
                            ),
                            const Spacer(),
                            _FilterChip(
                              label: 'Filters',
                              icon: Icons.tune_rounded,
                              isSelected: !_selectedFilter.isForYou,
                              onTap: _showCategoryFilters,
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    sliver: SliverList.separated(
                      itemCount: 4,
                      separatorBuilder: (_, __) => SizedBox(height: 16.h),
                      itemBuilder: (_, __) => const BlogCardShimmer(),
                    ),
                  )
                else if (filteredArticles.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'No articles found',
                        style: textStyle_14RegularGrey().copyWith(
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 100.h),
                    sliver: SliverList.separated(
                      itemCount: filteredArticles.length,
                      separatorBuilder: (_, __) => SizedBox(height: 16.h),
                      itemBuilder: (context, index) {
                        return BlogCard(blog: filteredArticles[index].blog);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.black : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: isSelected ? null : Border.all(color: Colors.grey.shade200),
            boxShadow: isSelected
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18.sp,
                    color: isSelected ? Colors.white : AppColors.subtitles,
                  ),
                  SizedBox(width: 6.w),
                ],
                Text(
                  label,
                  style: textStyle_14RegularBlack().copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.subtitles,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
