import 'package:flutter/material.dart';
import '../../../../config/app_constant.dart';

import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/modern_text_field.dart';
import '../widgets/checkout_dialog/checkout_dialog_widgets.dart';

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
            CheckoutDialogHeader(
              title: 'Informasi Customer',
              subtitle: 'Lengkapi data diri Anda',
              icon: Icons.person_outline,
              onClose: () => Navigator.pop(context),
            ),

            // Content with Action Button inside scroll
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Dismiss keyboard when tapping outside input fields
                  FocusScope.of(context).unfocus();
                },
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.of(context).viewInsets.bottom +
                        safePadding.bottom +
                        20,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Type Selection
                        Text(
                          'Tipe Customer',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppPadding.p16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomerTypeOption(
                                title: 'Customer Baru',
                                isSelected: !_isExistingCustomer,
                                onTap: () =>
                                    setState(() => _isExistingCustomer = false),
                              ),
                            ),
                            const SizedBox(width: AppPadding.p12),
                            Expanded(
                              child: CustomerTypeOption(
                                title: 'Customer Existing',
                                isSelected: _isExistingCustomer,
                                onTap: () =>
                                    setState(() => _isExistingCustomer = true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppPadding.p20),

                        // Form Fields
                        ModernTextField(
                          controller: _nameController,
                          label: 'Nama Lengkap',
                          icon: Icons.person,
                          isDark:
                              Theme.of(context).brightness == Brightness.dark,
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Nama wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: AppPadding.p12),
                        ModernTextField(
                          controller: _phoneController,
                          label: 'Nomor Telepon',
                          icon: Icons.phone,
                          isDark:
                              Theme.of(context).brightness == Brightness.dark,
                          keyboardType: TextInputType.phone,
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Nomor telepon wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: AppPadding.p12),
                        ModernTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email,
                          isDark:
                              Theme.of(context).brightness == Brightness.dark,
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
                        ),
                        const SizedBox(height: AppPadding.p12),

                        // Delivery Options
                        Text(
                          'Metode Pengiriman',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppPadding.p8),
                        Row(
                          children: [
                            Expanded(
                              child: DeliveryOption(
                                title: 'Pengiriman',
                                subtitle: 'Dikirim ke alamat',
                                icon: Icons.local_shipping_outlined,
                                isSelected: !_isTakeAway,
                                onTap: () =>
                                    setState(() => _isTakeAway = false),
                              ),
                            ),
                            const SizedBox(width: AppPadding.p12),
                            Expanded(
                              child: DeliveryOption(
                                title: 'Bawa Langsung',
                                subtitle: 'Ambil di toko',
                                icon: Icons.storefront_outlined,
                                isSelected: _isTakeAway,
                                onTap: () => setState(() => _isTakeAway = true),
                              ),
                            ),
                          ],
                        ),

                        // Action Button moved inside scroll
                        const SizedBox(height: AppPadding.p20),
                        _buildInlineActionButton(context, colorScheme),
                      ],
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

  Widget _buildInlineActionButton(
      BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: ResponsiveHelper.getResponsivePaddingWithZoom(
            context,
            mobile: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            tablet: const EdgeInsets.symmetric(vertical: 20, horizontal: 28),
            desktop: const EdgeInsets.symmetric(vertical: 22, horizontal: 32),
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
          style: TextStyle(
            fontFamily: 'Inter',
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
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Location validation disabled - proceed directly
      if (!mounted) return;
      if (!context.mounted) return;

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
  }
}
