import 'package:Readme/core/utils/draft_storage.dart';
import 'package:Readme/shared/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainActionScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainActionScreen({super.key, required this.navigationShell});

  @override
  State<MainActionScreen> createState() => _MainActionScreenState();
}

class _MainActionScreenState extends State<MainActionScreen> {
  /// Branch index for the drafts tab (the 5th `StatefulShellBranch` defined
  /// in `routes.dart`).
  static const int _draftsBranchIndex = 4;

  bool _hasDraft = false;

  @override
  void initState() {
    super.initState();
    _checkDraft();
  }

  @override
  void didUpdateWidget(covariant MainActionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-read draft state whenever the active branch changes (e.g. user
    // returns from drafts/editor) so the pencil indicator stays in sync.
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _checkDraft();
    }
  }

  Future<void> _checkDraft() async {
    final hasDraft = await DraftStorage.hasSavedDraft();
    if (mounted) setState(() => _hasDraft = hasDraft);
  }

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    return Scaffold(
      extendBody: true,
      body: widget.navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        hasDraft: _hasDraft,
        isDraftActive: currentIndex == _draftsBranchIndex,
        onTap: _goBranch,
        onCtaTap: () => _goBranch(_draftsBranchIndex),
      ),
    );
  }
}
