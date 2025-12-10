import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/widgets/modern_text_field.dart';
import '../../../../../theme/app_colors.dart';

/// Widget untuk menampilkan section input nomor telepon
/// dengan opsi untuk menambah nomor telepon kedua
class PhoneNumberSection extends StatelessWidget {
  final TextEditingController primaryController;
  final TextEditingController secondaryController;
  final bool showSecondPhone;
  final bool isDark;
  final VoidCallback onToggleSecondPhone;
  final String? Function(String?, bool) phoneValidator;

  const PhoneNumberSection({
    super.key,
    required this.primaryController,
    required this.secondaryController,
    required this.showSecondPhone,
    required this.isDark,
    required this.onToggleSecondPhone,
    required this.phoneValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary phone number with add button
        Row(
          children: [
            Expanded(
              child: ModernTextField(
                controller: primaryController,
                label: 'Nomor Telepon',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (val) => phoneValidator(val, true),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppPadding.p12),
            _buildToggleButton(context),
          ],
        ),
        // Second phone number field (conditional)
        if (showSecondPhone) ...[
          const SizedBox(height: AppPadding.p12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: ModernTextField(
              controller: secondaryController,
              label: 'Nomor Telepon Kedua (Opsional)',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (val) => phoneValidator(val, false),
              isDark: isDark,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleButton(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: showSecondPhone
            ? Colors.red.withValues(alpha: 0.1)
            : (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: showSecondPhone
              ? Colors.red
              : (isDark ? AppColors.primaryDark : AppColors.primaryLight),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          showSecondPhone ? Icons.remove : Icons.add,
          color: showSecondPhone
              ? Colors.red
              : (isDark ? AppColors.primaryDark : AppColors.primaryLight),
          size: 20,
        ),
        onPressed: onToggleSecondPhone,
        tooltip: showSecondPhone
            ? 'Hapus nomor kedua'
            : 'Tambah nomor kedua',
      ),
    );
  }
}

