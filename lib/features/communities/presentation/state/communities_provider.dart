import 'package:Readme/core/providers/datasource_providers.dart';
import 'package:Readme/features/communities/domain/entities/community.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// All communities available to browse on the Communities tab.
///
/// Replaces `communities_screen`'s inline `CommunityRemoteDatasource` +
/// `setState` loading. Kept alive (non-autoDispose) so switching tabs doesn't
/// re-query; pull-to-refresh drives [CommunitiesNotifier.refresh].
class CommunitiesNotifier extends AsyncNotifier<List<Community>> {
  Future<List<Community>> _fetch() =>
      ref.read(communityRemoteDatasourceProvider).fetchCommunities();

  @override
  Future<List<Community>> build() => _fetch();

  Future<void> refresh() async {
    state = const AsyncValue<List<Community>>.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final communitiesProvider =
    AsyncNotifierProvider<CommunitiesNotifier, List<Community>>(
      CommunitiesNotifier.new,
    );
