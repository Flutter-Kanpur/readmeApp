import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/story.dart';
import '../widgets/stat_item.dart';
import '../widgets/story_tile.dart';
<<<<<<< Updated upstream
import 'edit_profile_screen.dart';
=======
import '../../../../shared/widgets/gradient_background.dart';
>>>>>>> Stashed changes

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final List<Story> myStories = [
    Story(category: "TECH", tagColor: Colors.green, source: "Flutter Kanpur", title: "State Management", readTime: "5 min read", date: "Oct 12"),
    Story(category: "UI/UX", tagColor: Colors.purple, source: "Readme App", title: "Designing for Super Apps", readTime: "8 min read", date: "Sep 28"),
    Story(category: "DEV", tagColor: Colors.orange, source: "Medium", title: "Clean Architecture in Flutter", readTime: "10 min read", date: "Sep 15"),
    Story(category: "DART", tagColor: Colors.blue, source: "Dart.dev", title: "Mastering Patterns & Records", readTime: "6 min read", date: "Sep 01"),
    Story(category: "CAREER", tagColor: Colors.red, source: "LinkedIn", title: "Landing your firstJob", readTime: "4 min read", date: "Aug 20"),
  ];

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery);
    if (selected != null) setState(() => _imageFile = selected);
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 25.h),
                  _buildProfileAvatar(),
                  SizedBox(height: 15.h),
                  _buildNameAndBio(),
                  SizedBox(height: 20.h),
                  _buildEditButton(),
                  SizedBox(height: 25.h),
                  _buildStatsRow(),
                  SizedBox(height: 25.h),
                  _buildTabBar(),
                  _buildTabContent(),
                ],
              ),
            ),
=======
    return GradientBackground(
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: SafeArea(
            child: _isLoadingProfile
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 20.w,
                        right: 20.w,
                        top: 10.h,
                        bottom: 100.h, // Extra padding for bottom nav bar
                      ),
                      child: Column(
                        children: [
                          _buildHeader(),
                          SizedBox(height: 25.h),
                          _buildProfileAvatar(),
                          SizedBox(height: 15.h),
                          _buildNameAndBio(),
                          SizedBox(height: 20.h),
                          _buildEditButton(),
                          SizedBox(height: 25.h),
                          _buildStatsRow(),
                          SizedBox(height: 25.h),
                          _buildTabBar(),
                          _buildTabContent(),
                        ],
                      ),
                    ),
                  ),
>>>>>>> Stashed changes
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Icon(Icons.chevron_left, size: 30),
        Text(
          'Readme',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        const Icon(Icons.settings, size: 24),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60.r,
          backgroundColor: Colors.grey[100],
          backgroundImage: _imageFile != null ? FileImage(File(_imageFile!.path)) : null,
          child: _imageFile == null ? Icon(Icons.person, size: 60.r, color: Colors.grey[400]) : null,
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFF2ECC71), shape: BoxShape.circle),
            child: const Icon(Icons.edit, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildNameAndBio() {
    return Column(
      children: [
        Text(
          'BadMos',
          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        Text(
          'Flutter Developer & Tech Blogger.\nExploring the future of cross-platform apps.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.sp, color: Colors.grey[600], height: 1.4),
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EditProfileScreen()));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D1B2A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
          elevation: 0,
        ),
        child: Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        StatItem(count: "1.2k", label: "FOLLOWERS"),
        StatItem(count: "450", label: "FOLLOWING"),
        StatItem(count: "15k", label: "READS"),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: TabBar(
        indicatorColor: const Color(0xFF2ECC71),
        indicatorWeight: 3,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
        tabs: const [
          Tab(text: "My Stories"),
          Tab(text: "Saved"),
          Tab(text: "Claps"),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: (myStories.length * 110.h) + 20.h,
      child: TabBarView(
        children: [
          ListView.builder(
            padding: EdgeInsets.only(top: 15.h),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: myStories.length,
            itemBuilder: (context, index) => StoryTile(story: myStories[index]),
          ),
          const Center(child: Text("No saved stories")),
          const Center(child: Text("No claps yet")),
        ],
      ),
    );
  }
}
