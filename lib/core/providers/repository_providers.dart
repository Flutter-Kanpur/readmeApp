import 'package:Readme/core/providers/datasource_providers.dart';
import 'package:Readme/features/create_blog_page/data/repositories/create_blog_repository_impl.dart';
import 'package:Readme/features/create_blog_page/domain/repositories/create_blog_repository.dart';
import 'package:Readme/features/home_page/data/repositories/blog_repository_impl.dart';
import 'package:Readme/features/home_page/domain/repositories/blog_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes the [BlogRepository] interface; widgets depend on this, never on the
/// concrete [BlogRepositoryImpl].
final blogRepositoryProvider = Provider<BlogRepository>(
  (ref) => BlogRepositoryImpl(ref.watch(blogRemoteDatasourceProvider)),
);

/// Exposes the [CreateBlogRepository] used by the composer / drafts screens.
final createBlogRepositoryProvider = Provider<CreateBlogRepository>(
  (ref) =>
      CreateBlogRepositoryImpl(ref.watch(createBlogRemoteDatasourceProvider)),
);
