import 'package:Readme/core/utils/text_style.dart';
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
  int bottomNavIndex = 0;
  int selectedFilterIndex = 0;

  late final BlogRepository blogRepository;

  @override
  void initState() {
    super.initState();

    blogRepository = BlogRepositoryImpl(
      BlogRemoteDatasource(Supabase.instance.client),
    );
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
            child: Text(
              "Readme",
              style: textStyle_24BoldBlack(),
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 10),
            child: Column(
              spacing:  10.h,
              children: [
                Row(
                  spacing: 8.w,
                  children: [
                    TabsContainer(
                      text: "For You",
                      isSelected: selectedFilterIndex == 0,
                      onTap: () => setState(() => selectedFilterIndex = 0),
                    ),
                    TabsContainer(
                      text: "Flutter",
                      isSelected: selectedFilterIndex == 1,
                      onTap: () => setState(() => selectedFilterIndex = 1),
                    ),
                    TabsContainer(
                      text: "UI",
                      isSelected: selectedFilterIndex == 2,
                      onTap: () => setState(() => selectedFilterIndex = 2),
                    ),
                  ],
                ),
                Expanded(child: buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildContent() {
    switch (selectedFilterIndex) {
      case 0:
        return BlogsContent(
          category: 'for_you',
          blogRepository: blogRepository,
        );
      case 1:
        return BlogsContent(
          category: 'flutter',
          blogRepository: blogRepository,
        );
      case 2:
        return BlogsContent(
          category: 'ui',
          blogRepository: blogRepository,
        );
      default:
        return BlogsContent(
          category: 'for_you',
          blogRepository: blogRepository,
        );
    }
  }
}
