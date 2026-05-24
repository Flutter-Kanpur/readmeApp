import 'dart:io';

import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class BlogArticleSettingsPanel extends StatelessWidget {
  const BlogArticleSettingsPanel({
    super.key,
    required this.publishAs,
    required this.onPublishAsChanged,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.categories,
    required this.coverImageFile,
    required this.onPickCoverImage,
    required this.onRemoveCoverImage,
    required this.tagController,
    required this.tags,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  final String publishAs;
  final ValueChanged<String?> onPublishAsChanged;
  final String selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final List<String> categories;
  final XFile? coverImageFile;
  final VoidCallback onPickCoverImage;
  final VoidCallback onRemoveCoverImage;
  final TextEditingController tagController;
  final List<String> tags;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;

  static const publishAsOptions = ['Personal (just me)'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PublishAsCard(
          publishAs: publishAs,
          onChanged: onPublishAsChanged,
        ),
        SizedBox(height: 24.h),
        Text(
          'ARTICLE SETTINGS',
          style: textStyle_16BoldBlack().copyWith(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.subtitles,
          ),
        ),
        SizedBox(height: 16.h),
        _SettingsLabel(text: 'Category'),
        SizedBox(height: 8.h),
        _SettingsDropdown(
          value: selectedCategory,
          items: categories,
          onChanged: onCategoryChanged,
        ),
        SizedBox(height: 20.h),
        _SettingsLabel(text: 'Featured Image'),
        SizedBox(height: 15.h),
        _FeaturedImagePicker(
          coverImageFile: coverImageFile,
          onPick: onPickCoverImage,
          onRemove: onRemoveCoverImage,
        ),
        SizedBox(height: 20.h),
        _SettingsLabel(text: 'Tags'),
        SizedBox(height: 8.h),
        _TagInputField(
          controller: tagController,
          onSubmit: onAddTag,
        ),
        if (tags.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: tags
                .map(
                  (tag) => _TagChip(
                    label: tag,
                    onRemove: () => onRemoveTag(tag),
                  ),
                )
                .toList(),
          ),
        ],
        SizedBox(height: 20.h),
      ],
    );
  }
}

class _PublishAsCard extends StatelessWidget {
  const _PublishAsCard({
    required this.publishAs,
    required this.onChanged,
  });

  final String publishAs;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        // color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        // border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PUBLISH AS',
            style: textStyle_12RegularGrey().copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(height: 12.h),
          _SettingsLabel(text: 'Account'),
          SizedBox(height: 8.h),
          _SettingsDropdown(
            value: publishAs,
            items: BlogArticleSettingsPanel.publishAsOptions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsLabel extends StatelessWidget {
  const _SettingsLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: textStyle_14RegularBlack().copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _SettingsDropdown extends StatelessWidget {
  const _SettingsDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.subtitles),
          style: textStyle_14RegularBlack().copyWith(fontSize: 14.sp),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _FeaturedImagePicker extends StatelessWidget {
  const _FeaturedImagePicker({
    required this.coverImageFile,
    required this.onPick,
    required this.onRemove,
  });

  final XFile? coverImageFile;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        height: 160.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: Colors.grey.shade300,
            radius: 12.r,
            strokeWidth: 1.5,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 160.h,
            child: coverImageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(coverImageFile!.path),
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: onRemove,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.file_upload_outlined,
                        size: 28.sp,
                        color: AppColors.black,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Click to upload image',
                        style: textStyle_14RegularGrey().copyWith(
                          fontSize: 14.sp,
                          color: AppColors.subtitles,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _TagInputField extends StatelessWidget {
  const _TagInputField({
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.done,
        onSubmitted: onSubmit,
        decoration: InputDecoration(
          hintText: 'Add a tag and press Enter...',
          hintStyle: textStyle_14RegularGrey().copyWith(fontSize: 14.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textStyle_14RegularBlack().copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.linkBlue,
            ),
          ),
          SizedBox(width: 6.w),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16.sp,
              color: AppColors.linkBlue,
            ),
          ),
        ],
      ),
    );
  }
}
