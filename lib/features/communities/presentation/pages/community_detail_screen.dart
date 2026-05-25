import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/communities/data/datasource/community_remote_datasource.dart';
import 'package:Readme/features/communities/data/models/community_article_model.dart';
import 'package:Readme/features/communities/domain/entities/community.dart';
import 'package:Readme/features/communities/presentation/widgets/community_blog_card.dart';
import 'package:Readme/features/communities/presentation/widgets/community_detail_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({
    super.key,
    required this.slug,
    this.community,
  });

  final String slug;
  final Community? community;

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  late final CommunityRemoteDatasource _datasource;

  Community? _community;
  CommunityStats? _stats;
  List<CommunityArticle> _articles = [];
  bool _isMember = false;
  String? _userRole;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _datasource = CommunityRemoteDatasource(Supabase.instance.client);
    _community = widget.community;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final community =
          _community ?? await _datasource.fetchCommunityBySlug(widget.slug);

      if (community == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Community not found';
          _isLoading = false;
        });
        return;
      }

      final stats = await _datasource.fetchCommunityStats(community.id);
      final articles = await _datasource.fetchCommunityArticles(community.id);

      final userId = Supabase.instance.client.auth.currentUser?.id;
      var isMember = false;
      String? userRole;
      if (userId != null) {
        isMember = await _datasource.isCommunityMember(community.id, userId);
        userRole = await _datasource.fetchUserRole(community.id, userId);
      }

      if (!mounted) return;
      setState(() {
        _community = community;
        _stats = stats;
        _articles = articles;
        _isMember = isMember;
        _userRole = userRole;
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const CommunityDetailShimmer()
            : _error != null
                ? _ErrorView(message: _error!, onBack: () => context.pop())
                : RefreshIndicator(
                    onRefresh: _loadDetail,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBackLink(),
                                SizedBox(height: 20.h),
                                _buildHeader(),
                                SizedBox(height: 24.h),
                                _buildActions(context),
                                SizedBox(height: 28.h),
                                Divider(color: Colors.grey.shade200, height: 1),
                                SizedBox(height: 24.h),
                                Text(
                                  'Published articles',
                                  style: textStyle_16BoldBlack().copyWith(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                              ],
                            ),
                          ),
                        ),
                        if (_articles.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: Text(
                                'No published articles yet.',
                                style: textStyle_14RegularGrey().copyWith(
                                  fontSize: 14.sp,
                                  color: AppColors.subtitles,
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 32.h),
                            sliver: SliverList.separated(
                              itemCount: _articles.length,
                              separatorBuilder: (_, __) => SizedBox(height: 12.h),
                              itemBuilder: (context, index) {
                                return CommunityBlogCard(
                                  article: _articles[index],
                                  community: _community!,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildBackLink() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back, size: 18.sp, color: AppColors.linkBlue),
          SizedBox(width: 6.w),
          Text(
            'Back to Communities',
            style: textStyle_14RegularBlack().copyWith(
              fontSize: 14.sp,
              color: AppColors.linkBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final community = _community!;
    final stats = _stats;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: AppImage(
            source: community.logoUrl,
            width: 88.w,
            height: 88.w,
            fit: BoxFit.cover,
            placeholder: Container(
              width: 88.w,
              height: 88.w,
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: Icon(
                Icons.groups_outlined,
                size: 36.sp,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                community.name,
                style: textStyle_24BoldBlack().copyWith(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              if (community.description != null &&
                  community.description!.trim().isNotEmpty) ...[
                SizedBox(height: 8.h),
                Text(
                  community.description!,
                  style: textStyle_14RegularGrey().copyWith(
                    fontSize: 14.sp,
                    height: 1.45,
                    color: AppColors.subtitles,
                  ),
                ),
              ],
              if (stats != null) ...[
                SizedBox(height: 10.h),
                Text(
                  '${stats.memberCount} ${stats.memberCount == 1 ? 'member' : 'members'} · ${stats.publishedCount} published',
                  style: textStyle_12RegularGrey().copyWith(
                    fontSize: 13.sp,
                    color: AppColors.subtitles,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            onPressed: () => context.push(
              '/community/${_community!.slug}/dashboard',
              extra: _community,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              'Community dashboard',
              style: textStyle_16BoldBlack().copyWith(
                fontSize: 14.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: OutlinedButton(
            onPressed: _isMember
                ? () => context.push('/create')
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'You need to be a community member to write for this community.',
                        ),
                      ),
                    );
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.black,
              side: const BorderSide(color: AppColors.black),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              'Write for community',
              style: textStyle_16BoldBlack().copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onBack,
  });

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: textStyle_14RegularGrey(),
          ),
          SizedBox(height: 16.h),
          OutlinedButton(onPressed: onBack, child: const Text('Go back')),
        ],
      ),
    );
  }
}
