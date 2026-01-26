import 'dart:convert';
import 'dart:io';

import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/create_blog_page/presentation/widgets/editor_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kanpur_ui_kit/flutter_kanpur_ui_kit.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateBlogScreen extends StatefulWidget {
  const CreateBlogScreen({super.key});

  @override
  State<CreateBlogScreen> createState() => _CreateBlogScreenState();
}

class _CreateBlogScreenState extends State<CreateBlogScreen> {
  static const _draftTitleKey = 'draft_title';
  static const _draftContentKey = 'draft_content';
  static const _userNameKey = 'user_name';
  static const _userImageKey = 'user_profile_pic';

  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController titleController = TextEditingController();

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController.basic();
    _loadDraft();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    titleController.dispose();
    super.dispose();
  }

  // ================== LOAD DRAFT ==================
  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTitle = prefs.getString(_draftTitleKey);
    final savedContent = prefs.getString(_draftContentKey);

    if (savedTitle != null) titleController.text = savedTitle;

    if (savedContent != null) {
      final delta = Delta.fromJson(jsonDecode(savedContent));
      _controller = quill.QuillController(
        document: quill.Document.fromDelta(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
      setState(() {});
    }
  }

  // ================== AUTHOR ==================
  Future<Map<String, String?>> _getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_userNameKey),
      'image': prefs.getString(_userImageKey),
    };
  }

  // ================== SAVE DRAFT ==================
  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftTitleKey, titleController.text.trim());
    await prefs.setString(
      _draftContentKey,
      jsonEncode(_controller.document.toDelta().toJson()),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Draft saved locally")),
    );
  }

  // ================== CLEAR DRAFT ==================
  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftTitleKey);
    await prefs.remove(_draftContentKey);
  }

  // ================== UPLOAD IMAGES ON PUBLISH ==================
  Future<Map<String, dynamic>> _extractImagesWithPlaceholders(
      List<dynamic> deltaOps) async {

    final List<String> imagePaths = [];
    final List<dynamic> cleanedOps = [];
    String? coverImageUrl;
    int imageIndex = 0;

    for (final op in deltaOps) {
      // IMAGE OP
      if (op is Map &&
          op['insert'] is Map &&
          op['insert']['image'] is String) {

        final imageValue = op['insert']['image'] as String;

        if (!imageValue.startsWith('http')) {
          final file = File(imageValue);
          final bytes = await file.readAsBytes();

          final fileName =
              'blogs/${DateTime.now().millisecondsSinceEpoch}.jpg';

          await supabase.storage
              .from('blog_images')
              .uploadBinary(fileName, bytes);

          // ✅ Save path
          imagePaths.add(fileName);

          // ✅ Set cover image ONLY ONCE (first image)
          coverImageUrl ??= supabase.storage
              .from('blog_images')
              .getPublicUrl(fileName);


          // ✅ Insert placeholder to preserve order
          cleanedOps.add({
            'insert': '[[IMAGE$imageIndex]]\n',
          });

          imageIndex++;
        }
        continue;
      }

      cleanedOps.add(op);
    }

    return {
      'content': cleanedOps,
      'image_paths': imagePaths,
      'cover_image': coverImageUrl, // 👈 NEW
    };
  }



  // ================== PUBLISH ==================
  Future<void> _publishBlog() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title cannot be empty")),
      );
      return;
    }

    try {
      final rawDelta = _controller.document.toDelta().toJson();
      final result = await _extractImagesWithPlaceholders(rawDelta);

      await supabase.from('blogs').insert({
        'title': title,
        'content': jsonEncode(result['content']),
        'image_paths': result['image_paths'],
        'cover_image': result['cover_image'], // ✅ HERE
        'author_id': supabase.auth.currentUser!.id,
        'is_published': true,
      });
      await _clearDraft();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Blog published successfully")),
      );

      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: EditorToolbar(
        controller: _controller,
        focusNode: _focusNode,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _topBar(),
              const Divider(),
              _titleBar(),
              _authorBlock(),
              Expanded(
                child: Padding(
                  padding:  EdgeInsets.only(bottom: 100.sp),
                  child: quill.QuillEditor(
                    controller: _controller,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                    config: quill.QuillEditorConfig(
                      placeholder: 'Start writing your blog...',
                      embedBuilders:
                      FlutterQuillEmbeds.editorBuilders(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
        Row(
          spacing: 8.sp,
          children: [
            TextButton(
              onPressed: _saveDraft,
              child: Text(
                "Draft saved",
                style: textStyle_12RegularGrey().copyWith(fontSize: 14.sp),
              ),
            ),
            GestureDetector(
              onTap: _publishBlog,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgBlue,
                  borderRadius: BorderRadius.circular(25.r),
                ),
                height: 40.h,
                width: 100.w,
                child: GradientButton(
                  onTap: _publishBlog,
                  text:
                    "Publish",
                  ),
                ),

            ),
          ],
        ),
      ],
    );
  }

  Widget _titleBar() {
    return TextField(
      controller: titleController,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: "Title",
        hintStyle: textStyle_24RegularGrey(),
      ),
    );
  }

  Widget _authorBlock() {
    return FutureBuilder<Map<String, String?>>(
      future: _getCachedUser(),
      builder: (context, snapshot) {
        final name = snapshot.data?['name'];
        final imageUrl = snapshot.data?['image'];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage:
                imageUrl != null ? NetworkImage(imageUrl) : null,
                child: imageUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(name ?? "Unknown author"),
            ],
          ),
        );
      },
    );
  }
}


