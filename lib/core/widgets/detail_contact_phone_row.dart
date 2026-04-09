import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_layout_tokens.dart';
import '../utils/platform_utils.dart';

/// Satu atau beberapa nomor HP; tiap baris memakai [_CompactContactPhoneRow] (ikon-only, DRY).
class DetailContactPhoneRow extends StatelessWidget {
  const DetailContactPhoneRow({
    super.key,
    required this.phones,
    this.onCopyPhone,
    this.onCallPhone,
    this.onOpenWhatsApp,
  });

  final List<String> phones;
  final void Function(String phone)? onCopyPhone;
  final void Function(String phone)? onCallPhone;
  final void Function(String phone)? onOpenWhatsApp;

  static List<String> _normalize(List<String> raw) {
    final out = <String>[];
    for (final s in raw) {
      final t = s.trim();
      if (t.isEmpty || t == '-') continue;
      if (!out.contains(t)) out.add(t);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final list = _normalize(phones);
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppLayoutTokens.space4),
        for (var i = 0; i < list.length; i++) ...[
          if (i > 0) const SizedBox(height: AppLayoutTokens.space4),
          _CompactContactPhoneRow(
            phone: list[i],
            onCopyPhone:
                onCopyPhone == null ? null : () => onCopyPhone!(list[i]),
            onCallPhone:
                onCallPhone == null ? null : () => onCallPhone!(list[i]),
            onOpenWhatsApp: onOpenWhatsApp == null
                ? null
                : () => onOpenWhatsApp!(list[i]),
          ),
        ],
      ],
    );
  }
}

/// Baris ringkas: [ikon kontak] [nomor] [ikon salin] [ikon telepon] [ikon WA] — tanpa kotak latar.
class _CompactContactPhoneRow extends StatelessWidget {
  const _CompactContactPhoneRow({
    required this.phone,
    this.onCopyPhone,
    this.onCallPhone,
    this.onOpenWhatsApp,
  });

  final String phone;
  final VoidCallback? onCopyPhone;
  final VoidCallback? onCallPhone;
  final VoidCallback? onOpenWhatsApp;

  static const double _leadingIconSize = 14;
  static const double _actionIconSize = 17;

  static Color get _copyIconColor =>
      AppColors.textSecondary.withValues(alpha: 0.6);
  static Color get _callIconColor =>
      AppColors.accent.withValues(alpha: 0.6);
  static const double _waIconOpacity = 0.6;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Nomor telepon $phone',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.phone_android_outlined,
            size: _leadingIconSize,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppLayoutTokens.space6),
          Expanded(
            child: Text(
              phone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.15,
              ),
            ),
          ),
          _CompactPhoneIconActions(
            onCopyPhone: onCopyPhone,
            onCallPhone: onCallPhone,
            onOpenWhatsApp: onOpenWhatsApp,
            copyIconColor: _copyIconColor,
            callIconColor: _callIconColor,
            waIconOpacity: _waIconOpacity,
            iconSize: _actionIconSize,
          ),
        ],
      ),
    );
  }
}

class _CompactPhoneIconActions extends StatelessWidget {
  const _CompactPhoneIconActions({
    required this.copyIconColor,
    required this.callIconColor,
    required this.waIconOpacity,
    required this.iconSize,
    this.onCopyPhone,
    this.onCallPhone,
    this.onOpenWhatsApp,
  });

  final Color copyIconColor;
  final Color callIconColor;
  final double waIconOpacity;
  final double iconSize;
  final VoidCallback? onCopyPhone;
  final VoidCallback? onCallPhone;
  final VoidCallback? onOpenWhatsApp;

  static const BoxConstraints _tap = BoxConstraints(
    minWidth: 30,
    minHeight: 30,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onCopyPhone != null)
          _iconOnly(
            context: context,
            tooltip: 'Salin nomor',
            semanticLabel: 'Salin',
            onPressed: onCopyPhone!,
            icon: Icon(
              Icons.copy_rounded,
              size: iconSize,
              color: copyIconColor,
            ),
          ),
        if (onCopyPhone != null && onCallPhone != null)
          const SizedBox(width: AppLayoutTokens.space4),
        if (onCallPhone != null)
          _iconOnly(
            context: context,
            tooltip: 'Telepon',
            semanticLabel: 'Telepon',
            onPressed: onCallPhone!,
            icon: Icon(
              Icons.call_rounded,
              size: iconSize,
              color: callIconColor,
            ),
          ),
        if ((onCopyPhone != null || onCallPhone != null) &&
            onOpenWhatsApp != null)
          const SizedBox(width: AppLayoutTokens.space4),
        if (onOpenWhatsApp != null)
          _iconOnly(
            context: context,
            tooltip: 'Chat WhatsApp',
            semanticLabel: 'WhatsApp',
            onPressed: onOpenWhatsApp!,
            icon: Opacity(
              opacity: waIconOpacity,
              child: Image.asset(
                'assets/logo/whatsapp-icon.png',
                width: iconSize,
                height: iconSize,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
      ],
    );
  }

  Widget _iconOnly({
    required BuildContext context,
    required String tooltip,
    required String semanticLabel,
    required VoidCallback onPressed,
    required Widget icon,
  }) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: semanticLabel,
        button: true,
        child: IconButton(
          onPressed: () {
            hapticTap();
            onPressed();
          },
          padding: EdgeInsets.zero,
          constraints: _tap,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          icon: icon,
        ),
      ),
    );
  }
}
