import 'package:Readme/core/network/readme_supabase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The active Supabase client — the single seam every datasource builds on.
///
/// In standalone mode this is `Supabase.instance.client`; when embedded in a
/// host app it may be an injected override (see [ReadmeSupabase.bind]).
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => ReadmeSupabase.client,
);

/// Emits an [AuthState] on every sign-in / sign-out / token refresh.
final authStateChangesProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(supabaseClientProvider).auth.onAuthStateChange,
);

/// The currently signed-in user, or `null`.
///
/// Recomputes whenever [authStateChangesProvider] emits, so widgets that watch
/// it rebuild on login/logout without each wiring their own auth subscription.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser;
});
