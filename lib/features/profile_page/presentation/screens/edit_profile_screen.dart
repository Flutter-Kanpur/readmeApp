import 'dart:convert';
import 'dart:io';

import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _maxImageBytes = 2 * 1024 * 1024;

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingProfile = true;

  final supabase = Supabase.instance.client;
  User? _user;
  Map<String, dynamic>? _profileData;
  String _username = '';

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _headlineController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = supabase.auth.currentUser;
    _fetchProfile();
  }

  String _socialPrefsKey(String userId) => 'profile_social_$userId';

  Future<void> _fetchProfile() async {
    if (_user == null) return;

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle();

      final prefs = await SharedPreferences.getInstance();
      final socialJson = prefs.getString(_socialPrefsKey(_user!.id));
      Map<String, dynamic> social = {};
      if (socialJson != null) {
        social = jsonDecode(socialJson) as Map<String, dynamic>;
      }

      if (mounted) {
        setState(() {
          _profileData = data;
          _fullNameController.text = data?['name'] ?? '';
          _headlineController.text = data?['headline'] ?? '';
          _bioController.text = data?['bio'] ?? '';
          _username = data?['username'] ?? '';
          _twitterController.text = social['twitter'] as String? ?? '';
          _linkedinController.text = social['linkedin'] as String? ?? '';
          _websiteController.text = social['website'] as String? ?? '';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (selected == null || !mounted) return;

    final bytes = await selected.readAsBytes();
    if (bytes.length > _maxImageBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image must be 2MB or smaller.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _imageFile = selected);
  }

  Future<String?> _uploadProfileImage() async {
    if (_imageFile == null) return null;

    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final bytes = await _imageFile!.readAsBytes();
      final fileExt = _imageFile!.path.split('.').last;
      final fileName =
          'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      await supabase.storage.from('blog_images').uploadBinary(filePath, bytes);

      return supabase.storage.from('blog_images').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveSocialLinks(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _socialPrefsKey(userId),
      jsonEncode({
        'twitter': _twitterController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
        'website': _websiteController.text.trim(),
      }),
    );
  }

  Future<void> _saveProfile() async {
    final name = _fullNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final imageUrl = await _uploadProfileImage();

      final updates = <String, dynamic>{
        'name': name,
        'headline': _headlineController.text.trim(),
        'bio': _bioController.text.trim(),
      };

      if (_username.isNotEmpty) {
        updates['username'] = _username;
      }

      if (imageUrl != null) {
        updates['avatar_url'] = imageUrl;
      }

      await supabase.from('profiles').update(updates).eq('id', user.id);
      await _saveSocialLinks(user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _headlineController.dispose();
    _bioController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBackLink(),
                    SizedBox(height: 16.h),
                    Text(
                      'Edit Profile',
                      style: textStyle_24BoldBlack().copyWith(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    _buildPhotoSection(),
                    SizedBox(height: 32.h),
                    _buildLabeledField(
                      label: 'FULL NAME',
                      child: _ProfileTextField(
                        controller: _fullNameController,
                        hintText: 'Your full name',
                      ),
                    ),
                    SizedBox(height: 24.h),
                    _buildLabeledField(
                      label: 'PROFESSIONAL TITLE / HEADLINE',
                      child: _ProfileTextField(
                        controller: _headlineController,
                        hintText: 'A community for Flutter enthusiasts & developers...',
                      ),
                    ),
                    SizedBox(height: 24.h),
                    _buildLabeledField(
                      label: 'BIO',
                      child: _ProfileTextField(
                        controller: _bioController,
                        hintText: 'Tell us about yourself',
                        maxLines: 5,
                        minHeight: 120.h,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'SOCIAL LINKS',
                      style: textStyle_12RegularGrey().copyWith(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: AppColors.subtitles,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileTextField(
                            controller: _twitterController,
                            hintText: 'Twitter URL',
                            keyboardType: TextInputType.url,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _ProfileTextField(
                            controller: _linkedinController,
                            hintText: 'LinkedIn URL',
                            keyboardType: TextInputType.url,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    _ProfileTextField(
                      controller: _websiteController,
                      hintText: 'Personal Website URL',
                      keyboardType: TextInputType.url,
                    ),
                    SizedBox(height: 32.h),
                    _buildSaveButton(),
                    SizedBox(height: 32.h),
                    _buildPreferencesCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBackLink() {
    return GestureDetector(
      onTap: () => context.go('/profile'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back, size: 18.sp, color: AppColors.linkBlue),
          SizedBox(width: 6.w),
          Text(
            'Back to Profile',
            style: textStyle_14RegularBlack().copyWith(
              fontSize: 14.sp,
              color: AppColors.linkBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    final String? avatarUrl = _profileData?['avatar_url'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 44.r,
          backgroundColor: Colors.grey.shade100,
          backgroundImage: _imageFile != null
              ? FileImage(File(_imageFile!.path))
              : imageProviderFromSource(avatarUrl),
          child: (_imageFile == null && avatarUrl == null)
              ? Icon(Icons.person, size: 44.r, color: Colors.grey.shade400)
              : null,
        ),
        SizedBox(width: 16.w),
        OutlinedButton(
          onPressed: _pickImage,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.black,
            side: BorderSide(color: Colors.grey.shade200),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
          child: Text(
            'Change\nPhoto',
            textAlign: TextAlign.center,
            style: textStyle_14RegularBlack().copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            'JPG, GIF or PNG. Max size 2MB.',
            style: textStyle_12RegularGrey().copyWith(
              fontSize: 12.sp,
              color: AppColors.subtitles,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textStyle_12RegularGrey().copyWith(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: AppColors.subtitles,
          ),
        ),
        SizedBox(height: 10.h),
        child,
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          disabledBackgroundColor: Colors.grey.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 22.h,
                width: 22.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Save Changes',
                style: textStyle_16BoldBlack().copyWith(
                  fontSize: 15.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        'Preferences',
        style: textStyle_16BoldBlack().copyWith(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.minHeight,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final double? minHeight;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: minHeight != null
          ? BoxConstraints(minHeight: minHeight!)
          : BoxConstraints(minHeight: 48.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      alignment: maxLines > 1 ? Alignment.topLeft : Alignment.centerLeft,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: textStyle_14RegularBlack().copyWith(fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: textStyle_14RegularGrey().copyWith(
            fontSize: 14.sp,
            color: AppColors.subtitles,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
        ),
      ),
    );
  }
}
