import 'package:Readme/core/providers/datasource_providers.dart';
import 'package:Readme/core/providers/supabase_providers.dart';
import 'package:Readme/features/communities/data/models/community_article_model.dart';
import 'package:Readme/features/communities/data/models/community_newsletter_models.dart';
import 'package:Readme/features/communities/domain/entities/community.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable snapshot of a community's public detail page: the community, its
/// stats, published articles, and the current user's membership / follow state.
class CommunityDetailState {
  const CommunityDetailState({
    required this.community,
    this.stats,
    this.articles = const [],
    this.isMember = false,
    this.userRole,
    this.isFollowing = false,
    this.followAvailable = true,
    this.newsletterStats,
  });

  final Community community;
  final CommunityStats? stats;
  final List<CommunityArticle> articles;
  final bool isMember;
  final String? userRole;
  final bool isFollowing;
  final bool followAvailable;
  final CommunityNewsletterStats? newsletterStats;

  CommunityDetailState copyWith({
    Community? community,
    CommunityStats? stats,
    List<CommunityArticle>? articles,
    bool? isMember,
    String? userRole,
    bool? isFollowing,
    bool? followAvailable,
    CommunityNewsletterStats? newsletterStats,
  }) {
    return CommunityDetailState(
      community: community ?? this.community,
      stats: stats ?? this.stats,
      articles: articles ?? this.articles,
      isMember: isMember ?? this.isMember,
      userRole: userRole ?? this.userRole,
      isFollowing: isFollowing ?? this.isFollowing,
      followAvailable: followAvailable ?? this.followAvailable,
      newsletterStats: newsletterStats ?? this.newsletterStats,
    );
  }
}

/// Loads a community's detail page — keyed by slug — aggregating the community,
/// stats, articles, membership, role, follow relationship and newsletter stats.
///
/// The family argument is passed to the constructor (Riverpod 3 hand-written
/// family pattern) and reused by [build]. Newsletter and follow lookups are
/// best-effort: environments without those tables still render the page.
///
/// Engagement seeding and like preloading are intentionally NOT done here —
/// they mutate `blogEngagementProvider` / `blogLikeProvider`, and cross-provider
/// mutation during `build()` throws. The screen seeds them via `ref.listen`.
class CommunityDetailNotifier extends AsyncNotifier<CommunityDetailState> {
  CommunityDetailNotifier(this.slug);

  final String slug;

  @override
  Future<CommunityDetailState> build() => _load();

  Future<CommunityDetailState> _load() async {
    final ds = ref.read(communityRemoteDatasourceProvider);

    final community = await ds.fetchCommunityBySlug(slug);
    if (community == null) {
      throw Exception('Community not found');
    }

    final stats = await ds.fetchCommunityStats(community.id);
    final articles = await ds.fetchCommunityArticles(community.id);

    final user = ref.read(currentUserProvider);
    final userId = user?.id;
    var isMember = false;
    String? userRole;
    var isFollowing = false;
    var followAvailable = true;
    if (userId != null) {
      isMember = await ds.isCommunityMember(community.id, userId);
      userRole = await ds.fetchUserRole(community.id, userId);
      try {
        isFollowing = await ds.isFollowingCommunity(
          communityId: community.id,
          userId: userId,
        );
      } catch (_) {
        followAvailable = false;
      }
    }

    // Newsletter stats are best-effort — if the table doesn't exist yet on this
    // environment we don't want to break the screen.
    CommunityNewsletterStats? newsletterStats;
    try {
      newsletterStats = await ds.fetchNewsletterStats(
        communityId: community.id,
        viewerEmail: user?.email,
      );
    } catch (_) {
      newsletterStats = null;
    }

    return CommunityDetailState(
      community: community,
      stats: stats,
      articles: articles,
      isMember: isMember,
      userRole: userRole,
      isFollowing: isFollowing,
      followAvailable: followAvailable,
      newsletterStats: newsletterStats,
    );
  }

  /// Re-fetches everything (pull-to-refresh, post-subscribe return).
  Future<void> refresh() async {
    state = const AsyncValue<CommunityDetailState>.loading();
    state = await AsyncValue.guard(_load);
  }

  /// Optimistically toggles the follow relationship, reverting on failure.
  ///
  /// No-ops when signed-out (the screen redirects to sign-in first). Rethrows
  /// the backend error after reverting so the UI can surface it.
  Future<void> toggleFollow() async {
    final current = state.value;
    if (current == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final wasFollowing = current.isFollowing;
    final stats = current.stats;
    state = AsyncData(
      current.copyWith(
        isFollowing: !wasFollowing,
        stats: stats == null
            ? null
            : CommunityStats(
                memberCount: stats.memberCount,
                followerCount: wasFollowing
                    ? (stats.followerCount - 1).clamp(0, 1 << 30)
                    : stats.followerCount + 1,
                publishedCount: stats.publishedCount,
              ),
      ),
    );

    try {
      final ds = ref.read(communityRemoteDatasourceProvider);
      if (wasFollowing) {
        await ds.unfollowCommunity(
          communityId: current.community.id,
          userId: user.id,
        );
      } else {
        await ds.followCommunity(
          communityId: current.community.id,
          userId: user.id,
        );
      }
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final communityDetailProvider =
    AsyncNotifierProvider.family<
      CommunityDetailNotifier,
      CommunityDetailState,
      String
    >(CommunityDetailNotifier.new);
