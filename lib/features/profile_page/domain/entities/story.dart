import 'package:flutter/material.dart';

class Story {
  final String category;
  final String source;
  final String title;
  final String readTime;
  final String date;
  final Color tagColor;

  Story({required this.category, required this.source, required this.title, required this.readTime, required this.date, required this.tagColor});
}
