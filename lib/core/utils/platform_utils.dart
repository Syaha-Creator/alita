import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Platform Detection ─────────────────────────────────────────────────────

bool get isIOS => Platform.isIOS;

// ─── Haptic Feedback ────────────────────────────────────────────────────────

/// Light haptic tap for primary action buttons.
void hapticTap() => HapticFeedback.lightImpact();

/// Medium haptic for confirmations (approve, checkout).
void hapticConfirm() => HapticFeedback.mediumImpact();

/// Heavy haptic for destructive actions (reject, delete).
void hapticDestructive() => HapticFeedback.heavyImpact();

// ─── Adaptive Alert Dialog ──────────────────────────────────────────────────

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
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions
            .map((a) => CupertinoDialogAction(
                  isDestructiveAction: a.isDestructive,
                  isDefaultAction: a.isDefault,
                  onPressed: () {
                    a.onPressed?.call();
                    if (a.popResult != null) {
                      Navigator.of(context).pop(a.popResult);
                    }
                  },
                  child: Text(a.label),
                ))
            .toList(),
      ),
    );
  }

  return showDialog<T>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(content),
      actions: actions.map((a) {
        if (a.isDestructive) {
          return TextButton(
            onPressed: () {
              a.onPressed?.call();
              if (a.popResult != null) {
                Navigator.of(context).pop(a.popResult);
              }
            },
            child: Text(
              a.label,
              style: TextStyle(
                color: a.color ?? Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        return TextButton(
          onPressed: () {
            a.onPressed?.call();
            if (a.popResult != null) {
              Navigator.of(context).pop(a.popResult);
            }
          },
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

class AdaptiveAction {
  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isDefault;
  final Color? color;

  /// If non-null, pops the dialog with this value after [onPressed].
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
