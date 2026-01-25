import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  final TextEditingController _fullNameController = TextEditingController(text: 'John Doe');
  final TextEditingController _usernameController = TextEditingController(text: '@johndoe_dev');
  final TextEditingController _bioController = TextEditingController(text: 'Tech enthusiast & Flutter developer. Crafting beautiful experiences with Dart! 🚀');

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery);
    if (selected != null) setState(() => _imageFile = selected);
  }

  Future<String?> _uploadProfileImage() async {
    if (_imageFile == null) return null;

    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final file = File(_imageFile!.path);
    final filePath = '${user.id}/avatar.jpg';

    await supabase.storage.from('avatars').upload(filePath, file, fileOptions: const FileOptions(upsert: true));

    final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);

    return imageUrl;
  }

  Future<void> _saveProfile() async {
  debugPrint('========== SAVE PROFILE START ==========');

  setState(() => _isLoading = true);

  try {
    final user = supabase.auth.currentUser;
    debugPrint('👤 Current user: ${user?.id}');

    if (user == null) {
      debugPrint('❌ No authenticated user');
      return;
    }

    debugPrint('✍️ Full Name: ${_fullNameController.text}');
    debugPrint('✍️ Username: ${_usernameController.text}');
    debugPrint('✍️ Bio: ${_bioController.text}');

    final imageUrl = await _uploadProfileImage();
    debugPrint('🖼 Uploaded image URL: $imageUrl');

    final response = await supabase
        .from('profiles')
        .update({
          'full_name': _fullNameController.text.trim(),
          'username': _usernameController.text.trim(),
          'bio': _bioController.text.trim(),
          if (imageUrl != null) 'avatar_url': imageUrl,
        })
        .eq('id', user.id)
        .select();

    debugPrint('✅ Supabase response: $response');
  } catch (e, st) {
    debugPrint('❌ ERROR: $e');
    debugPrint('📍 STACK TRACE: $st');
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
    return Scaffold(
      // appBar: _buildHeader(),
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
                // _buildChangePhotoButton(),
                SizedBox(height: 25.h),
                CustomTextField(label: 'Full Name', hintText: 'John Doe', controller: _fullNameController),
                SizedBox(height: 20.h),
                CustomTextField(label: 'Username', hintText: '@johndoe_dev', controller: _usernameController),
                SizedBox(height: 20.h),
                CustomTextField(label: 'Bio', hintText: 'Bio', controller: _bioController, maxLines: 3),
                SizedBox(height: 30.h),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AppBar(
      title: Text("Edit Profile"),
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60.r,
          backgroundColor: Colors.grey[300],
          backgroundImage: _imageFile != null ? FileImage(File(_imageFile!.path)) : null,
          child: _imageFile == null ? Icon(Icons.person, size: 60.r, color: Colors.grey[400]) : null,
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 32,
            width: 32,
            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildChangePhotoButton() {
    return TextButton(
      onPressed: _pickImage,
      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      child: Text(
        'Change Photo',
        style: TextStyle(color: Colors.blue, fontSize: 14.sp, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
