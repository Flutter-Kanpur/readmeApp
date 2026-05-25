import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/communities/data/datasource/community_remote_datasource.dart';
import 'package:Readme/features/communities/domain/entities/community.dart';
import 'package:Readme/features/communities/presentation/widgets/community_card.dart';
import 'package:Readme/shared/widgets/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  late final CommunityRemoteDatasource _datasource;

  List<Community> _communities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _datasource = CommunityRemoteDatasource(Supabase.instance.client);
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final communities = await _datasource.fetchCommunities();
      if (!mounted) return;
      setState(() {
        _communities = communities;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadCommunities,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMMUNITIES',
                          style: textStyle_12RegularGrey().copyWith(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: AppColors.subtitles,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Write together',
                          style: textStyle_24BoldBlack().copyWith(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Join a community, co-author posts, and publish under a shared brand.',
                          style: textStyle_16RegularGrey().copyWith(
                            fontSize: 15.sp,
                            height: 1.5,
                            color: AppColors.subtitles,
                          ),
                        ),
                        SizedBox(height: 28.h),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 80.h),
                        child: const CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      message: _error!,
                      onRetry: _loadCommunities,
                    ),
                  )
                else if (_communities.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 100.h),
                    sliver: SliverList.separated(
                      itemCount: _communities.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final community = _communities[index];
                        return CommunityCard(
                          community: community,
                          onTap: () => context.push(
                            '/community/${community.slug}',
                            extra: community,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 56.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              'No communities yet',
              style: textStyle_16BoldBlack().copyWith(fontSize: 18.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              'Communities will appear here once they are created on the web.',
              textAlign: TextAlign.center,
              style: textStyle_14RegularGrey().copyWith(
                fontSize: 14.sp,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: Colors.grey.shade500),
            SizedBox(height: 16.h),
            Text(
              'Could not load communities',
              style: textStyle_16BoldBlack().copyWith(fontSize: 18.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textStyle_14RegularGrey().copyWith(fontSize: 13.sp),
            ),
            SizedBox(height: 20.h),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
