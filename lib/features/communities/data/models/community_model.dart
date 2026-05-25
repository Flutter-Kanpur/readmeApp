import '../../domain/entities/community.dart';

class CommunityModel extends Community {
  const CommunityModel({
    required super.id,
    required super.slug,
    required super.name,
    super.description,
    super.logoUrl,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
