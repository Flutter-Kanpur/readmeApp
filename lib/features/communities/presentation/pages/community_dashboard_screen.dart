import 'dart:io';

import 'package:Readme/core/utils/app_colors.dart';
import 'package:Readme/core/utils/app_image.dart';
import 'package:Readme/core/utils/text_style.dart';
import 'package:Readme/features/communities/data/datasource/community_remote_datasource.dart';
import 'package:Readme/features/communities/data/models/community_dashboard_models.dart';
import 'package:Readme/features/communities/data/models/community_newsletter_models.dart';
import 'package:Readme/features/communities/domain/entities/community.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _DashboardTab { drafts, newsletter, requests, settings, members }

class CommunityDashboardScreen extends StatefulWidget {
  const CommunityDashboardScreen({
    super.key,
    required this.slug,
    this.community,
  });

  final String slug;
  final Community? community;

  @override
  State<CommunityDashboardScreen> createState() =>
      _CommunityDashboardScreenState();
}

class _CommunityDashboardScreenState extends State<CommunityDashboardScreen> {
  static const _maxImageBytes = 2 * 1024 * 1024;
  static const _roles = ['admin', 'contributor'];
  // Only contributor can be self-requested. Admin is granted later via the
  // Members tab by an existing admin (matches the web RLS policy on
  // `community_join_requests`).
  static const _requestableRoles = ['contributor'];

  late final CommunityRemoteDatasource _datasource;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _inviteNameController = TextEditingController();

  Community? _community;
  String? _userRole;
  _DashboardTab _selectedTab = _DashboardTab.drafts;

  List<CommunityDraft> _drafts = [];
  List<CommunityJoinRequest> _requests = [];
  List<CommunityMember> _members = [];

  XFile? _pickedLogo;
  String? _savedLogoUrl;
  bool _logoDirty = false;
  bool _isSavingLogo = false;
  String _inviteRole = 'contributor';
  bool _isInviting = false;

  // Non-member join request flow.
  CommunityJoinRequest? _pendingRequest;
  String _requestedRole = 'contributor';
  bool _isSubmittingRequest = false;
  bool _isCancellingRequest = false;
  bool _justSentRequest = false;

  // Newsletter
  static const _maxAttachmentBytes = 20 * 1024 * 1024;
  final TextEditingController _issueTitleController = TextEditingController();
  final TextEditingController _issueBodyController = TextEditingController();
  CommunityNewsletterStats? _newsletterStats;
  List<CommunityNewsletterIssue> _newsletterIssues = [];
  String? _newsletterError;
  PlatformFile? _pickedAttachment;
  bool _isPublishingIssue = false;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _datasource = CommunityRemoteDatasource(Supabase.instance.client);
    _community = widget.community;
    _loadDashboard();
  }

  @override
  void dispose() {
    _inviteNameController.dispose();
    _issueTitleController.dispose();
    _issueBodyController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
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

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _error = 'You must be signed in to view the dashboard.';
          _isLoading = false;
        });
        return;
      }

      final role = await _datasource.fetchUserRole(community.id, userId);

      // Non-members see a "Request to join" flow instead of an error.
      if (role == null) {
        final pending = await _datasource.fetchUserPendingJoinRequest(
          communityId: community.id,
          userId: userId,
        );
        if (!mounted) return;
        setState(() {
          _community = community;
          _userRole = null;
          _pendingRequest = pending;
          _isLoading = false;
        });
        return;
      }

      // Non-admin members (e.g. contributors) get a member-status view
      // rather than a strict error so they can see the role they hold and
      // navigate from there.
      if (role != 'admin') {
        if (!mounted) return;
        setState(() {
          _community = community;
          _userRole = role;
          _isLoading = false;
        });
        return;
      }

      await _loadTabData(community.id);

      if (!mounted) return;
      setState(() {
        _community = community;
        _userRole = role;
        _savedLogoUrl = community.logoUrl;
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

  Future<void> _loadTabData(String communityId) async {
    final drafts = await _datasource.fetchCommunityDrafts(communityId);
    final requests = await _datasource.fetchPendingJoinRequests(communityId);
    final members = await _datasource.fetchCommunityMembers(communityId);

    // Load newsletter pieces independently so a failure on one (e.g. a 0-row
    // RLS read on issues) doesn't hide the publish form. Capture any error
    // messages so we can surface them in the UI rather than silently hiding
    // the feature.
    CommunityNewsletterStats? newsletterStats;
    List<CommunityNewsletterIssue> issues = [];
    String? newsletterError;

    try {
      newsletterStats = await _datasource.fetchNewsletterStats(
        communityId: communityId,
      );
    } catch (e) {
      newsletterError = _describeNewsletterError(e);
    }

    try {
      issues = await _datasource.fetchNewsletterIssues(communityId);
    } catch (e) {
      newsletterError ??= _describeNewsletterError(e);
    }

    if (!mounted) return;
    setState(() {
      _drafts = drafts;
      _requests = requests;
      _members = members;
      _newsletterStats = newsletterStats ??
          const CommunityNewsletterStats(
            subscriberCount: 0,
            isSubscribed: false,
          );
      _newsletterIssues = issues;
      _newsletterError = newsletterError;
    });
  }

  String _describeNewsletterError(Object e) {
    if (e is PostgrestException) {
      final msg = e.message;
      final code = e.code;
      if (code == '42P01' || msg.contains('does not exist')) {
        return 'Newsletter tables not found on Supabase. '
            'Expected `community_newsletter_subscribers` and '
            '`community_newsletter_issues`.';
      }
      if (code == '42501') {
        return 'Row-level security blocked the newsletter read for this user.';
      }
      return 'Newsletter load failed: $msg';
    }
    return 'Newsletter load failed: $e';
  }

  Future<void> _refreshCurrentTab() async {
    if (_community == null) return;
    await _loadTabData(_community!.id);
  }

  Future<void> _pickLogo() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    if (bytes.length > _maxImageBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image must be 2MB or smaller.')),
      );
      return;
    }

    setState(() {
      _pickedLogo = picked;
      _logoDirty = true;
    });
  }

  Future<void> _saveLogo() async {
    if (_community == null || !_logoDirty || _pickedLogo == null) return;

    setState(() => _isSavingLogo = true);
    try {
      final bytes = await _pickedLogo!.readAsBytes();
      final fileExt = _pickedLogo!.path.split('.').last;
      final logoUrl = await _datasource.uploadCommunityLogo(
        communityId: _community!.id,
        bytes: bytes,
        fileExt: fileExt,
      );
      final cacheBusted = '$logoUrl?v=${DateTime.now().millisecondsSinceEpoch}';
      await _datasource.updateCommunityLogo(
        communityId: _community!.id,
        logoUrl: cacheBusted,
      );

      if (!mounted) return;
      setState(() {
        _savedLogoUrl = cacheBusted;
        _pickedLogo = null;
        _logoDirty = false;
        _community = Community(
          id: _community!.id,
          slug: _community!.slug,
          name: _community!.name,
          description: _community!.description,
          logoUrl: cacheBusted,
          createdBy: _community!.createdBy,
          createdAt: _community!.createdAt,
          updatedAt: DateTime.now(),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community icon saved.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save icon: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingLogo = false);
    }
  }

  Future<void> _updateMemberRole(CommunityMember member, String role) async {
    try {
      await _datasource.updateMemberRole(member.id, role);
      await _refreshCurrentTab();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(CommunityMember member) async {
    try {
      await _datasource.removeMember(member.id);
      await _refreshCurrentTab();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove member: $e')),
        );
      }
    }
  }

  Future<void> _inviteMember() async {
    if (_community == null) return;
    final name = _inviteNameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isInviting = true);
    try {
      await _datasource.inviteMemberByName(
        communityId: _community!.id,
        profileName: name,
        role: _inviteRole,
      );
      _inviteNameController.clear();
      await _refreshCurrentTab();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member invited successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isInviting = false);
    }
  }

  Future<void> _approveRequest(CommunityJoinRequest request) async {
    if (_community == null) return;
    try {
      await _datasource.approveJoinRequest(request.id, _community!.id);
      await _refreshCurrentTab();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve request: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(CommunityJoinRequest request) async {
    try {
      await _datasource.rejectJoinRequest(request.id);
      await _refreshCurrentTab();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject request: $e')),
        );
      }
    }
  }

  // ============================================================
  // Newsletter publishing
  // ============================================================

  Future<void> _pickNewsletterAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    if (file.size > _maxAttachmentBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attachment must be 20MB or smaller.')),
        );
      }
      return;
    }

    setState(() => _pickedAttachment = file);
  }

  void _clearNewsletterAttachment() {
    setState(() => _pickedAttachment = null);
  }

  String _contentTypeFor(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _publishNewsletterIssue() async {
    if (_community == null) return;
    final title = _issueTitleController.text.trim();
    final body = _issueBodyController.text.trim();
    final attachment = _pickedAttachment;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an issue title.')),
      );
      return;
    }
    if (body.isEmpty && attachment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a body or an attachment before publishing.'),
        ),
      );
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isPublishingIssue = true);
    try {
      String? attachmentUrl;
      if (attachment != null) {
        final bytes = attachment.bytes;
        if (bytes == null) {
          throw Exception('Could not read the selected file.');
        }
        attachmentUrl = await _datasource.uploadNewsletterAttachment(
          communityId: _community!.id,
          bytes: bytes,
          fileName: attachment.name,
          contentType: _contentTypeFor(attachment.name),
        );
      }

      await _datasource.publishNewsletterIssue(
        communityId: _community!.id,
        title: title,
        body: body,
        createdBy: userId,
        attachmentUrl: attachmentUrl,
      );

      _issueTitleController.clear();
      _issueBodyController.clear();
      setState(() => _pickedAttachment = null);

      await _refreshCurrentTab();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Newsletter issue published.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to publish: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishingIssue = false);
    }
  }

  Future<void> _submitJoinRequest() async {
    if (_community == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to request to join.')),
      );
      return;
    }

    setState(() => _isSubmittingRequest = true);
    try {
      await _datasource.createJoinRequest(
        communityId: _community!.id,
        userId: userId,
        role: _requestedRole,
      );
      final pending = await _datasource.fetchUserPendingJoinRequest(
        communityId: _community!.id,
        userId: userId,
      );
      if (!mounted) return;
      setState(() {
        _pendingRequest = pending;
        _justSentRequest = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyJoinRequestError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingRequest = false);
    }
  }

  String _friendlyJoinRequestError(Object e) {
    final code = e is PostgrestException ? e.code : null;
    final raw = e is PostgrestException
        ? (e.message)
        : e.toString().replaceFirst('Exception: ', '');

    if (code == '42501' || raw.toLowerCase().contains('row-level security')) {
      return "You can't request this role. Ask an existing admin to promote "
          'you instead.';
    }
    if (code == '23505') {
      return 'You already have a pending request for this community.';
    }
    return 'Could not send request: $raw';
  }

  Future<void> _cancelJoinRequest() async {
    final request = _pendingRequest;
    if (request == null) return;

    setState(() => _isCancellingRequest = true);
    try {
      await _datasource.cancelJoinRequest(request.id);
      if (!mounted) return;
      setState(() {
        _pendingRequest = null;
        _justSentRequest = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request cancelled.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not cancel request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancellingRequest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(message: _error!, onBack: () => context.pop())
                : _userRole == 'admin'
                    ? _buildAdminDashboard()
                    : _buildJoinRequestView(),
      ),
    );
  }

  Widget _buildAdminDashboard() {
    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBackLink(),
            SizedBox(height: 16.h),
            Text(
              '${_community!.name} dashboard',
              style: textStyle_24BoldBlack().copyWith(
                fontSize: 26.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your role: $_userRole',
              style: textStyle_14RegularGrey().copyWith(
                fontSize: 14.sp,
                color: AppColors.subtitles,
              ),
            ),
            SizedBox(height: 24.h),
            _buildTabBar(),
            SizedBox(height: 20.h),
            _buildTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinRequestView() {
    final community = _community!;
    final pending = _pendingRequest;
    final hasPending = pending != null;
    final isMember = _userRole != null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackLink(),
          SizedBox(height: 16.h),
          Text(
            '${community.name} dashboard',
            style: textStyle_24BoldBlack().copyWith(
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Your role: ${_userRole ?? 'none'}',
            style: textStyle_14RegularGrey().copyWith(
              fontSize: 14.sp,
              color: AppColors.subtitles,
            ),
          ),
          SizedBox(height: 20.h),
          if (isMember)
            _MemberStatusCard(
              communityName: community.name,
              role: _userRole!,
            )
          else ...[
            if (hasPending && _justSentRequest) ...[
              _SentBanner(),
              SizedBox(height: 16.h),
            ],
            if (hasPending)
              _PendingRequestCard(
                communityName: community.name,
                request: pending,
                isCancelling: _isCancellingRequest,
                onCancel: _cancelJoinRequest,
              )
            else
              _RequestForm(
                communityName: community.name,
                role: _requestedRole,
                roles: _requestableRoles,
                isSubmitting: _isSubmittingRequest,
                onRoleChanged: (role) {
                  if (role != null) setState(() => _requestedRole = role);
                },
                onSubmit: _submitJoinRequest,
              ),
          ],
        ],
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
            'Back to ${_community?.name ?? 'community'}',
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

  Widget _buildTabBar() {
    const tabs = _DashboardTab.values;

    String labelFor(_DashboardTab tab) {
      switch (tab) {
        case _DashboardTab.drafts:
          return 'Drafts';
        case _DashboardTab.newsletter:
          return 'Newsletter';
        case _DashboardTab.requests:
          return _requests.isEmpty
              ? 'Requests'
              : 'Requests (${_requests.length})';
        case _DashboardTab.settings:
          return 'Settings';
        case _DashboardTab.members:
          return 'Members';
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Material(
              color: isSelected ? AppColors.black : Colors.white,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => setState(() => _selectedTab = tab),
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected ? AppColors.black : Colors.grey.shade200,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                  child: Text(
                    labelFor(tab),
                    style: textStyle_14RegularBlack().copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.black,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case _DashboardTab.drafts:
        return _DashboardCard(
          title: 'Community drafts',
          child: _drafts.isEmpty
              ? _emptyText('No drafts for this community.')
              : Column(
                  children: _drafts
                      .map(
                        (draft) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      draft.title,
                                      style: textStyle_16BoldBlack().copyWith(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      draft.authorName,
                                      style: textStyle_12RegularGrey().copyWith(
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        );
      case _DashboardTab.newsletter:
        return _buildNewsletterTab();
      case _DashboardTab.requests:
        return _DashboardCard(
          title: 'Pending join requests',
          child: _requests.isEmpty
              ? _emptyText('No pending requests.')
              : Column(
                  children: _requests
                      .map(
                        (request) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  request.name,
                                  style: textStyle_14RegularBlack().copyWith(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _rejectRequest(request),
                                child: Text(
                                  'Reject',
                                  style: TextStyle(color: Colors.red.shade600),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _approveRequest(request),
                                child: const Text('Approve'),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        );
      case _DashboardTab.settings:
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: _pickedLogo != null
                        ? Image.file(
                            File(_pickedLogo!.path),
                            width: 88.w,
                            height: 88.w,
                            fit: BoxFit.cover,
                          )
                        : AppImage(
                            source: _savedLogoUrl,
                            width: 88.w,
                            height: 88.w,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              width: 88.w,
                              height: 88.w,
                              color: Colors.grey.shade100,
                              child: Icon(
                                Icons.groups_outlined,
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
                          'Community icon',
                          style: textStyle_16BoldBlack().copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Shown on your community profile, article cards, and listings. Square images work best.',
                          style: textStyle_14RegularGrey().copyWith(
                            fontSize: 13.sp,
                            height: 1.45,
                            color: AppColors.subtitles,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: [
                  OutlinedButton(
                    onPressed: _pickLogo,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.black,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text('Choose image'),
                  ),
                  ElevatedButton(
                    onPressed: _logoDirty && !_isSavingLogo ? _saveLogo : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      disabledBackgroundColor: Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: _isSavingLogo
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save icon'),
                  ),
                ],
              ),
            ],
          ),
        );
      case _DashboardTab.members:
        return _DashboardCard(
          title: 'Members',
          child: Column(
            children: [
              ..._members.map(
                (member) => Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: textStyle_14RegularBlack().copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          _RoleDropdown(
                            value: member.role,
                            roles: _roles,
                            onChanged: (role) {
                              if (role != null) _updateMemberRole(member, role);
                            },
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _removeMember(member),
                            child: Text(
                              'Remove',
                              style: TextStyle(color: Colors.red.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Divider(color: Colors.grey.shade200, height: 32.h),
              TextField(
                controller: _inviteNameController,
                decoration: InputDecoration(
                  hintText: 'Exact profile name to invite',
                  hintStyle: textStyle_14RegularGrey().copyWith(fontSize: 13.sp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _RoleDropdown(
                    value: _inviteRole,
                    roles: _roles,
                    onChanged: (role) {
                      if (role != null) setState(() => _inviteRole = role);
                    },
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isInviting ? null : _inviteMember,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 14.h,
                      ),
                    ),
                    child: _isInviting
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Invite'),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }

  Widget _emptyText(String message) {
    return Text(
      message,
      style: textStyle_14RegularGrey().copyWith(
        fontSize: 14.sp,
        color: AppColors.subtitles,
      ),
    );
  }

  // ============================================================
  // Newsletter tab content
  // ============================================================
  Widget _buildNewsletterTab() {
    final stats = _newsletterStats ??
        const CommunityNewsletterStats(
          subscriberCount: 0,
          isSubscribed: false,
        );
    final attachment = _pickedAttachment;
    final canPublish = !_isPublishingIssue &&
        _issueTitleController.text.trim().isNotEmpty &&
        (_issueBodyController.text.trim().isNotEmpty || attachment != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_newsletterError != null) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFFFD9A8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16.sp,
                  color: const Color(0xFFB26500),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _newsletterError!,
                    style: textStyle_12RegularGrey().copyWith(
                      fontSize: 12.sp,
                      color: const Color(0xFFB26500),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
        ],
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Monthly newsletter',
                      style: textStyle_16BoldBlack().copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${stats.subscriberCount} ${stats.subscriberCount == 1 ? 'subscriber' : 'subscribers'}',
                    style: textStyle_12RegularGrey().copyWith(
                      fontSize: 12.sp,
                      color: AppColors.subtitles,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              _newsletterFieldLabel('ISSUE TITLE'),
              SizedBox(height: 8.h),
              _newsletterTextField(
                controller: _issueTitleController,
                hint: 'e.g. May 2026 — what we shipped',
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: 16.h),
              _newsletterFieldLabel('BODY (OPTIONAL IF A FILE IS ATTACHED)'),
              SizedBox(height: 8.h),
              _newsletterTextField(
                controller: _issueBodyController,
                hint: "Hi everyone,  Here's what's been happening this month…",
                maxLines: 6,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: 6.h),
              Text(
                "Plain text. Separate paragraphs with a blank line — they'll render as paragraphs on the public archive page.",
                style: textStyle_12RegularGrey().copyWith(
                  fontSize: 12.sp,
                  color: AppColors.subtitles,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 18.h),
              _newsletterFieldLabel('ATTACHMENT (OPTIONAL)'),
              SizedBox(height: 8.h),
              if (attachment != null)
                _AttachmentChip(
                  fileName: attachment.name,
                  bytes: attachment.size,
                  onClear: _clearNewsletterAttachment,
                )
              else
                OutlinedButton(
                  onPressed: _pickNewsletterAttachment,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.black,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Choose PDF or image'),
                ),
              SizedBox(height: 6.h),
              Text(
                'PDF, PNG or JPEG up to 20 MB. Subscribers and visitors can download it from the newsletter page.',
                style: textStyle_12RegularGrey().copyWith(
                  fontSize: 12.sp,
                  color: AppColors.subtitles,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: canPublish ? _publishNewsletterIssue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    disabledBackgroundColor: Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 22.w,
                      vertical: 14.h,
                    ),
                  ),
                  child: _isPublishingIssue
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Publish issue'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'Past issues',
          style: textStyle_16BoldBlack().copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12.h),
        if (_newsletterIssues.isEmpty)
          _emptyText('No newsletters published yet.')
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _newsletterIssues
                .map(
                  (issue) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _NewsletterIssueRow(issue: issue),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _newsletterFieldLabel(String text) {
    return Text(
      text,
      style: textStyle_12RegularGrey().copyWith(
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.subtitles,
      ),
    );
  }

  Widget _newsletterTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      style: textStyle_14RegularBlack().copyWith(
        fontSize: 14.sp,
        color: AppColors.black,
        height: 1.45,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: textStyle_14RegularGrey().copyWith(
          fontSize: 13.sp,
          color: AppColors.subtitles,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: 12.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: AppColors.linkBlue),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textStyle_16BoldBlack().copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({
    required this.value,
    required this.roles,
    required this.onChanged,
  });

  final String value;
  final List<String> roles;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          items: roles
              .map(
                (role) => DropdownMenuItem(
                  value: role,
                  child: Text(role),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
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
          Text(message, textAlign: TextAlign.center),
          SizedBox(height: 16.h),
          OutlinedButton(onPressed: onBack, child: const Text('Go back')),
        ],
      ),
    );
  }
}

class _MemberStatusCard extends StatelessWidget {
  const _MemberStatusCard({
    required this.communityName,
    required this.role,
  });

  final String communityName;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 16.sp,
                  color: const Color(0xFF1B7D33),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: textStyle_14RegularBlack().copyWith(
                      fontSize: 15.sp,
                      color: AppColors.black,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      const TextSpan(text: "You're a "),
                      TextSpan(
                        text: role,
                        style: textStyle_14RegularBlack().copyWith(
                          fontSize: 15.sp,
                          color: AppColors.black,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      TextSpan(text: ' in $communityName.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'You can write and publish for this community. Only admins can manage drafts, members and join requests.',
            style: textStyle_14RegularGrey().copyWith(
              fontSize: 13.sp,
              height: 1.55,
              color: AppColors.subtitles,
            ),
          ),
        ],
      ),
    );
  }
}

class _SentBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        'Join request sent. An admin will review it soon.',
        style: textStyle_14RegularBlack().copyWith(
          fontSize: 14.sp,
          color: AppColors.black,
          height: 1.4,
        ),
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({
    required this.communityName,
    required this.request,
    required this.isCancelling,
    required this.onCancel,
  });

  final String communityName;
  final CommunityJoinRequest request;
  final bool isCancelling;
  final VoidCallback onCancel;

  String _formatTimestamp(DateTime when) {
    final local = when.toLocal();
    String pad(int v) => v.toString().padLeft(2, '0');
    final date =
        '${pad(local.day)}/${pad(local.month)}/${local.year}';
    final time =
        '${pad(local.hour)}:${pad(local.minute)}:${pad(local.second)}';
    return '$date, $time';
  }

  @override
  Widget build(BuildContext context) {
    final role = request.requestedRole?.trim().isNotEmpty == true
        ? request.requestedRole!
        : 'member';
    final createdAt = request.createdAt;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: textStyle_14RegularBlack().copyWith(
                fontSize: 15.sp,
                color: AppColors.black,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
              children: [
                const TextSpan(text: 'Your request to join as '),
                TextSpan(
                  text: role,
                  style: textStyle_14RegularBlack().copyWith(
                    fontSize: 15.sp,
                    color: AppColors.black,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                const TextSpan(text: ' is pending admin approval.'),
              ],
            ),
          ),
          if (createdAt != null) ...[
            SizedBox(height: 8.h),
            Text(
              'Requested on ${_formatTimestamp(createdAt)}',
              style: textStyle_12RegularGrey().copyWith(
                fontSize: 12.sp,
                color: AppColors.subtitles,
              ),
            ),
          ],
          SizedBox(height: 18.h),
          OutlinedButton(
            onPressed: isCancelling ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.black,
              side: const BorderSide(color: AppColors.black),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 12.h,
              ),
            ),
            child: isCancelling
                ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.black,
                    ),
                  )
                : Text(
                    'Cancel request',
                    style: textStyle_16BoldBlack().copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RequestForm extends StatelessWidget {
  const _RequestForm({
    required this.communityName,
    required this.role,
    required this.roles,
    required this.isSubmitting,
    required this.onRoleChanged,
    required this.onSubmit,
  });

  final String communityName;
  final String role;
  final List<String> roles;
  final bool isSubmitting;
  final ValueChanged<String?> onRoleChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request to join $communityName. An admin must approve before you can write or publish as this community.',
            style: textStyle_14RegularGrey().copyWith(
              fontSize: 14.sp,
              height: 1.55,
              color: AppColors.subtitles,
            ),
          ),
          SizedBox(height: 20.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Requested role',
                style: textStyle_14RegularBlack().copyWith(
                  fontSize: 14.sp,
                  color: AppColors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _RoleDropdown(
                value: role,
                roles: roles,
                onChanged: onRoleChanged,
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  disabledBackgroundColor: Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 22.w,
                    vertical: 14.h,
                  ),
                ),
                child: isSubmitting
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Request to join',
                        style: textStyle_16BoldBlack().copyWith(
                          fontSize: 14.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.fileName,
    required this.bytes,
    required this.onClear,
  });

  final String fileName;
  final int bytes;
  final VoidCallback onClear;

  String _formatBytes() {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.attach_file_rounded,
            size: 16.sp,
            color: AppColors.black,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName,
                  style: textStyle_14RegularBlack().copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  _formatBytes(),
                  style: textStyle_12RegularGrey().copyWith(
                    fontSize: 11.sp,
                    color: AppColors.subtitles,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.close_rounded,
              size: 18.sp,
              color: AppColors.subtitles,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsletterIssueRow extends StatelessWidget {
  const _NewsletterIssueRow({required this.issue});

  final CommunityNewsletterIssue issue;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d, yyyy').format(issue.createdAt);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            issue.title,
            style: textStyle_16BoldBlack().copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Published $dateLabel${issue.authorName != null ? ' · ${issue.authorName}' : ''}',
            style: textStyle_12RegularGrey().copyWith(
              fontSize: 12.sp,
              color: AppColors.subtitles,
            ),
          ),
          if (issue.body.trim().isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              issue.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textStyle_14RegularGrey().copyWith(
                fontSize: 13.sp,
                color: AppColors.subtitles,
                height: 1.45,
              ),
            ),
          ],
          if (issue.attachmentUrl != null) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(
                  Icons.attach_file_rounded,
                  size: 14.sp,
                  color: AppColors.linkBlue,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Attachment available',
                  style: textStyle_12RegularGrey().copyWith(
                    fontSize: 12.sp,
                    color: AppColors.linkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
