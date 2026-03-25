import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

// ─── Platform Detection ─────────────────────────────────────────────────────

bool get isIOS => Platform.isIOS;

// ─── Haptic Feedback ────────────────────────────────────────────────────────
// Wrapped in try/catch — MIUI/Xiaomi devices may lack VIBRATE permission.

/// Light haptic tap for primary action buttons.
void hapticTap() {
  try { HapticFeedback.lightImpact(); } on PlatformException catch (_) {}
}

/// Medium haptic for confirmations (approve, checkout).
void hapticConfirm() {
  try { HapticFeedback.mediumImpact(); } on PlatformException catch (_) {}
}

/// Heavy haptic for destructive actions (reject, delete).
void hapticDestructive() {
  try { HapticFeedback.heavyImpact(); } on PlatformException catch (_) {}
}

/// Selection tick for toggles, chips, pickers.
void hapticSelection() {
  try { HapticFeedback.selectionClick(); } on PlatformException catch (_) {}
}

// ─── Adaptive Alert Dialog ──────────────────────────────────────────────────

/// Pops the dialog route first, then runs [action.onPressed] on the next frame
/// when [AdaptiveAction.popResult] is set. Avoids races where callbacks call
/// `logout()` / `Navigator.pop(parentContext)` and tear down the tree while the
/// dialog route is still handling the tap (seen as null `State` / `Navigator.of`
/// crashes on newer Android).
void _adaptiveAlertActionPressed(
  BuildContext dialogContext,
  AdaptiveAction action,
) {
  final callback = action.onPressed;

  if (action.popResult != null) {
    if (dialogContext.mounted) {
      Navigator.maybeOf(dialogContext)?.pop(action.popResult);
    }
    if (callback != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => callback());
    }
  } else {
    callback?.call();
    if (dialogContext.mounted) {
      final nav = Navigator.maybeOf(dialogContext);
      if (nav != null && nav.canPop()) {
        nav.pop();
      }
    }
  }
}

/// Shows [CupertinoAlertDialog] on iOS, [AlertDialog] on Android.
///
/// [actions] maps label → callback. The last action is treated as the
/// primary/destructive button on Cupertino.
Future<T?> showAdaptiveAlert<T>({
  required BuildContext context,
  required String title,
  required String content,
  required List<AdaptiveAction> actions,
}) {
  if (isIOS) {
    return showCupertinoDialog<T>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions
            .map((a) => CupertinoDialogAction(
                  isDestructiveAction: a.isDestructive,
                  isDefaultAction: a.isDefault,
                  onPressed: () =>
                      _adaptiveAlertActionPressed(dialogContext, a),
                  child: Text(a.label),
                ))
            .toList(),
      ),
    );
  }

  return showDialog<T>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: actions.map((a) {
        if (a.isDestructive) {
          return TextButton(
            onPressed: () =>
                _adaptiveAlertActionPressed(dialogContext, a),
            child: Text(
              a.label,
              style: TextStyle(
                color: a.color ?? AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        return TextButton(
          onPressed: () =>
              _adaptiveAlertActionPressed(dialogContext, a),
          child: Text(a.label, style: TextStyle(color: a.color)),
        );
      }).toList(),
    ),
  );
}

/// Confirmation dialog with "Batal" / primary action.
/// Returns `true` when confirmed, `null` / `false` otherwise.
Future<bool?> showAdaptiveConfirm({
  required BuildContext context,
  required String title,
  required String content,
  String cancelLabel = 'Batal',
  required String confirmLabel,
  bool isDestructive = false,
  Color? confirmColor,
}) {
  return showAdaptiveAlert<bool>(
    context: context,
    title: title,
    content: content,
    actions: [
      AdaptiveAction(label: cancelLabel, popResult: false),
      AdaptiveAction(
        label: confirmLabel,
        isDestructive: isDestructive,
        isDefault: !isDestructive,
        color: confirmColor,
        popResult: true,
      ),
    ],
  );
}

// ─── Adaptive Date Picker ────────────────────────────────────────────────

/// Shows a [CupertinoDatePicker] on iOS (modal bottom sheet),
/// and [showDatePicker] on Android (Material dialog).
///
/// Returns the selected [DateTime] or `null` if cancelled.
Future<DateTime?> showAdaptiveDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) async {
  if (isIOS) {
    DateTime tempDate = initialDate;
    final result = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (popupContext) => Container(
        height: 280,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    onPressed: () {
                      if (popupContext.mounted) Navigator.pop(popupContext);
                    },
                  ),
                  if (helpText != null)
                    Flexible(
                      child: Text(
                        helpText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          decoration: TextDecoration.none,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  CupertinoButton(
                    child: const Text(
                      'Pilih',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      if (popupContext.mounted) Navigator.pop(popupContext, tempDate);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: firstDate,
                maximumDate: lastDate,
                onDateTimeChanged: (d) => tempDate = d,
              ),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
  );
}

// ─── Adaptive Action Data ────────────────────────────────────────────────

class AdaptiveAction {
  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isDefault;
  final Color? color;

  /// If non-null, pops the dialog with this value first; [onPressed] runs on
  /// the **next frame** after pop (safe for logout / navigation side effects).
  final dynamic popResult;

  const AdaptiveAction({
    required this.label,
    this.onPressed,
    this.isDestructive = false,
    this.isDefault = false,
    this.color,
    this.popResult,
  });
}
