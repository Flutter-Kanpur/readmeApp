import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/story.dart';

class StoryTile extends StatelessWidget {
  final Story story;

  const StoryTile({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: story.tagColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        story.category,
                        style: TextStyle(color: story.tagColor, fontSize: 10.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      story.source,
                      style: TextStyle(color: Colors.grey, fontSize: 11.sp),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  story.title,
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                  maxLines: 2,
                ),
                SizedBox(height: 4.h),
                Text(
                  "${story.readTime} • ${story.date}",
                  style: TextStyle(color: Colors.grey, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 15.w),
          Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12.r)),
            child: Icon(Icons.description_outlined, color: Colors.grey[400], size: 30.sp),
          ),
        ],
      ),
    );
  }
}
