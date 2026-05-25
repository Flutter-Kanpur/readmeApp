import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/communities/data/datasource/community_remote_datasource.dart';
import 'package:Readme/features/communities/data/models/community_newsletter_models.dart';
import 'package:Readme/features/communities/domain/entities/community.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityNewsletterSubscribeCard extends StatefulWidget {
  const CommunityNewsletterSubscribeCard({
    super.key,
    required this.community,
    required this.stats,
    required this.datasource,
    required this.onSubscribed,
  });

  final Community community;
  final CommunityNewsletterStats stats;
  final CommunityRemoteDatasource datasource;
  final VoidCallback onSubscribed;

  @override
  State<CommunityNewsletterSubscribeCard> createState() =>
      _CommunityNewsletterSubscribeCardState();
}

class _CommunityNewsletterSubscribeCardState
    extends State<CommunityNewsletterSubscribeCard> {
  late final TextEditingController _emailController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.datasource.subscribeToNewsletter(
        communityId: widget.community.id,
        email: email,
        userId: Supabase.instance.client.auth.currentUser?.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscribed to ${widget.community.name} newsletter.'),
        ),
      );
      widget.onSubscribed();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final isSubscribed = stats.isSubscribed;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.linkBlue,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.mail_outline_rounded,
                  size: 18.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly newsletter',
                      style: textStyle_16BoldBlack().copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Get a monthly recap from ${widget.community.name} — highlights, new posts, and what\'s next.',
                      style: textStyle_14RegularGrey().copyWith(
                        fontSize: 13.sp,
                        color: AppColors.subtitles,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (isSubscribed)
            _SubscribedBadge()
          else
            _SubscribeRow(
              controller: _emailController,
              isSubmitting: _isSubmitting,
              onSubscribe: _subscribe,
            ),
          SizedBox(height: 10.h),
          Text(
            '${stats.subscriberCount} ${stats.subscriberCount == 1 ? 'subscriber' : 'subscribers'}',
            style: textStyle_12RegularGrey().copyWith(
              fontSize: 12.sp,
              color: AppColors.subtitles,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscribeRow extends StatelessWidget {
  const _SubscribeRow({
    required this.controller,
    required this.isSubmitting,
    required this.onSubscribe,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 4.h, 4.w, 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              style: textStyle_14RegularBlack().copyWith(
                fontSize: 13.sp,
                color: AppColors.black,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'you@email.com',
                hintStyle: textStyle_14RegularGrey().copyWith(
                  fontSize: 13.sp,
                  color: AppColors.subtitles,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
              ),
            ),
          ),
          SizedBox(width: 6.w),
          ElevatedButton(
            onPressed: isSubmitting ? null : onSubscribe,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              disabledBackgroundColor: Colors.grey.shade400,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: isSubmitting
                ? SizedBox(
                    width: 14.w,
                    height: 14.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Subscribe',
                    style: textStyle_14RegularBlack().copyWith(
                      fontSize: 13.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SubscribedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFB7E0BD)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 16.sp, color: const Color(0xFF1B7D33)),
          SizedBox(width: 8.w),
          Text(
            'You\'re subscribed',
            style: textStyle_14RegularBlack().copyWith(
              fontSize: 13.sp,
              color: const Color(0xFF1B7D33),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
