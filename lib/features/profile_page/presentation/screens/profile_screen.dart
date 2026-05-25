import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/home_page/data/datasource/blog_remote_datasource.dart';
import 'package:Readme/features/home_page/data/repositories/blog_repository_impl.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:Readme/features/profile_page/presentation/widgets/profile_blog_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/widgets/gradient_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  late final _blogRepository = BlogRepositoryImpl(
    BlogRemoteDatasource(_supabase),
  );

  User? _user;
  Map<String, dynamic>? _profileData;
  List<Blog> _publishedBlogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _user = _supabase.auth.currentUser;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle();
      final publishedBlogs =
          await _blogRepository.getBlogsByAuthor(_user!.id);

      if (!mounted) return;
      setState(() {
        _profileData = profileData;
        _publishedBlogs = publishedBlogs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _userName =>
      _profileData?['name'] ??
      _profileData?['full_name'] ??
      _profileData?['username'] ??
      _user?.userMetadata?['full_name'] ??
      _user?.userMetadata?['name'] ??
      _user?.userMetadata?['username'] ??
      'User';

  String get _subtitle {
    final headline = _profileData?['headline'] as String?;
    final bio = _profileData?['bio'] as String?;
    if (headline != null && headline.trim().isNotEmpty) return headline.trim();
    if (bio != null && bio.trim().isNotEmpty) return bio.trim();
    return '';
  }

  String? get _avatarUrl =>
      _profileData?['avatar_url'] ?? _user?.userMetadata?['avatar_url'];

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 100.h),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        SizedBox(height: 32.h),
                        Divider(color: Colors.grey.shade200, height: 1),
                        SizedBox(height: 24.h),
                        _buildPublishedSection(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 52.r,
          backgroundColor: Colors.grey.shade100,
          backgroundImage: imageProviderFromSource(_avatarUrl),
          child: _avatarUrl == null
              ? Icon(Icons.person, size: 52.r, color: Colors.grey.shade400)
              : null,
        ),
        SizedBox(height: 16.h),
        Text(
          _userName,
          textAlign: TextAlign.center,
          style: textStyle_24BoldBlack().copyWith(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          _subtitle,
          textAlign: TextAlign.center,
          style: textStyle_14RegularGrey().copyWith(
            fontSize: 14.sp,
            height: 1.5,
            color: AppColors.subtitles,
          ),
        ),
        SizedBox(height: 20.h),
        OutlinedButton(
          onPressed: () => context.go('/edit_profile'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.black,
            side: BorderSide(color: Colors.grey.shade200),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
          ),
          child: Text(
            'Edit Profile',
            style: textStyle_16BoldBlack().copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPublishedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PUBLISHED',
          style: textStyle_12RegularGrey().copyWith(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.subtitles,
          ),
        ),
        SizedBox(height: 16.h),
        if (_publishedBlogs.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 32.h),
            child: Center(
              child: Text(
                'No published articles yet',
                style: textStyle_14RegularGrey().copyWith(fontSize: 14.sp),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _publishedBlogs.length,
            separatorBuilder: (_, __) => SizedBox(height: 16.h),
            itemBuilder: (context, index) {
              final blog = _publishedBlogs[index];
              return ProfileBlogCard(
                blog: blog,
                onEdit: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Blog editing coming soon')),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
