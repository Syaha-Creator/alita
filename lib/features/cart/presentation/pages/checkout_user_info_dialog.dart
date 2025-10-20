import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_colors.dart';

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
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final safeAreaTop = mediaQuery.padding.top;
    final safeAreaBottom = mediaQuery.padding.bottom;
    final availableHeight = screenHeight -
        keyboardHeight -
        safeAreaTop -
        60; // 60 untuk navigation bar dan margin

    return Material(
      color: Colors.transparent,
      child: Container(
        height: availableHeight > 650 ? 650 : availableHeight,
        margin: EdgeInsets.only(
          top: safeAreaTop + 20, // Memberikan jarak dari status bar
          bottom: 0, // Tidak ada margin bottom
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
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
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
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
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Customer',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lengkapi data diri Anda',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                        color: isDark ? Colors.grey[700] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : Colors.black,
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Type Selection
                      Text(
                        'Tipe Customer',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
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
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCustomerTypeOption(
                              title: 'Customer Existing',
                              isSelected: _isExistingCustomer,
                              onTap: () =>
                                  setState(() => _isExistingCustomer = true),
                              isDark: isDark,
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
                        isDark: isDark,
                      ),
                      const SizedBox(height: 18),
                      _buildModernTextField(
                        controller: _phoneController,
                        label: 'Nomor Telepon',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Nomor telepon wajib diisi'
                            : null,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 18),
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
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),

                      // Delivery Options
                      Text(
                        'Metode Pengiriman',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDeliveryOption(
                              title: 'Pengiriman',
                              subtitle: 'Dikirim ke alamat',
                              icon: Icons.local_shipping_outlined,
                              isSelected: !_isTakeAway,
                              onTap: () => setState(() => _isTakeAway = false),
                              isDark: isDark,
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
                              isDark: isDark,
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                    backgroundColor:
                        isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: Text(
                    'Lanjutkan',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
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
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.montserrat(
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            icon,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            size: 22,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: GoogleFonts.montserrat(
          fontSize: 14,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: GoogleFonts.montserrat(
          color: Colors.red,
          fontSize: 12,
        ),
        filled: true,
        fillColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
      ),
    );
  }

  Widget _buildCustomerTypeOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? isDark
                  ? AppColors.primaryDark
                  : AppColors.primaryLight.withOpacity(0.1)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          border: Border.all(
            color: isSelected
                ? isDark
                    ? AppColors.primaryDark
                    : AppColors.primaryLight
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? isDark
                    ? AppColors.primaryDark
                    : AppColors.primaryLight
                : (isDark ? Colors.white : Colors.black),
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
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? isDark
                  ? AppColors.primaryDark
                  : AppColors.primaryLight.withOpacity(0.1)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          border: Border.all(
            color: isSelected
                ? isDark
                    ? AppColors.primaryDark
                    : AppColors.primaryLight
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
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
                  ? isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight
                    : (isDark ? Colors.white : Colors.black),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: isSelected
                    ? isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight.withOpacity(0.8)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
