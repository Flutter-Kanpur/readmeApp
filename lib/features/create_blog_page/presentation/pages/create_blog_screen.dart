import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/draft_storage.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/create_blog_page/presentation/widgets/blog_article_settings_panel.dart';
import 'package:Readme/features/create_blog_page/presentation/widgets/editor_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kanpur_ui_kit/flutter_kanpur_ui_kit.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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

  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController titleController = TextEditingController();

  final supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _coverImageFile;

  String _publishAs = BlogArticleSettingsPanel.publishAsOptions.first;
  String _selectedCategory = 'Technology';
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = [];

  static const _articleCategories = [
    'Technology',
    'Flutter',
    'UI',
    'React',
    'JavaScript',
    'DSA',
  ];

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
    _tagController.dispose();
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
  Future<Map<String, String?>> _getAuthorInfo() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return {'name': null, 'image': null};
    }

    try {
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final name = profileData?['name'] as String? ??
          profileData?['full_name'] as String? ??
          profileData?['username'] as String? ??
          user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String? ??
          user.userMetadata?['username'] as String? ??
          user.email?.split('@').first;

      final image = profileData?['avatar_url'] as String? ??
          user.userMetadata?['avatar_url'] as String?;

      return {'name': name, 'image': image};
    } catch (_) {
      final name = user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String? ??
          user.userMetadata?['username'] as String? ??
          user.email?.split('@').first;
      final image = user.userMetadata?['avatar_url'] as String?;
      return {'name': name, 'image': image};
    }
  }

  // ================== SAVE DRAFT ==================
  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftTitleKey, titleController.text.trim());
    await prefs.setString(
      _draftContentKey,
      jsonEncode(_controller.document.toDelta().toJson()),
    );
    await DraftStorage.setSavedAt(DateTime.now());
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Draft saved locally")));
  }

  // ================== CLEAR DRAFT ==================
  Future<void> _clearDraft() async {
    await DraftStorage.clearDraft();
  }

  // ================== COVER IMAGE ==================
  Future<void> _pickCoverImage() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked != null && mounted) setState(() => _coverImageFile = picked);
  }

  void _addTag(String value) {
    final tag = value.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  // ================== UPLOAD IMAGES ON PUBLISH ==================
  Future<Map<String, dynamic>> _extractImagesWithPlaceholders(
    List<dynamic> deltaOps,
  ) async {
    final List<dynamic> cleanedOps = [];
    String? coverImageUrl;

    for (final op in deltaOps) {
      // IMAGE OP
      if (op is Map && op['insert'] is Map && op['insert']['image'] is String) {
        final imageValue = op['insert']['image'] as String;

        if (isDataUriImage(imageValue)) {
          final bytes = decodeDataUriImage(imageValue);
          if (bytes == null) continue;

          final fileName =
              'blogs/${DateTime.now().millisecondsSinceEpoch}.jpg';

          await supabase.storage
              .from('blog_images')
              .uploadBinary(fileName, bytes);

          final publicUrl = supabase.storage
              .from('blog_images')
              .getPublicUrl(fileName);
          coverImageUrl ??= publicUrl;
          cleanedOps.add({'insert': {'image': publicUrl}});
          cleanedOps.add({'insert': '\n'});
        } else if (imageValue.startsWith('http') || imageValue.startsWith('//')) {
          final publicUrl =
              imageValue.startsWith('//') ? 'https:$imageValue' : imageValue;
          cleanedOps.add({'insert': {'image': publicUrl}});
          cleanedOps.add({'insert': '\n'});
          coverImageUrl ??= publicUrl;
        } else {
          final file = File(imageValue);
          final bytes = await file.readAsBytes();

          final fileName = 'blogs/${DateTime.now().millisecondsSinceEpoch}.jpg';

          await supabase.storage
              .from('blog_images')
              .uploadBinary(fileName, bytes);

          final publicUrl = supabase.storage
              .from('blog_images')
              .getPublicUrl(fileName);
          coverImageUrl ??= publicUrl;
          cleanedOps.add({'insert': {'image': publicUrl}});
          cleanedOps.add({'insert': '\n'});
        }
        continue;
      }

      cleanedOps.add(op);
    }

    return {
      'content': cleanedOps,
      'cover_image': coverImageUrl,
    };
  }

  // ================== PUBLISH ==================
  Future<void> _publishBlog() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Title cannot be empty")));
      return;
    }

    try {
      String? coverImageUrl;
      if (_coverImageFile != null) {
        final bytes = await _coverImageFile!.readAsBytes();
        final fileExt = _coverImageFile!.path.split('.').last;
        final fileName = 'covers/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        await supabase.storage.from('blog_images').uploadBinary(fileName, bytes);
        coverImageUrl = supabase.storage.from('blog_images').getPublicUrl(fileName);
      }

      final rawDelta = _controller.document.toDelta().toJson();
      final result = await _extractImagesWithPlaceholders(rawDelta);
      coverImageUrl ??= result['cover_image'] as String?;

      await supabase.from('blogs').insert({
        'title': title,
        'content': jsonEncode(result['content']),
        'cover_image': coverImageUrl,
        'category': _selectedCategory,
        'tags': _tags.isEmpty ? null : _tags,
        'author_id': supabase.auth.currentUser!.id,
        'is_published': true,
      });
      await _clearDraft();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Blog published successfully")),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _handleTabIndent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      final index = _controller.selection.baseOffset;
      if (index < 0) return;

      _controller.replaceText(
        index,
        0,
        '    ', // 4 spaces
        TextSelection.collapsed(offset: index + 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              _topBar(),
              const Divider(),
              EditorToolbar(
                controller: _controller,
                focusNode: _focusNode,
              ),
              5.verticalSpace,
              _titleBar(),
              5.verticalSpace,
              _authorBlock(),
              5.verticalSpace,
              Expanded(
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: _handleTabIndent,
                  child: quill.QuillEditor(
                    controller: _controller,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                    config: quill.QuillEditorConfig(
                      placeholder: 'Start writing your blog...',
                      embedBuilders: FlutterQuillEmbeds.editorBuilders(
                        imageEmbedConfig: QuillEditorImageEmbedConfig(
                          imageProviderBuilder: quillImageProviderBuilder,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 340.h),
                child: SingleChildScrollView(
                  child: BlogArticleSettingsPanel(
                    publishAs: _publishAs,
                    onPublishAsChanged: (value) {
                      if (value != null) setState(() => _publishAs = value);
                    },
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: (value) {
                      if (value != null) setState(() => _selectedCategory = value);
                    },
                    categories: _articleCategories,
                    coverImageFile: _coverImageFile,
                    onPickCoverImage: _pickCoverImage,
                    onRemoveCoverImage: () =>
                        setState(() => _coverImageFile = null),
                    tagController: _tagController,
                    tags: _tags,
                    onAddTag: _addTag,
                    onRemoveTag: _removeTag,
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
                "Save Draft",
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
                child: GradientButton(onTap: _publishBlog, text: "Publish"),
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
      future: _getAuthorInfo(),
      builder: (context, snapshot) {
        final name = snapshot.data?['name'];
        final imageUrl = snapshot.data?['image'];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: imageProviderFromSource(imageUrl),
                child: imageUrl == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 12),
              Text(name ?? "Unknown author",style: textStyle_14LightBlack(),),
            ],
          ),
        );
      },
    );
  }
}
