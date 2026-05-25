import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community_article_model.dart';
import '../models/community_dashboard_models.dart';
import '../models/community_model.dart';

class CommunityRemoteDatasource {
  CommunityRemoteDatasource(this.client);

  final SupabaseClient client;

  Future<List<CommunityModel>> fetchCommunities() async {
    final response = await client
        .from('communities')
        .select()
        .order('created_at', ascending: false);

    return response
        .map<CommunityModel>((row) => CommunityModel.fromJson(row))
        .toList();
  }

  Future<CommunityModel?> fetchCommunityBySlug(String slug) async {
    final response = await client
        .from('communities')
        .select()
        .eq('slug', slug)
        .maybeSingle();

    if (response == null) return null;
    return CommunityModel.fromJson(response);
  }

  Future<CommunityStats> fetchCommunityStats(String communityId) async {
    final members = await client
        .from('community_members')
        .select('id')
        .eq('community_id', communityId);

    final blogs = await client
        .from('blogs')
        .select('blog_id')
        .eq('community_id', communityId)
        .eq('is_published', true);

    return CommunityStats(
      memberCount: (members as List).length,
      publishedCount: (blogs as List).length,
    );
  }

  Future<List<CommunityArticle>> fetchCommunityArticles(
    String communityId,
  ) async {
    final response = await client
        .from('blogs')
        .select('''
      blog_id,
      title,
      content,
      cover_image,
      created_at,
      category,
      is_published,
      profiles!inner (
        name,
        avatar_url
      ),
      blog_coauthors (
        user_id,
        profiles (
          name,
          avatar_url
        )
      )
    ''')
        .eq('community_id', communityId)
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return response
        .map<CommunityArticle>((row) => CommunityArticle.fromJson(row))
        .toList();
  }

  Future<bool> isCommunityMember(String communityId, String userId) async {
    final response = await client
        .from('community_members')
        .select('id')
        .eq('community_id', communityId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }

  Future<String?> fetchUserRole(String communityId, String userId) async {
    final response = await client
        .from('community_members')
        .select('role')
        .eq('community_id', communityId)
        .eq('user_id', userId)
        .maybeSingle();

    return response?['role'] as String?;
  }

  Future<List<CommunityDraft>> fetchCommunityDrafts(String communityId) async {
    final response = await client
        .from('blogs')
        .select('''
      blog_id,
      title,
      created_at,
      profiles!inner (name)
    ''')
        .eq('community_id', communityId)
        .eq('is_published', false)
        .order('created_at', ascending: false);

    return response
        .map<CommunityDraft>((row) => CommunityDraft.fromJson(row))
        .toList();
  }

  /// Returns the most recent (pending) join request from this user, or null
  /// if they have no pending request for this community.
  Future<CommunityJoinRequest?> fetchUserPendingJoinRequest({
    required String communityId,
    required String userId,
  }) async {
    Map<String, dynamic>? response;
    try {
      response = await client
          .from('community_join_requests')
          .select('id, user_id, status, requested_role, created_at')
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .eq('status', 'pending')
          .maybeSingle();
    } on PostgrestException catch (e) {
      // Schema may not yet have requested_role.
      final missingColumn = e.code == '42703' ||
          e.message.toLowerCase().contains('requested_role');
      if (!missingColumn) rethrow;
      response = await client
          .from('community_join_requests')
          .select('id, user_id, status, created_at')
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .eq('status', 'pending')
          .maybeSingle();
    }

    if (response == null) return null;
    return CommunityJoinRequest.fromJson({
      ...response,
      'profiles': null,
    });
  }

  /// Cancels a pending join request submitted by the user.
  Future<void> cancelJoinRequest(String requestId) async {
    await client.from('community_join_requests').delete().eq('id', requestId);
  }

  /// Creates a new pending join request. Stores `requested_role` if the
  /// schema has the column; falls back to a request without it otherwise.
  Future<void> createJoinRequest({
    required String communityId,
    required String userId,
    required String role,
  }) async {
    try {
      await client.from('community_join_requests').insert({
        'community_id': communityId,
        'user_id': userId,
        'status': 'pending',
        'requested_role': role,
      });
    } on PostgrestException catch (e) {
      final missingColumn = e.code == '42703' ||
          e.message.toLowerCase().contains('requested_role');
      if (!missingColumn) rethrow;
      await client.from('community_join_requests').insert({
        'community_id': communityId,
        'user_id': userId,
        'status': 'pending',
      });
    }
  }

  Future<List<CommunityJoinRequest>> fetchPendingJoinRequests(
    String communityId,
  ) async {
    final response = await client
        .from('community_join_requests')
        .select('''
      id,
      user_id,
      status,
      profiles!community_join_requests_user_id_fkey (name)
    ''')
        .eq('community_id', communityId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return response
        .map<CommunityJoinRequest>((row) => CommunityJoinRequest.fromJson(row))
        .toList();
  }

  Future<List<CommunityMember>> fetchCommunityMembers(
    String communityId,
  ) async {
    final response = await client
        .from('community_members')
        .select('''
      id,
      user_id,
      role,
      profiles!inner (name)
    ''')
        .eq('community_id', communityId)
        .order('joined_at', ascending: true);

    return response
        .map<CommunityMember>((row) => CommunityMember.fromJson(row))
        .toList();
  }

  Future<void> updateMemberRole(String memberId, String role) async {
    await client.from('community_members').update({'role': role}).eq('id', memberId);
  }

  Future<void> removeMember(String memberId) async {
    await client.from('community_members').delete().eq('id', memberId);
  }

  Future<void> inviteMemberByName({
    required String communityId,
    required String profileName,
    required String role,
  }) async {
    final profile = await client
        .from('profiles')
        .select('id')
        .eq('name', profileName.trim())
        .maybeSingle();

    if (profile == null) {
      throw Exception('No profile found with that exact name.');
    }

    final userId = profile['id'] as String;

    final existing = await client
        .from('community_members')
        .select('id')
        .eq('community_id', communityId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('This user is already a community member.');
    }

    await client.from('community_members').insert({
      'community_id': communityId,
      'user_id': userId,
      'role': role,
    });
  }

  Future<void> approveJoinRequest(String requestId, String communityId) async {
    final request = await client
        .from('community_join_requests')
        .select('user_id')
        .eq('id', requestId)
        .maybeSingle();

    if (request == null) return;

    final userId = request['user_id'] as String;

    await client.from('community_join_requests').update({
      'status': 'approved',
      'reviewed_by': client.auth.currentUser?.id,
    }).eq('id', requestId);

    final existing = await client
        .from('community_members')
        .select('id')
        .eq('community_id', communityId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      await client.from('community_members').insert({
        'community_id': communityId,
        'user_id': userId,
        'role': 'contributor',
      });
    }
  }

  Future<void> rejectJoinRequest(String requestId) async {
    await client.from('community_join_requests').update({
      'status': 'rejected',
      'reviewed_by': client.auth.currentUser?.id,
    }).eq('id', requestId);
  }

  Future<String> uploadCommunityLogo({
    required String communityId,
    required Uint8List bytes,
    required String fileExt,
  }) async {
    final fileName = '$communityId/logo.$fileExt';
    await client.storage.from('community-logos').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: 'image/$fileExt'),
        );

    return client.storage.from('community-logos').getPublicUrl(fileName);
  }

  Future<void> updateCommunityLogo({
    required String communityId,
    required String logoUrl,
  }) async {
    await client.from('communities').update({
      'logo_url': logoUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', communityId);
  }
}
