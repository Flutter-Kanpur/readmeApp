import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/communities/presentation/state/communities_provider.dart';
import 'package:Readme/features/communities/presentation/widgets/community_card.dart';
import 'package:Readme/shared/widgets/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class CommunitiesScreen extends ConsumerWidget {
  const CommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(communitiesProvider);
    final communities = async.value;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.read(communitiesProvider.notifier).refresh(),
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
                if (async.isLoading && communities == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 80.h),
                        child: const CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (async.hasError && communities == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      message: async.error.toString().replaceFirst(
                        'Exception: ',
                        '',
                      ),
                      onRetry: () =>
                          ref.read(communitiesProvider.notifier).refresh(),
                    ),
                  )
                else if ((communities ?? const []).isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 100.h),
                    sliver: SliverList.separated(
                      itemCount: communities!.length,
                      separatorBuilder: (_, _) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final community = communities[index];
                        return CommunityCard(
                          community: community,
                          onTap: () =>
                              context.push('/community/${community.slug}'),
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
  const _ErrorState({required this.message, required this.onRetry});

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
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
