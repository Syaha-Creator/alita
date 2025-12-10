import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/widgets/modern_text_field.dart';
import '../../../../../theme/app_colors.dart';
import 'phone_number_section.dart';

/// Widget untuk menampilkan section informasi customer
/// Pure UI widget - menerima controllers dan callbacks dari parent
class CustomerInfoSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController spgCodeController;
  final TextEditingController phoneController;
  final TextEditingController phone2Controller;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final bool showSecondPhone;
  final bool isDark;
  final VoidCallback onToggleSecondPhone;
  final String? Function(String?, bool) phoneValidator;

  const CustomerInfoSection({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.spgCodeController,
    required this.phoneController,
    required this.phone2Controller,
    required this.emailController,
    required this.addressController,
    required this.showSecondPhone,
    required this.isDark,
    required this.onToggleSecondPhone,
    required this.phoneValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildForm(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            size: 20,
          ),
          const SizedBox(width: AppPadding.p8),
          Text(
            'Informasi Customer',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.surfaceLight : Colors.black,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            ModernTextField(
              controller: nameController,
              label: 'Nama Customer',
              icon: Icons.person,
              validator: (val) =>
                  val == null || val.isEmpty ? 'Nama customer wajib diisi' : null,
              isDark: isDark,
            ),
            const SizedBox(height: AppPadding.p16),
            ModernTextField(
              controller: spgCodeController,
              label: 'Kode SPG',
              icon: Icons.badge,
              isDark: isDark,
            ),
            const SizedBox(height: AppPadding.p16),
            PhoneNumberSection(
              primaryController: phoneController,
              secondaryController: phone2Controller,
              showSecondPhone: showSecondPhone,
              isDark: isDark,
              onToggleSecondPhone: onToggleSecondPhone,
              phoneValidator: phoneValidator,
            ),
            const SizedBox(height: AppPadding.p16),
            ModernTextField(
              controller: emailController,
              label: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Email wajib diisi';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                  return 'Format email tidak valid';
                }
                return null;
              },
              isDark: isDark,
            ),
            const SizedBox(height: AppPadding.p16),
            ModernTextField(
              controller: addressController,
              label: 'Alamat Customer',
              icon: Icons.location_on,
              maxLines: 3,
              validator: (val) => val == null || val.isEmpty
                  ? 'Alamat customer wajib diisi'
                  : null,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

