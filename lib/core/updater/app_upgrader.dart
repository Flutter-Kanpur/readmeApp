import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

/// Wraps the app with a Play Store / App Store update prompt.
class AppUpgrader extends StatelessWidget {
  const AppUpgrader({super.key, required this.child});

  final Widget child;

  static final Upgrader _upgrader = Upgrader(
    durationUntilAlertAgain: const Duration(days: 1),
    messages: ReadmeUpgraderMessages(),
  );

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: _upgrader,
      showReleaseNotes: true,
      barrierDismissible: false,
      dialogStyle: UpgradeDialogStyle.material,
      child: child,
    );
  }
}

class ReadmeUpgraderMessages extends UpgraderMessages {
  ReadmeUpgraderMessages({super.code = 'en'});

  @override
  String get title => 'Update Available';

  @override
  String get body =>
      'A new version of Readme is available. Update now for the latest '
      'features and improvements.';

  @override
  String get buttonTitleUpdate => 'Update Now';

  @override
  String get buttonTitleLater => 'Later';

  @override
  String get buttonTitleIgnore => 'Skip';
}
