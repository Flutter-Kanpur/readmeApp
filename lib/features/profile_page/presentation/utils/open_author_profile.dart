import 'package:Readme/core/providers/supabase_providers.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Navigates to an author's profile, routing to `/profile` (the signed-in
/// user's own screen) when the author is the current user.
void openAuthorProfile(BuildContext context, WidgetRef ref, Author author) {
  final authorId = author.id;
  if (authorId == null) return;

  final currentUserId = ref.read(currentUserProvider)?.id;
  if (currentUserId == authorId) {
    context.go('/profile');
    return;
  }

  context.push('/profile/$authorId');
}
