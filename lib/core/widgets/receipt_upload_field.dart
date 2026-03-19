import 'dart:io';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable receipt upload field for payment forms.
class ReceiptUploadField extends StatelessWidget {
  final File? imageFile;
  final bool hasError;
  final String? errorText;
  final VoidCallback onPickOrEdit;
  final VoidCallback onRemove;

  const ReceiptUploadField({
    super.key,
    required this.imageFile,
    required this.hasError,
    required this.errorText,
    required this.onPickOrEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        imageFile != null
            ? Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                      image: DecorationImage(
                        image: FileImage(imageFile!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _ActionCircleButton(
                          icon: Icons.edit,
                          iconColor: AppColors.accent,
                          onTap: onPickOrEdit,
                        ),
                        const SizedBox(width: 8),
                        _ActionCircleButton(
                          icon: Icons.delete,
                          iconColor: AppColors.error,
                          onTap: onRemove,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : InkWell(
                onTap: onPickOrEdit,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: hasError
                        ? AppColors.accentLight
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasError
                          ? AppColors.error
                          : AppColors.accent.withValues(alpha: 0.3),
                      width: hasError ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: hasError ? AppColors.error : AppColors.accent,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap untuk Upload Struk',
                        style: TextStyle(
                          color: hasError ? AppColors.error : AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        if (hasError && (errorText?.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCircleButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}
