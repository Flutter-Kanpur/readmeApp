import 'dart:convert';

import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/create_blog_page/presentation/widgets/editor_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';
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
  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController titleController = TextEditingController();

  final supabase = Supabase.instance.client;

  static const String _draftTitleKey = 'draft_title';
  static const String _draftContentKey = 'draft_content';

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

    if (savedTitle != null) {
      titleController.text = savedTitle;
    }

    if (savedContent != null) {
      final delta = Delta.fromJson(jsonDecode(savedContent));
      _controller = quill.QuillController(
        document: quill.Document.fromDelta(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
      setState(() {});
    }
  }

  // ================== SAVE DRAFT ==================
  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();

    final title = titleController.text.trim();
    final contentJson = jsonEncode(
      _controller.document.toDelta().toJson(),
    );

    await prefs.setString(_draftTitleKey, title);
    await prefs.setString(_draftContentKey, contentJson);

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

  // ================== PUBLISH BLOG ==================
  Future<void> _publishBlog() async {
    final title = titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title cannot be empty")),
      );
      return;
    }

    final contentJson = _controller.document.toDelta().toJson();

    try {
      await supabase.from('blogs').insert({
        'title': title,
        'content': contentJson,
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
      bottomNavigationBar: EditorToolbar(
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
              Expanded(
                child: quill.QuillEditor(
                  controller: _controller,
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  config: const quill.QuillEditorConfig(
                    placeholder: 'Start writing your blog...',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================== TOP BAR ==================
  Widget _topBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
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
                child: Center(
                  child: Text(
                    "Publish",
                    style: textStyle_16RegularWhite().copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================== TITLE ==================
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

}