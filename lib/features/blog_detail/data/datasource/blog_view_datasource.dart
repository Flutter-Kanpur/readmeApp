import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Records and reads blog view counts.
///
/// Uses the `view_count` column on `blogs` plus `increment_blog_view` RPC.
/// Client-side dedupe prevents the same device from inflating counts on every
/// reopen within 24 hours.
class BlogViewDatasource {
  BlogViewDatasource(this.client);

  final SupabaseClient client;

  static const _prefsPrefix = 'blog_viewed_';
  static const _dedupeWindow = Duration(hours: 24);

  Future<int> fetchViewCount(String blogId) async {
    try {
      final response = await client
          .from('blogs')
          .select('view_count')
          .eq('blog_id', blogId)
          .maybeSingle();
      return _asInt(response?['view_count']);
    } catch (_) {
      return 0;
    }
  }

  /// Increments the server counter once per device per blog per day.
  /// Returns the latest count (or null if the feature is unavailable).
  Future<int?> recordView(String blogId) async {
    try {
      if (await _wasViewedRecently(blogId)) {
        return fetchViewCount(blogId);
      }

      final response = await client.rpc(
        'increment_blog_view',
        params: {'p_blog_id': blogId},
      );

      await _markViewed(blogId);
      return _asInt(response);
    } catch (error) {
      // Column / RPC may not exist yet on older environments.
      debugPrintSafe('recordView failed: $error');
      return null;
    }
  }

  Future<bool> _wasViewedRecently(String blogId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefsPrefix$blogId');
    if (raw == null) return false;
    final when = DateTime.tryParse(raw);
    if (when == null) return false;
    return DateTime.now().difference(when) < _dedupeWindow;
  }

  Future<void> _markViewed(String blogId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsPrefix$blogId',
      DateTime.now().toIso8601String(),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

void debugPrintSafe(String message) {
  // Avoid importing flutter/foundation just for debugPrint in datasource.
  assert(() {
    // ignore: avoid_print
    print(message);
    return true;
  }());
}
