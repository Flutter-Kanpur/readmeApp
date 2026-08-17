import 'dart:async';

import 'package:Readme/core/cache/blog_feed_cache.dart';
import 'package:Readme/core/network/readme_supabase.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/assets_path.dart';
import 'package:Readme/core/utils/draft_storage.dart';
import 'package:Readme/core/utils/quill_content_parser.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/create_blog_page/data/datasource/blog_draft_datasource.dart';
import 'package:Readme/features/create_blog_page/domain/entities/blog_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyDraftsScreen extends StatefulWidget {
  const MyDraftsScreen({super.key});

  @override
  State<MyDraftsScreen> createState() => _MyDraftsScreenState();
}

class _MyDraftsScreenState extends State<MyDraftsScreen> {
  final _datasource = BlogDraftDatasource(ReadmeSupabase.client);

  bool _isLoading = true;
  List<BlogDraft> _drafts = [];
  String? _error;
  StreamSubscription<AuthState>? _authSub;
  bool _tabTickerEnabled = false;

  @override
  void initState() {
    super.initState();
    _authSub = ReadmeSupabase.client.auth.onAuthStateChange.listen((_) {
      if (mounted) _loadDrafts();
    });
    _loadDrafts();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tickerEnabled = TickerMode.of(context);
    if (tickerEnabled && !_tabTickerEnabled) {
      _tabTickerEnabled = true;
      _loadDrafts();
    } else if (!tickerEnabled) {
      _tabTickerEnabled = false;
    }
  }

  Future<void> _loadDrafts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final user = ReadmeSupabase.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _drafts = [];
      });
      return;
    }

    try {
      final drafts = await _datasource.fetchAllDrafts(user.id);
      if (!mounted) return;
      setState(() {
        _drafts = drafts;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load drafts. Pull to refresh.';
        _isLoading = false;
      });
      debugPrint('fetchAllDrafts error: $error');
    }
  }

  Future<void> _openNewDraft() async {
    final user = ReadmeSupabase.client.auth.currentUser;
    if (user == null) {
      context.push('/signin');
      return;
    }
    await context.push('/create');
    if (mounted) _loadDrafts();
  }

  Future<void> _openEdit(BlogDraft draft) async {
    if (draft.isLocalOnly) {
      await context.push('/create');
    } else {
      await context.push('/edit/${draft.id}');
    }
    if (mounted) _loadDrafts();
  }

  Future<void> _publishDraft(BlogDraft draft) async {
    final user = ReadmeSupabase.client.auth.currentUser;
    if (user == null) {
      context.push('/signin');
      return;
    }

    if (draft.isLocalOnly) {
      if (draft.title.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a title in the editor, then save')),
        );
        await context.push('/create');
        if (mounted) _loadDrafts();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save draft to cloud first, then publish'),
        ),
      );
      await context.push('/create');
      if (mounted) _loadDrafts();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish draft?'),
        content: Text(
          'Publish "${draft.title.isEmpty ? 'Untitled Draft' : draft.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _datasource.publishDraft(blogId: draft.id, userId: user.id);
      BlogFeedCache.instance.invalidate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft published successfully')),
      );
      _loadDrafts();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish: $error')),
      );
    }
  }

  Future<void> _deleteDraft(BlogDraft draft) async {
    if (draft.isLocalOnly) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete local draft?'),
          content: const Text(
            'This removes the draft saved on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await DraftStorage.clearDraft();
      if (!mounted) return;
      setState(() => _drafts.removeWhere((d) => d.isLocalOnly));
      return;
    }

    final user = ReadmeSupabase.client.auth.currentUser;
    if (user == null) {
      context.push('/signin');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete draft?'),
        content: const Text(
          'This will permanently remove this draft. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _datasource.deleteDraft(blogId: draft.id, userId: user.id);
      if (!mounted) return;
      setState(() => _drafts.removeWhere((d) => d.id == draft.id));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ReadmeSupabase.client.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DraftsHeader(onNewDraft: _openNewDraft),
            Divider(height: 1, color: Colors.grey.shade200),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDrafts,
                child: _buildBody(user),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(user) {
    if (user == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 80.h),
          Center(
            child: Column(
              children: [
                Text(
                  'Sign in to view your drafts',
                  style: textStyle_14RegularGrey().copyWith(fontSize: 14.sp),
                ),
                SizedBox(height: 16.h),
                _PrimaryPillButton(
                  label: 'Sign in',
                  onTap: () => context.push('/signin'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 24.h),
        children: List.generate(3, (_) => Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: _DraftSkeletonCard(),
        )),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 80.h),
          Center(
            child: Text(_error!, style: textStyle_14RegularGrey()),
          ),
        ],
      );
    }

    if (_drafts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
            child: _EmptyState(onWrite: _openNewDraft),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
      itemCount: _drafts.length,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final draft = _drafts[index];
        return _DraftCard(
          draft: draft,
          onEdit: () => _openEdit(draft),
          onPublish: () => _publishDraft(draft),
          onDelete: () => _deleteDraft(draft),
        );
      },
    );
  }
}

class _DraftsHeader extends StatelessWidget {
  const _DraftsHeader({required this.onNewDraft});

  final VoidCallback onNewDraft;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 16.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMPLETE YOUR',
            style: textStyle_12RegularGrey().copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.8,
              color: const Color(0xFF374151).withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Drafts',
                  style: textStyle_24BoldBlack().copyWith(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              _PrimaryPillButton(
                label: 'New Draft',
                icon: Icons.add,
                onTap: onNewDraft,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.black,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16.sp, color: Colors.white),
                SizedBox(width: 6.w),
              ],
              Text(
                label,
                style: GoogleFonts.ptSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.onEdit,
    required this.onPublish,
    required this.onDelete,
  });

  final BlogDraft draft;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onDelete;

  String get _title =>
      draft.title.trim().isEmpty ? 'Untitled Draft' : draft.title.trim();

  String get _preview {
    final text = parseQuillContent(draft.content).trim();
    if (text.isEmpty) return '';
    return text.length > 150 ? '${text.substring(0, 150)}...' : text;
  }

  String get _editedLabel {
    final formatted = DateFormat('MMM d, yyyy, hh:mm a').format(draft.updatedAt);
    return 'Edited $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
              height: 1.3,
            ),
          ),
          if (_preview.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              _preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: const Color(0xFF4B5563),
                height: 1.55,
              ),
            ),
          ],
          SizedBox(height: 16.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 8.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  draft.isLocalOnly
                      ? 'ON DEVICE'
                      : draft.category.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              Text(
                _editedLabel,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: _DraftActionButton(
                  label: 'Edit',
                  onTap: onEdit,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _DraftActionButton(
                  label: 'Publish',
                  onTap: onPublish,
                  filled: true,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _DraftActionButton(
                  label: 'Delete',
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DraftActionButton extends StatelessWidget {
  const _DraftActionButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.black : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: filled ? null : Border.all(color: const Color(0xFFE5E7EB)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}

class _DraftSkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16.r),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onWrite});

  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 48.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180.w,
            height: 180.w,
            child: Lottie.asset(
              AssetsPath.emptyLottie,
              package: AssetsPath.package,
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "You haven't started any stories yet.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: AppColors.subtitles,
              height: 1.4,
            ),
          ),
          SizedBox(height: 20.h),
          _PrimaryPillButton(label: 'Write Your First Story', onTap: onWrite),
        ],
      ),
    );
  }
}
