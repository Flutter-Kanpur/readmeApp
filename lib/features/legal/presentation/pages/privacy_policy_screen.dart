import 'package:Readme/core/legal/privacy_policy_content.dart';
import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _openWebPolicy(BuildContext context) async {
    final uri = Uri.parse(PrivacyPolicyContent.webUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the privacy policy page.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 12.w, 8.h),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 8.h,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              size: 16.sp,
                              color: AppColors.linkBlue,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Back',
                              style: textStyle_14RegularBlack().copyWith(
                                fontSize: 14.sp,
                                color: AppColors.linkBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _openWebPolicy(context),
                    child: Text(
                      'Open on web',
                      style: textStyle_12RegularGrey().copyWith(
                        fontSize: 12.sp,
                        color: AppColors.linkBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 40.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy Policy',
                      style: textStyle_24BoldBlack().copyWith(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Last updated: ${PrivacyPolicyContent.lastUpdated}',
                      style: textStyle_12RegularGrey().copyWith(
                        fontSize: 13.sp,
                        color: AppColors.subtitles,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ..._buildSections(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSections() {
    final lines = PrivacyPolicyContent.markdown.split('\n');
    final widgets = <Widget>[];

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.isEmpty) {
        widgets.add(SizedBox(height: 8.h));
        continue;
      }
      if (line.startsWith('# ')) {
        continue; // title already shown above
      }
      if (line.startsWith('## ')) {
        widgets.add(SizedBox(height: 18.h));
        widgets.add(
          Text(
            line.substring(3),
            style: textStyle_16BoldBlack().copyWith(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        widgets.add(SizedBox(height: 8.h));
        continue;
      }
      if (line.startsWith('### ')) {
        widgets.add(SizedBox(height: 12.h));
        widgets.add(
          Text(
            line.substring(4),
            style: textStyle_14RegularBlack().copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        widgets.add(SizedBox(height: 6.h));
        continue;
      }
      if (line.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•  ',
                  style: textStyle_14RegularBlack().copyWith(
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                ),
                Expanded(
                  child: Text(
                    _stripMarkdown(line.substring(2)),
                    style: textStyle_14RegularBlack().copyWith(
                      fontSize: 14.sp,
                      height: 1.5,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Text(
            _stripMarkdown(line),
            style: textStyle_14RegularBlack().copyWith(
              fontSize: 14.sp,
              height: 1.55,
              color: AppColors.black,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  String _stripMarkdown(String input) {
    return input.replaceAll('**', '').trim();
  }
}
