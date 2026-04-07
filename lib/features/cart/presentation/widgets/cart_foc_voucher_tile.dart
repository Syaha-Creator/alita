import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/platform_utils.dart';

/// Baris tipis voucher FOC di **bawah** isi utama kartu keranjang (bukan di kolom tengah).
/// Hanya label + switch — hemat vertikal, switch tidak ikut area tap buka detail.
class CartFocVoucherBar extends StatelessWidget {
  const CartFocVoucherBar({
    super.key,
    required this.active,
    required this.onChanged,
  });

  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Voucher FOC 100 persen',
      toggled: active,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accentLight.withValues(alpha: 0.35),
          border: const Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayoutTokens.space12,
            vertical: AppLayoutTokens.space6,
          ),
          child: Row(
            children: [
              Icon(
                Icons.redeem_outlined,
                size: 18,
                color: active ? AppColors.accent : AppColors.textTertiary,
              ),
              const SizedBox(width: AppLayoutTokens.space8),
              Expanded(
                child: Text(
                  'FOC 100%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    color: active ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.88,
                alignment: Alignment.centerRight,
                child: Switch.adaptive(
                  value: active,
                  activeTrackColor: AppColors.accent.withValues(alpha: 0.45),
                  activeThumbColor: AppColors.onPrimary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) {
                    hapticSelection();
                    onChanged(v);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
