import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:Readme/features/home_page/presentation/state/article_category_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:Readme/features/home_page/data/datasource/blog_remote_datasource.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Readme/features/home_page/data/repositories/blog_repository_impl.dart';
import 'package:Readme/features/home_page/domain/repositories/blog_repository.dart';
import 'package:Readme/features/home_page/presentation/widgets/blog_card.dart';
import 'package:Readme/features/home_page/presentation/widgets/blog_card_shimmer.dart';
import 'package:Readme/features/home_page/presentation/widgets/home_articles_section.dart';
import 'package:Readme/features/home_page/presentation/widgets/home_hero_section.dart';

import '../../../../shared/widgets/category_filter_bottom_sheet.dart';
import '../../../../shared/widgets/gradient_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final BlogRepository blogRepository;
  final ScrollController _scrollController = ScrollController();

  List<Blog> allBlogs = [];
  ArticleCategoryFilter _selectedFilter = ArticleCategoryFilter.forYou;
  bool _isLoadingBlogs = true;
  double _scrollOffset = 0;

  static const double _statusBarFadeDistance = 72;

  @override
  void initState() {
    super.initState();

    blogRepository = BlogRepositoryImpl(
      BlogRemoteDatasource(Supabase.instance.client),
    );

    _scrollController.addListener(_onScroll);
    _loadBlogs();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    if ((offset - _scrollOffset).abs() < 0.5) return;
    setState(() => _scrollOffset = offset);
  }

  double get _statusBarBlend =>
      (_scrollOffset / _statusBarFadeDistance).clamp(0.0, 1.0);

  Future<void> _loadBlogs() async {
    if (!mounted) return;
    setState(() => _isLoadingBlogs = true);

    final blogs = await blogRepository.getBlogs();

    if (!mounted) return;
    setState(() {
      allBlogs = blogs;
      _selectedFilter = ArticleCategoryFilter.forYou;
      _isLoadingBlogs = false;
    });
  }

  List<Blog> get filteredBlogs {
    return allBlogs
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
        // appBar: AppBar(
        //   forceMaterialTransparency: true,
        //   automaticallyImplyLeading: false,
        //   backgroundColor: Colors.transparent,
        //   title: Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 8.0),
        //     child: Row(
        //       children: [
        //         ClipRRect(
        //             borderRadius: BorderRadius.circular(5),
        //             child: Container(
        //                 color: Colors.black,
        //                 height: 30.h,
        //                 width: 30.w,
        //                 child: Padding(
        //                   padding: const EdgeInsets.all(4.0),
        //                   child: SvgPicture.asset("assets/icons/logo.svg"),
        //                 ))),
        //         10.horizontalSpace,
        //         Text("Readme", style: textStyle_24BoldBlack().copyWith(
        //           fontSize: 20.sp,
        //           fontWeight: FontWeight.w700,
        //         )),
        //       ],
        //     ),
        //   ),
        // ),
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: 40.h),
                ),
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
                if (_isLoadingBlogs)
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
