import 'package:Readme/core/providers/datasource_providers.dart';
import 'package:Readme/core/providers/repository_providers.dart';
import 'package:Readme/core/providers/supabase_providers.dart';
import 'package:Readme/features/home_page/domain/entities/blog.dart';
import 'package:Readme/features/profile_page/data/datasource/profile_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Immutable snapshot of the signed-in user's own profile screen.
///
/// A `null` [user] means signed-out; the screen renders its default shell.
class ProfileState {
  const ProfileState({
    this.user,
    this.profileData,
    this.publishedBlogs = const [],
    this.followStats = const UserFollowStats(followers: 0, following: 0),
  });

  final User? user;
  final Map<String, dynamic>? profileData;
  final List<Blog> publishedBlogs;
  final UserFollowStats followStats;

  bool get isSignedOut => user == null;
}

/// Loads the current user's profile, published blogs and follow stats.
///
/// Replaces the manual `onAuthStateChange` subscription in `ProfileScreen`:
/// `build` watches [currentUserProvider], so signing in/out or refreshing the
/// session automatically reloads (or clears) the profile.
class ProfileNotifier extends AsyncNotifier<ProfileState> {
  @override
  Future<ProfileState> build() {
    return _fetch(ref.watch(currentUserProvider));
  }

  Future<ProfileState> _fetch(User? user) async {
    if (user == null) return const ProfileState();

    final profileDs = ref.read(profileRemoteDatasourceProvider);
    final repo = ref.read(blogRepositoryProvider);

    final profileData = await profileDs.fetchProfileById(user.id);
    final publishedBlogs = await repo.getBlogsByAuthor(user.id);
    final followStats = await profileDs.fetchFollowStats(user.id);

    return ProfileState(
      user: user,
      profileData: profileData,
      publishedBlogs: publishedBlogs,
      followStats: followStats,
    );
  }

  /// Pull-to-refresh: reloads without changing the watched user.
  Future<void> refresh() async {
    final user = ref.read(currentUserProvider);
    state = const AsyncValue<ProfileState>.loading();
    state = await AsyncValue.guard(() => _fetch(user));
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
