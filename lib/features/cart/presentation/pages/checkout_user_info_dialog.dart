import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/responsive_helper.dart';

class CheckoutDialogResult {
  final String name;
  final String phone;
  final String email;
  final bool isTakeAway;
  final bool isExistingCustomer;

  CheckoutDialogResult({
    required this.name,
    required this.phone,
    required this.email,
    required this.isTakeAway,
    required this.isExistingCustomer,
  });
}

class CheckoutUserInfoDialog extends StatefulWidget {
  const CheckoutUserInfoDialog({super.key});

  @override
  State<CheckoutUserInfoDialog> createState() => _CheckoutUserInfoDialogState();

  // Static method to show the bottom sheet
  static Future<CheckoutDialogResult?> show(BuildContext context) {
    return showModalBottomSheet<CheckoutDialogResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CheckoutUserInfoDialog(),
    );
  }
}

class _CheckoutUserInfoDialogState extends State<CheckoutUserInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isTakeAway = false;
  bool _isExistingCustomer = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final availableHeight = ResponsiveHelper.getSafeModalHeight(context);
    final safePadding = ResponsiveHelper.getSafeAreaPadding(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        height: availableHeight,
        margin: EdgeInsets.only(
          top: safePadding.top +
              ResponsiveHelper.getResponsiveSpacingWithZoom(
                context,
                mobile: 20,
                tablet: 24,
                desktop: 28,
              ),
          bottom: 0,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: ResponsiveHelper.getResponsivePaddingWithZoom(
                context,
                mobile: const EdgeInsets.all(20),
                tablet: const EdgeInsets.all(24),
                desktop: const EdgeInsets.all(28),
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: colorScheme.onPrimary,
                      size: ResponsiveHelper.getResponsiveIconSize(
                        context,
                        mobile: 20,
                        tablet: 22,
                        desktop: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Customer',
                          style: GoogleFonts.inter(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 18,
                              tablet: 20,
                              desktop: 22,
                            ),
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lengkapi data diri Anda',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.close,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Type Selection
                      Text(
                        'Tipe Customer',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCustomerTypeOption(
                              title: 'Customer Baru',
                              isSelected: !_isExistingCustomer,
                              onTap: () =>
                                  setState(() => _isExistingCustomer = false),
                              colorScheme: colorScheme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCustomerTypeOption(
                              title: 'Customer Existing',
                              isSelected: _isExistingCustomer,
                              onTap: () =>
                                  setState(() => _isExistingCustomer = true),
                              colorScheme: colorScheme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Form Fields
                      _buildModernTextField(
                        controller: _nameController,
                        label: 'Nama Lengkap',
                        icon: Icons.person,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Nama wajib diisi'
                            : null,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 12),
                      _buildModernTextField(
                        controller: _phoneController,
                        label: 'Nomor Telepon',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Nomor telepon wajib diisi'
                            : null,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 12),
                      _buildModernTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Email wajib diisi';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(val)) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 12),

                      // Delivery Options
                      Text(
                        'Metode Pengiriman',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDeliveryOption(
                              title: 'Pengiriman',
                              subtitle: 'Dikirim ke alamat',
                              icon: Icons.local_shipping_outlined,
                              isSelected: !_isTakeAway,
                              onTap: () => setState(() => _isTakeAway = false),
                              colorScheme: colorScheme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDeliveryOption(
                              title: 'Bawa Langsung',
                              subtitle: 'Ambil di toko',
                              icon: Icons.storefront_outlined,
                              isSelected: _isTakeAway,
                              onTap: () => setState(() => _isTakeAway = true),
                              colorScheme: colorScheme,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Button - Fixed at bottom
            Padding(
              padding: ResponsiveHelper.getResponsivePaddingWithZoom(
                context,
                mobile: EdgeInsets.fromLTRB(20, 4, 20, safePadding.bottom + 20),
                tablet: EdgeInsets.fromLTRB(24, 6, 24, safePadding.bottom + 24),
                desktop:
                    EdgeInsets.fromLTRB(28, 8, 28, safePadding.bottom + 28),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      Navigator.pop(
                        context,
                        CheckoutDialogResult(
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          email: _emailController.text.trim(),
                          isTakeAway: _isTakeAway,
                          isExistingCustomer: _isExistingCustomer,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: ResponsiveHelper.getResponsivePaddingWithZoom(
                      context,
                      mobile: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 24),
                      tablet: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 28),
                      desktop: const EdgeInsets.symmetric(
                          vertical: 22, horizontal: 32),
                    ),
                    elevation: 0,
                    minimumSize: Size(
                      double.infinity,
                      ResponsiveHelper.getResponsiveButtonHeight(
                        context,
                        mobile: 56,
                        tablet: 60,
                        desktop: 64,
                      ),
                    ),
                  ),
                  child: Text(
                    'Lanjutkan',
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 17,
                        desktop: 18,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ColorScheme colorScheme,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 22,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: GoogleFonts.inter(
          color: colorScheme.error,
          fontSize: 12,
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant,
      ),
    );
  }

  Widget _buildCustomerTypeOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceVariant,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDeliveryOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceVariant,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isSelected
                    ? colorScheme.onPrimaryContainer.withOpacity(0.8)
                    : colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
