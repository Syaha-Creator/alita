import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Enum untuk jenis confirmation dialog
enum ConfirmationType {
  delete,
  warning,
  info,
  success,
  custom,
}

/// Widget dialog konfirmasi yang reusable.
/// Digunakan untuk konfirmasi delete, warning, dll.
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final ConfirmationType type;
  final Color? confirmColor;
  final IconData? icon;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Konfirmasi',
    this.cancelText = 'Batal',
    this.type = ConfirmationType.warning,
    this.confirmColor,
    this.icon,
    this.onConfirm,
    this.onCancel,
  });

  /// Factory untuk delete confirmation
  factory ConfirmationDialog.delete({
    String title = 'Hapus Item',
    required String message,
    String confirmText = 'Hapus',
    String cancelText = 'Batal',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return ConfirmationDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      type: ConfirmationType.delete,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  Color _getColor() {
    if (confirmColor != null) return confirmColor!;
    
    switch (type) {
      case ConfirmationType.delete:
        return AppColors.error;
      case ConfirmationType.warning:
        return AppColors.warning;
      case ConfirmationType.info:
        return AppColors.info;
      case ConfirmationType.success:
        return AppColors.success;
      case ConfirmationType.custom:
        return AppColors.info;
    }
  }

  IconData _getIcon() {
    if (icon != null) return icon!;
    
    switch (type) {
      case ConfirmationType.delete:
        return Icons.delete_outline;
      case ConfirmationType.warning:
        return Icons.warning_amber_rounded;
      case ConfirmationType.info:
        return Icons.info_outline;
      case ConfirmationType.success:
        return Icons.check_circle_outline;
      case ConfirmationType.custom:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _getColor();

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getIcon(), color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark 
                    ? AppColors.textPrimaryDark 
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isDark 
              ? AppColors.textSecondaryDark 
              : AppColors.textSecondaryLight,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: Text(
            cancelText,
            style: TextStyle(
              fontFamily: 'Inter',
              color: isDark 
                  ? AppColors.textSecondaryDark 
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Static method untuk menampilkan dialog dan mendapatkan hasil
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Konfirmasi',
    String cancelText = 'Batal',
    ConfirmationType type = ConfirmationType.warning,
    Color? confirmColor,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        type: type,
        confirmColor: confirmColor,
        icon: icon,
      ),
    );
  }

  /// Static method untuk menampilkan delete confirmation
  static Future<bool?> showDelete({
    required BuildContext context,
    String title = 'Hapus Item',
    required String message,
    String confirmText = 'Hapus',
    String cancelText = 'Batal',
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      type: ConfirmationType.delete,
    );
  }
}

