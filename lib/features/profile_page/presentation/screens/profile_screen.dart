import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_kanpur_ui_kit/flutter_kanpur_ui_kit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/story.dart';
import '../widgets/stat_item.dart';
import '../widgets/story_tile.dart';
import '../../../../shared/widgets/gradient_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final _supabase = Supabase.instance.client;
  User? _user;
  Map<String, dynamic>? _profileData;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _user = _supabase.auth.currentUser;
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (_user == null) return;

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  final List<Story> myStories = [
    Story(
      category: "TECH",
      tagColor: Colors.green,
      source: "Flutter Kanpur",
      title: "State Management",
      readTime: "5 min read",
      date: "Oct 12",
    ),
    Story(
      category: "UI/UX",
      tagColor: Colors.purple,
      source: "Readme App",
      title: "Designing for Super Apps",
      readTime: "8 min read",
      date: "Sep 28",
    ),
    Story(
      category: "DEV",
      tagColor: Colors.orange,
      source: "Medium",
      title: "Clean Architecture in Flutter",
      readTime: "10 min read",
      date: "Sep 15",
    ),
    Story(
      category: "DART",
      tagColor: Colors.blue,
      source: "Dart.dev",
      title: "Mastering Patterns & Records",
      readTime: "6 min read",
      date: "Sep 01",
    ),
    Story(
      category: "CAREER",
      tagColor: Colors.red,
      source: "LinkedIn",
      title: "Landing your firstJob",
      readTime: "4 min read",
      date: "Aug 20",
    ),
  ];

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (selected != null) setState(() => _imageFile = selected);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.chevron_left, size: 28, color: Colors.black),
              onPressed: () => context.go('/home'),
              padding: EdgeInsets.zero,
            ),
            title: Text(
              'Profile',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
          ),
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
                          _buildProfileAvatar(),
                          SizedBox(height: 15.h),
                          _buildNameAndBio(),
                          SizedBox(height: 20.h),
                          _buildEditButton(),
                          SizedBox(height: 25.h),
                          _buildTabBar(),
                          _buildTabContent(),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final String? avatarUrl =
        _profileData?['avatar_url'] ?? _user?.userMetadata?['avatar_url'];

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60.r,
          backgroundColor: Colors.grey[100],
          backgroundImage: _imageFile != null
              ? FileImage(File(_imageFile!.path))
              : (avatarUrl != null ? NetworkImage(avatarUrl) : null)
                    as ImageProvider?,
          child: (_imageFile == null && avatarUrl == null)
              ? Icon(Icons.person, size: 60.r, color: Colors.grey[400])
              : null,
        ),
      ],
    );
  }

  Widget _buildNameAndBio() {
    final String userName =
        _profileData?['full_name'] ??
        _profileData?['name'] ??
        _user?.userMetadata?['full_name'] ??
        'User';
    final String bio =
        _profileData?['bio'] ??
        'Flutter Developer & Tech Blogger.\nExploring the future of cross-platform apps.';

    return Column(
      children: [
        Text(
          userName,
          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        Text(
          bio,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return GradientButton(
      height: 45.h,
      text: "Edit Profile",
      textStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold
      ),
      onTap: () {
        context.go("/edit_profile");
      },
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
