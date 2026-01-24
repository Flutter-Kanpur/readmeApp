import 'package:Readme/core/utils/string_extensions.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:Readme/features/home_page/presentation/utils/blog_category_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kanpur_ui_kit/flutter_kanpur_ui_kit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:Readme/features/home_page/data/datasource/blog_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Readme/features/home_page/data/repositories/blog_repository_impl.dart';
import 'package:Readme/features/home_page/domain/repositories/blog_repository.dart';
import 'package:Readme/features/home_page/presentation/widgets/blogs_content.dart';
import 'package:Readme/features/home_page/presentation/widgets/tabs_container.dart';

import '../../../../shared/widgets/gradient_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final BlogRepository blogRepository;

  int bottomNavIndex = 0;

  List<Blog> allBlogs = [];
  List<String> categories = [];
  String? selectedCategory;

  @override
  void initState() {
    super.initState();

    blogRepository = BlogRepositoryImpl(
      BlogRemoteDatasource(Supabase.instance.client),
    );

    _loadBlogs();
  }

  Future<void> _loadBlogs() async {
    final blogs = await blogRepository.getBlogs();

    setState(() {
      allBlogs = blogs;
      categories = extractCategories(blogs);
      selectedCategory = categories.isNotEmpty ? categories.first : null;
    });
  }

  List<Blog> get filteredBlogs {
    if (selectedCategory == null) return allBlogs;

    return allBlogs.where((blog) => blog.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text("Readme", style: textStyle_24BoldBlack()),
          ),
        ),
        extendBody: true,
        extendBodyBehindAppBar: true,
        bottomNavigationBar: BottomNavbar(
          currentIndex: bottomNavIndex,
          onTap: (index) => setState(() => bottomNavIndex = index),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Column(
              spacing: 10.h,
              children: [
                SizedBox(
                  height: 36.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (context, index) {
                      final category = categories[index];

                      return TabsContainer(
                        text: category.smartCategoryCase(),
                        isSelected: selectedCategory == category,
                        onTap: () {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                      );
                    },
                  ),
                ),

                Expanded(child: BlogsContent(blogs: filteredBlogs)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
