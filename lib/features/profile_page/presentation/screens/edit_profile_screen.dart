import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_image.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/textfield.dart';
import '../../../../shared/widgets/gradient_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingProfile = true;

  final supabase = Supabase.instance.client;
  User? _user;
  Map<String, dynamic>? _profileData;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = supabase.auth.currentUser;
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (_user == null) return;

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _profileData = data;
          _fullNameController.text = data?['name'] ?? '';
          _usernameController.text = data?['username'] ?? '';
          _bioController.text =
              data?['bio'] ?? 'Flutter developer and tech explorer';
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

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (selected != null) setState(() => _imageFile = selected);
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

      final imageUrl = supabase.storage
          .from('blog_images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  String _generateUsername(String name) {
    String cleanName = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();

    if (cleanName.isEmpty) {
      cleanName = 'user';
    }

    final random = Random();
    final randomNumber = 1000 + random.nextInt(9000);

    return '${cleanName}_$randomNumber';
  }

  Future<void> _saveProfile() async {
    debugPrint('========== SAVE PROFILE START ==========');

    final name = _fullNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      debugPrint('👤 Current user: ${user?.id}');

      if (user == null) {
        debugPrint('❌ No authenticated user');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Generate username if empty
      String username = _usernameController.text.trim();
      if (username.isEmpty) {
        username = _generateUsername(name);
        _usernameController.text = username;
      }

      debugPrint('✍️ Full Name: $name');
      debugPrint('✍️ Username: $username');
      debugPrint('✍️ Bio: ${_bioController.text}');

      final imageUrl = await _uploadProfileImage();
      debugPrint('🖼 Uploaded image URL: $imageUrl');

      final Map<String, dynamic> updates = {
        'name': name,
        'username': username,
        'bio': _bioController.text.trim(),
      };

      if (imageUrl != null) {
        updates['avatar_url'] = imageUrl;
      }

      final response = await supabase
          .from('profiles')
          .update(updates)
          .eq('id', user.id)
          .select();

      debugPrint('✅ Supabase response: $response');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/profile');
      }
    } catch (e, st) {
      debugPrint('❌ ERROR: $e');
      debugPrint('📍 STACK TRACE: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
      debugPrint('========== SAVE PROFILE END ==========');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, size: 28, color: Colors.black),
            onPressed: () => context.go('/profile'),
            padding: EdgeInsets.zero,
          ),
          title: Text(
            'Edit Profile',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _isLoadingProfile
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    child: Column(
                      children: [
                        _buildProfileAvatar(),
                        SizedBox(height: 10.h),
                        _buildChangePhotoButton(),
                        SizedBox(height: 30.h),
                        _buildLabeledField(
                          label: 'Full Name',
                          child: CustomTextField(
                            text: 'John Doe',
                            controller: _fullNameController,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _buildLabeledField(
                          label: 'Username',
                          child: CustomTextField(
                            text: '@johndoe_dev',
                            controller: _usernameController,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _buildLabeledField(
                          label: 'Bio',
                          child: CustomTextField(
                            text: 'Tell us about yourself',
                            controller: _bioController,
                            maxLines: 5,
                          ),
                        ),
                        SizedBox(height: 40.h),
                        _buildSaveButton(),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final String? avatarUrl = _profileData?['avatar_url'];

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60.r,
          backgroundColor: Colors.grey[300],
          backgroundImage: _imageFile != null
              ? FileImage(File(_imageFile!.path))
              : imageProviderFromSource(avatarUrl),
          child: (_imageFile == null && avatarUrl == null)
              ? Icon(Icons.person, size: 60.r, color: Colors.grey[400])
              : null,
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildChangePhotoButton() {
    return TextButton(
      onPressed: _pickImage,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Change Photo',
        style: TextStyle(
          color: Colors.blue[600],
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        child,
      ],
    );
  }

  Widget _buildSaveButton() {
    return GradientButton(
      text: 'Save Changes',
      onTap: _saveProfile,
      loading: _isLoading,
      height: 55.h,
      width: double.infinity,
    );
  }
}
