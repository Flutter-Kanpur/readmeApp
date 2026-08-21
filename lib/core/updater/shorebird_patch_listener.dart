import 'package:Readme/core/config/readme_host.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Notifies users when a Shorebird patch is ready and logs patch info in debug.
///
/// With `auto_update: true` in [shorebird.yaml], patches download on launch.
/// This widget surfaces `restartRequired` so users know to reopen the app.
class ShorebirdPatchListener extends StatefulWidget {
  const ShorebirdPatchListener({super.key, required this.child});

  final Widget child;

  @override
  State<ShorebirdPatchListener> createState() => _ShorebirdPatchListenerState();
}

class _ShorebirdPatchListenerState extends State<ShorebirdPatchListener> {
  final ShorebirdUpdater _updater = ShorebirdUpdater();
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    if (!ReadmeHost.isEmbedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkPatchStatus());
    }
  }

  Future<void> _checkPatchStatus() async {
    if (_checked || !mounted) return;
    _checked = true;

    if (!_updater.isAvailable) {
      if (kDebugMode) {
        debugPrint(
          'Shorebird: updater unavailable (use shorebird release / preview)',
        );
      }
      return;
    }

    try {
      final patch = await _updater.readCurrentPatch();
      if (kDebugMode && patch != null) {
        debugPrint('Shorebird: running patch #${patch.number}');
      }

      final status = await _updater.checkForUpdate();
      if (!mounted) return;

      switch (status) {
        case UpdateStatus.restartRequired:
          _showRestartSnackBar();
        case UpdateStatus.outdated:
          _showRestartSnackBar(
            message: 'An update is downloading. Reopen ReadMe to apply it.',
          );
        case UpdateStatus.upToDate:
        case UpdateStatus.unavailable:
          return;
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Shorebird patch check failed: $error');
        debugPrint('$stackTrace');
      }
    }
  }

  void _showRestartSnackBar({
    String message = 'Update ready. Close and reopen ReadMe to apply it.',
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
