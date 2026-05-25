class CommunityMember {
  const CommunityMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.role,
  });

  final String id;
  final String userId;
  final String name;
  final String role;

  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return CommunityMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: profile?['name'] as String? ?? 'Unknown',
      role: json['role'] as String? ?? 'contributor',
    );
  }
}

class CommunityJoinRequest {
  const CommunityJoinRequest({
    required this.id,
    required this.userId,
    required this.name,
    required this.status,
    this.requestedRole,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String status;
  final String? requestedRole;
  final DateTime? createdAt;

  factory CommunityJoinRequest.fromJson(Map<String, dynamic> json) {
    final profile =
        json['profiles'] as Map<String, dynamic>? ??
        json['profiles!community_join_requests_user_id_fkey']
            as Map<String, dynamic>?;

    final createdAtRaw = json['created_at'] as String?;

    return CommunityJoinRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: profile?['name'] as String? ?? 'Unknown',
      status: json['status'] as String? ?? 'pending',
      requestedRole: json['requested_role'] as String?,
      createdAt: createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null,
    );
  }
}

class CommunityDraft {
  const CommunityDraft({
    required this.id,
    required this.title,
    required this.authorName,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String authorName;
  final DateTime createdAt;

  factory CommunityDraft.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return CommunityDraft(
      id: json['blog_id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      authorName: profile?['name'] as String? ?? 'Unknown',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
