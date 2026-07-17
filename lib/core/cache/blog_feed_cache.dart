import 'package:Readme/features/home_page/domain/entities/blog.dart';

/// In-memory cache for the published blog feed so Home and Search do not
/// duplicate the same Supabase query on every app launch.
class BlogFeedCache {
  BlogFeedCache._();

  static final BlogFeedCache instance = BlogFeedCache._();

  static const _ttl = Duration(minutes: 5);

  List<Blog>? _blogs;
  DateTime? _fetchedAt;
  Future<List<Blog>>? _inFlight;

  bool get isFresh =>
      _blogs != null &&
      _fetchedAt != null &&
      DateTime.now().difference(_fetchedAt!) < _ttl;

  List<Blog>? get blogs => _blogs;

  void set(List<Blog> blogs) {
    _blogs = List.unmodifiable(blogs);
    _fetchedAt = DateTime.now();
  }

  Future<List<Blog>> load(Future<List<Blog>> Function() fetch) async {
    if (isFresh) return _blogs!;
    if (_inFlight != null) return _inFlight!;

    _inFlight = fetch().then((blogs) {
      set(blogs);
      _inFlight = null;
      return blogs;
    }).catchError((Object error, StackTrace stackTrace) {
      _inFlight = null;
      Error.throwWithStackTrace(error, stackTrace);
    });

    return _inFlight!;
  }

  void invalidate() {
    _blogs = null;
    _fetchedAt = null;
    _inFlight = null;
  }
}
