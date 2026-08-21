import 'package:Readme/core/providers/datasource_providers.dart';
import 'package:Readme/core/providers/repository_providers.dart';
import 'package:Readme/core/providers/supabase_providers.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:Readme/features/profile_page/data/datasource/profile_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable snapshot of another user's public profile.
class AuthorProfileState {
  const AuthorProfileState({
    this.profileData,
    this.publishedBlogs = const [],
    this.followStats = const UserFollowStats(followers: 0, following: 0),
    this.isFollowing = false,
  });

  final Map<String, dynamic>? profileData;
  final List<Blog> publishedBlogs;
  final UserFollowStats followStats;
  final bool isFollowing;

  AuthorProfileState copyWith({
    Map<String, dynamic>? profileData,
    List<Blog>? publishedBlogs,
    UserFollowStats? followStats,
    bool? isFollowing,
  }) {
    return AuthorProfileState(
      profileData: profileData ?? this.profileData,
      publishedBlogs: publishedBlogs ?? this.publishedBlogs,
      followStats: followStats ?? this.followStats,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

/// Loads a single author's profile, published blogs, follow stats and the
/// current user's follow relationship — keyed by the author's user id.
///
/// The family argument is passed to the constructor (Riverpod 3 hand-written
/// family pattern) and reused by [build].
class AuthorProfileNotifier extends AsyncNotifier<AuthorProfileState> {
  AuthorProfileNotifier(this.userId);

  final String userId;

  @override
  Future<AuthorProfileState> build() => _load();

  Future<AuthorProfileState> _load() async {
    final profileDs = ref.read(profileRemoteDatasourceProvider);
    final repo = ref.read(blogRepositoryProvider);

    final profileData = await profileDs.fetchProfileById(userId);
    if (profileData == null) {
      throw Exception('User not found');
    }

    final publishedBlogs = await repo.getBlogsByAuthor(userId);
    final followStats = await profileDs.fetchFollowStats(userId);

    var isFollowing = false;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && currentUser.id != userId) {
      isFollowing = await profileDs.isFollowingAuthor(
        followerId: currentUser.id,
        authorId: userId,
      );
    }

    return AuthorProfileState(
      profileData: profileData,
      publishedBlogs: publishedBlogs,
      followStats: followStats,
      isFollowing: isFollowing,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<AuthorProfileState>.loading();
    state = await AsyncValue.guard(_load);
  }

  /// Optimistically toggles the follow relationship, reverting on failure.
  ///
  /// No-ops when signed-out or viewing your own profile. Rethrows the backend
  /// error after reverting so the UI can surface it.
  Future<void> toggleFollow() async {
    final current = state.value;
    if (current == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null || user.id == userId) return;

    final wasFollowing = current.isFollowing;
    state = AsyncData(
      current.copyWith(
        isFollowing: !wasFollowing,
        followStats: UserFollowStats(
          followers: wasFollowing
              ? (current.followStats.followers - 1).clamp(0, 1 << 30)
              : current.followStats.followers + 1,
          following: current.followStats.following,
        ),
      ),
    );

    try {
      final profileDs = ref.read(profileRemoteDatasourceProvider);
      if (wasFollowing) {
        await profileDs.unfollowAuthor(
          followerId: user.id,
          authorId: userId,
        );
      } else {
        await profileDs.followAuthor(followerId: user.id, authorId: userId);
      }
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final authorProfileProvider =
    AsyncNotifierProvider.family<
      AuthorProfileNotifier,
      AuthorProfileState,
      String
    >(AuthorProfileNotifier.new);
