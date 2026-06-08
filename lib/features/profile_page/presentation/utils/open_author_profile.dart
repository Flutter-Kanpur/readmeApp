import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void openAuthorProfile(BuildContext context, Author author) {
  final authorId = author.id;
  if (authorId == null) return;

  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  if (currentUserId == authorId) {
    context.go('/profile');
    return;
  }

  context.push('/profile/$authorId');
}
