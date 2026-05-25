import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/draft_storage.dart';
import 'package:Readme/core/utils/quill_content_parser.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/shared/widgets/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MyDraftsScreen extends StatefulWidget {
  const MyDraftsScreen({super.key});

  @override
  State<MyDraftsScreen> createState() => _MyDraftsScreenState();
}

class _MyDraftsScreenState extends State<MyDraftsScreen> {
  bool _isLoading = true;
  DraftEntry? _draft;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    setState(() => _isLoading = true);
    final draft = await DraftStorage.getDraft();
    if (!mounted) return;
    setState(() {
      _draft = draft;
      _isLoading = false;
    });
  }

  Future<void> _openEditor() async {
    await context.push('/create');
    if (mounted) _loadDraft();
  }

  Future<void> _deleteDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete draft?'),
        content: const Text(
          'This will permanently remove your saved draft. This cannot be undone.',
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
    if (confirmed != true) return;
    await DraftStorage.clearDraft();
    if (!mounted) return;
    setState(() => _draft = null);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              Divider(height: 1.h, color: Colors.grey.shade200),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadDraft,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _isLoading
                        ? Padding(
                            padding: EdgeInsets.only(top: 80.h),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _draft == null
                            ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40.0),
                              child: _EmptyState(onWrite: _openEditor),
                            )
                            : _DraftListItem(
                                draft: _draft!,
                                onTap: _openEditor,
                                onDelete: _deleteDraft,
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

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMPLETE YOUR',
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
                child: Text(
                  'Drafts',
                  style: textStyle_24BoldBlack().copyWith(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
              _NewDraftButton(onTap: _openEditor),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewDraftButton extends StatelessWidget {
  const _NewDraftButton({required this.onTap});

  final VoidCallback onTap;

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
              Icon(Icons.add, size: 16.sp, color: Colors.white),
              SizedBox(width: 6.w),
              Text(
                'New Draft',
                style: GoogleFonts.poppins(
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onWrite});

  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 60.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "You haven't started any stories yet.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: AppColors.subtitles,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16.h),
          Material(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onWrite,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 28.w,
                  vertical: 14.h,
                ),
                child: Text(
                  'Write Your First Story',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftListItem extends StatelessWidget {
  const _DraftListItem({
    required this.draft,
    required this.onTap,
    required this.onDelete,
  });

  final DraftEntry draft;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _formatSavedAt(DateTime when) {
    final now = DateTime.now();
    final diff = now.difference(when);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${when.day}/${when.month}/${when.year}';
  }

  @override
  Widget build(BuildContext context) {
    final title = draft.title.trim().isEmpty
        ? 'Untitled draft'
        : draft.title.trim();
    final preview = parseQuillContent(draft.content).trim();
    final savedLabel =
        draft.savedAt != null ? _formatSavedAt(draft.savedAt!) : 'Saved';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 20.sp,
                      color: AppColors.subtitles,
                    ),
                  ),
                ],
              ),
              if (preview.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Text(
                  preview,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: AppColors.subtitles,
                    height: 1.45,
                  ),
                ),
              ],
              SizedBox(height: 14.h),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14.sp,
                    color: AppColors.subtitles,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Last saved $savedLabel',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: AppColors.subtitles,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
