import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class UserFollowStats {
  const UserFollowStats({required this.followers, required this.following});

  final int followers;
  final int following;
}

class ProfileRemoteDatasource {
  ProfileRemoteDatasource(this.client);

  final SupabaseClient client;

  Future<Map<String, dynamic>?> fetchProfileById(String userId) async {
    final response = await client
        .from('profiles')
        .select('id, name, username, headline, bio, avatar_url, created_at')
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  Future<UserFollowStats> fetchFollowStats(String userId) async {
    try {
      final followers = await client
          .from('follows')
          .count(CountOption.exact)
          .eq('following_id', userId);

      final following = await client
          .from('follows')
          .count(CountOption.exact)
          .eq('follower_id', userId);

      return UserFollowStats(followers: followers, following: following);
    } catch (_) {
      return const UserFollowStats(followers: 0, following: 0);
    }
  }

  Future<bool> isFollowingAuthor({
    required String followerId,
    required String authorId,
  }) async {
    try {
      final response = await client
          .from('follows')
          .select('id')
          .eq('follower_id', followerId)
          .eq('following_id', authorId)
          .maybeSingle();

      return response != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> followAuthor({
    required String followerId,
    required String authorId,
  }) async {
    try {
      await client.from('follows').insert({
        'follower_id': followerId,
        'following_id': authorId,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') return;
      rethrow;
    }
  }

  Future<void> unfollowAuthor({
    required String followerId,
    required String authorId,
  }) async {
    await client
        .from('follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', authorId);
  }

  /// Applies profile field updates for [userId].
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    await client.from('profiles').update(updates).eq('id', userId);
  }

  /// Uploads avatar [bytes] to storage and returns the public URL.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final fileName =
        'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final filePath = 'avatars/$fileName';
    await client.storage.from('blog_images').uploadBinary(filePath, bytes);
    return client.storage.from('blog_images').getPublicUrl(filePath);
  }

  /// Invokes the `delete-account` edge function. Throws on a non-2xx response.
  Future<void> deleteAccount() async {
    final response = await client.functions.invoke('delete-account');
    if (response.status < 200 || response.status >= 300) {
      final data = response.data;
      final message = data is Map<String, dynamic>
          ? data['error'] as String?
          : null;
      throw Exception(message ?? 'The server could not delete your account.');
    }
  }
}
