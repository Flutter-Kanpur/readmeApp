import 'package:Readme/core/providers/supabase_providers.dart';
import 'package:Readme/features/blog_detail/data/datasource/blog_comment_datasource.dart';
import 'package:Readme/features/blog_detail/data/datasource/blog_like_datasource.dart';
import 'package:Readme/features/blog_detail/data/datasource/blog_view_datasource.dart';
import 'package:Readme/features/communities/data/datasource/community_remote_datasource.dart';
import 'package:Readme/features/create_blog_page/data/datasource/blog_draft_datasource.dart';
import 'package:Readme/features/create_blog_page/data/datasource/create_blog_remote_datasource.dart';
import 'package:Readme/features/home_page/data/datasource/blog_remote_datasource.dart';
import 'package:Readme/features/profile_page/data/datasource/profile_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Remote datasources. Each depends only on the Supabase client, so a single
/// [supabaseClientProvider] override in a test swaps the backend everywhere.

final blogRemoteDatasourceProvider = Provider<BlogRemoteDatasource>(
  (ref) => BlogRemoteDatasource(ref.watch(supabaseClientProvider)),
);

final profileRemoteDatasourceProvider = Provider<ProfileRemoteDatasource>(
  (ref) => ProfileRemoteDatasource(ref.watch(supabaseClientProvider)),
);

final communityRemoteDatasourceProvider = Provider<CommunityRemoteDatasource>(
  (ref) => CommunityRemoteDatasource(ref.watch(supabaseClientProvider)),
);

final blogCommentDatasourceProvider = Provider<BlogCommentDatasource>(
  (ref) => BlogCommentDatasource(ref.watch(supabaseClientProvider)),
);

final blogViewDatasourceProvider = Provider<BlogViewDatasource>(
  (ref) => BlogViewDatasource(ref.watch(supabaseClientProvider)),
);

final blogLikeDatasourceProvider = Provider<BlogLikeDatasource>(
  (ref) => BlogLikeDatasource(ref.watch(supabaseClientProvider)),
);

final blogDraftDatasourceProvider = Provider<BlogDraftDatasource>(
  (ref) => BlogDraftDatasource(ref.watch(supabaseClientProvider)),
);

final createBlogRemoteDatasourceProvider = Provider<CreateBlogRemoteDatasource>(
  (ref) => CreateBlogRemoteDatasource(ref.watch(supabaseClientProvider)),
);
