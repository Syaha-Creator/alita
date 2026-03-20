import 'package:flutter/material.dart';

import 'app_feedback.dart';

/// Returns `true` when action should be blocked due to offline mode.
///
/// Use this helper before actions that require internet (upload/share/fetch).
bool ifOfflineShowFeedback(
  BuildContext context, {
  required bool isOffline,
  String message = 'Fungsi ini membutuhkan internet',
}) {
  if (!isOffline) return false;
  AppFeedback.show(
    context,
    message: message,
    type: AppFeedbackType.warning,
    floating: true,
  );
  return true;
}
