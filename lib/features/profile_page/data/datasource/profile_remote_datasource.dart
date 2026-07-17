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
        .select('id, name, username, headline, bio, avatar_url')
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
}
