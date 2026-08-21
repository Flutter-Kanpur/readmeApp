import 'dart:async';

import 'package:Readme/core/network/supabase_connectivity.dart';
import 'package:Readme/core/providers/supabase_providers.dart';
import 'package:Readme/core/secrets/app_secrets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Outcome of a sign-up attempt that completed without throwing.
///
/// Supabase does not throw when an email is already registered — it returns a
/// user with no identities — so that case is surfaced here rather than as an
/// [AuthException].
enum SignUpOutcome { sessionCreated, needsEmailConfirmation, alreadyRegistered }

/// Centralises the `supabase.auth.*` calls that were previously inlined across
/// the five auth screens, behind the [supabaseClientProvider] seam.
///
/// The [AsyncValue] state is purely a loading/last-error signal: screens drive
/// their submit button off `ref.watch(authControllerProvider).isLoading`. Each
/// method still **rethrows** auth errors so the screen keeps its own
/// error-message mapping and snackbar/navigation logic (unchanged behaviour).
///
/// [build] is intentionally synchronous so the initial state is `AsyncData`
/// (not `AsyncLoading`) — otherwise every auth button would flash a spinner on
/// first frame.
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Returns `null` when Supabase is unreachable (the screen shows its own
  /// connectivity message), otherwise the [SignUpOutcome]. Throws on auth
  /// errors so the screen can map them to friendly messages.
  Future<SignUpOutcome?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AsyncLoading();
    try {
      final reachable = await SupabaseConnectivity.canReachServer();
      if (!reachable) {
        state = const AsyncData(null);
        return null;
      }

      final result = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'name': username, 'full_name': username},
      );

      // Supabase may return a user with no identities when the email is
      // already registered (instead of throwing AuthException).
      final identities = result.user?.identities;
      if (result.user != null && (identities == null || identities.isEmpty)) {
        state = const AsyncData(null);
        return SignUpOutcome.alreadyRegistered;
      }

      if (result.user != null) {
        await _syncProfileAfterSignUp(
          userId: result.user!.id,
          username: username,
        );
      }

      state = const AsyncData(null);
      return result.session != null
          ? SignUpOutcome.sessionCreated
          : SignUpOutcome.needsEmailConfirmation;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> _syncProfileAfterSignUp({
    required String userId,
    required String username,
  }) async {
    try {
      await _client.from('profiles').upsert({
        'id': userId,
        'name': username,
        'username': username,
      });
    } catch (_) {
      // Best-effort: a trigger also seeds the profile server-side.
    }
  }

  /// Returns `false` when Supabase is unreachable. Throws on auth errors.
  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    try {
      final reachable = await SupabaseConnectivity.canReachServer();
      if (!reachable) {
        state = const AsyncData(null);
        return false;
      }
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: AppSecrets.authCallbackUrl,
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Updates the recovery-session password, then signs out so the user logs in
  /// fresh with the new credentials.
  ///
  /// The sign-out is **best-effort**: once [SupabaseClient.auth.updateUser]
  /// succeeds the password has already changed server-side, so a failing
  /// `signOut` (e.g. a transient network drop during token revocation) must not
  /// be reported to the screen as a failed password update. Only an
  /// `updateUser` error propagates; the recovery session expires on its own and
  /// the screen sends the user to `/signin` regardless.
  Future<void> updatePassword(String password) async {
    state = const AsyncLoading();
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Best-effort — see the doc comment above.
    }
    state = const AsyncData(null);
  }

  /// Exchanges a Google ID token for a Supabase session. The Welcome screen
  /// keeps its own loading flag (it spans the whole Google SDK dance), so this
  /// does not touch [state].
  Future<AuthResponse> signInWithGoogleIdToken(String idToken) {
    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
