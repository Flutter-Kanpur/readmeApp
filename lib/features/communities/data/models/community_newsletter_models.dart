class CommunityNewsletterIssue {
  const CommunityNewsletterIssue({
    required this.id,
    required this.communityId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.attachmentUrl,
    this.authorName,
  });

  final String id;
  final String communityId;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? attachmentUrl;
  final String? authorName;

  factory CommunityNewsletterIssue.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return CommunityNewsletterIssue(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      title: json['title'] as String? ?? 'Untitled issue',
      body: json['body'] as String? ?? '',
      attachmentUrl: json['attachment_url'] as String?,
      authorName: profile?['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class CommunityNewsletterStats {
  const CommunityNewsletterStats({
    required this.subscriberCount,
    required this.isSubscribed,
  });

  final int subscriberCount;
  final bool isSubscribed;
}
