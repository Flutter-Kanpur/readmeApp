import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

// --- DATA MODEL ---
class StoryModel {
  final String category;
  final String source;
  final String title;
  final String readTime;
  final String date;
  final Color tagColor;

  StoryModel({
    required this.category,
    required this.source,
    required this.title,
    required this.readTime,
    required this.date,
    required this.tagColor,
  });
}


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final List<StoryModel> myStories = [
    StoryModel(category: "TECH", tagColor: Colors.green, source: "Flutter Kanpur", title: "State Management", readTime: "5 min read", date: "Oct 12"),
    StoryModel(category: "UI/UX", tagColor: Colors.purple, source: "Readme App", title: "Designing for Super Apps", readTime: "8 min read", date: "Sep 28"),
    StoryModel(category: "DEV", tagColor: Colors.orange, source: "Medium", title: "Clean Architecture in Flutter", readTime: "10 min read", date: "Sep 15"),
    StoryModel(category: "DART", tagColor: Colors.blue, source: "Dart.dev", title: "Mastering Patterns & Records", readTime: "6 min read", date: "Sep 01"),
    StoryModel(category: "CAREER", tagColor: Colors.red, source: "LinkedIn", title: "Landing your firstJob", readTime: "4 min read", date: "Aug 20"),
  ];

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery);
    if (selected != null) setState(() => _imageFile = selected);
  }

  @override
  Widget build(BuildContext context) {
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
        Text('Readme', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
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
          child: _imageFile == null 
              ? Icon(Icons.person, size: 60.r, color: Colors.grey[400]) 
              : null,
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
        Text('BadMos', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
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
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D1B2A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
          elevation: 0,
        ),
        child: Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem("1.2k", "FOLLOWERS"),
        _buildStatItem("450", "FOLLOWING"),
        _buildStatItem("15k", "READS"),
      ],
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Container(
      width: 100.w,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 4.h),
          Text(label, style: TextStyle(fontSize: 9.sp, color: Colors.grey, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: TabBar(
        indicatorColor: const Color(0xFF2ECC71),
        indicatorWeight: 3,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
        tabs: const [Tab(text: "My Stories"), Tab(text: "Saved"), Tab(text: "Claps")],
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
            itemBuilder: (context, index) => _buildStoryTile(myStories[index]),
          ),
          const Center(child: Text("No saved stories")),
          const Center(child: Text("No claps yet")),
        ],
      ),
    );
  }

  Widget _buildStoryTile(StoryModel story) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: story.tagColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(story.category, style: TextStyle(color: story.tagColor, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(width: 8.w),
                    Text(story.source, style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(story.title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold), maxLines: 2),
                SizedBox(height: 4.h),
                Text("${story.readTime} • ${story.date}", style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
              ],
            ),
          ),
          SizedBox(width: 15.w),
          Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.description_outlined, color: Colors.grey[400], size: 30.sp),
          ),
        ],
      ),
    );
  }
}