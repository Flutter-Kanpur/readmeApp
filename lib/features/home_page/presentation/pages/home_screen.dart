import 'package:Readme/core/utils/string_extensions.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:Readme/features/home_page/presentation/utils/blog_category_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:Readme/features/home_page/data/datasource/blog_remote_datasource.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Readme/features/home_page/data/repositories/blog_repository_impl.dart';
import 'package:Readme/features/home_page/domain/repositories/blog_repository.dart';
import 'package:Readme/features/home_page/presentation/widgets/blog_card.dart';
import 'package:Readme/features/home_page/presentation/widgets/blog_card_shimmer.dart';
import 'package:Readme/features/home_page/presentation/widgets/home_articles_section.dart';
import 'package:Readme/features/home_page/presentation/widgets/home_hero_section.dart';

import '../../../../shared/widgets/gradient_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final BlogRepository blogRepository;

  List<Blog> allBlogs = [];
  List<String> categories = [];
  bool _isForYou = true;
  String? _selectedFilterCategory;
  bool _isLoadingBlogs = true;

  @override
  void initState() {
    super.initState();

    blogRepository = BlogRepositoryImpl(
      BlogRemoteDatasource(Supabase.instance.client),
    );

    _loadBlogs();
  }

  Future<void> _loadBlogs() async {
    if (!mounted) return;
    setState(() => _isLoadingBlogs = true);

    final blogs = await blogRepository.getBlogs();

    if (!mounted) return;
    setState(() {
      allBlogs = blogs;
      categories = extractCategories(blogs);
      _isForYou = true;
      _selectedFilterCategory = null;
      _isLoadingBlogs = false;
    });
  }

  List<Blog> get filteredBlogs {
    if (_isForYou || _selectedFilterCategory == null) return allBlogs;
    return allBlogs
        .where((blog) => blog.category == _selectedFilterCategory)
        .toList();
  }

  void _showCategoryFilters() {
    if (categories.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Filter by topic',
                  style: textStyle_16BoldBlack().copyWith(fontSize: 18.sp),
                ),
                SizedBox(height: 16.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: categories.map((category) {
                    final isSelected = _selectedFilterCategory == category;
                    return FilterChip(
                      label: Text(category.smartCategoryCase()),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _isForYou = false;
                          _selectedFilterCategory = category;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: CustomScrollView(
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
                        _isForYou = true;
                        _selectedFilterCategory = null;
                      });
                    },
                    onFiltersTap: _showCategoryFilters,
                    isForYouSelected: _isForYou,
                    hasActiveFilter: !_isForYou && _selectedFilterCategory != null,
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
      ),
    );
  }
}
