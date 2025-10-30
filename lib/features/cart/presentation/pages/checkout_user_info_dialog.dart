import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../services/attendance_service.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_state.dart';
import '../../../product/presentation/bloc/product_bloc.dart';

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
  bool _isValidatingLocation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Validate user location before allowing checkout
  Future<bool> _validateLocation(BuildContext context) async {
    try {
      // Get AttendanceService and validate checkout location
      final attendanceService = locator<AttendanceService>();
      final validationResult =
          await attendanceService.validateCheckoutLocation();

      if (validationResult['isValid'] == true) {
        // Location is valid, now validate prices
        await _revalidateCartPrices(context);

        // Allow checkout directly without dialog
        return true;
      } else {
        // Location is not valid, show error message
        final message =
            validationResult['message'] as String? ?? 'Lokasi tidak valid';

        _showLocationErrorDialog(
          context,
          'Lokasi tidak valid',
          message,
        );
        return false;
      }
    } catch (e) {
      _showLocationErrorDialog(
        context,
        'Error validasi lokasi',
        'Terjadi kesalahan saat memvalidasi lokasi: $e',
      );
      return false;
    }
  }

  /// Revalidate cart prices with latest from API
  Future<void> _revalidateCartPrices(BuildContext context) async {
    final cartBloc = context.read<CartBloc>();
    final productBloc = context.read<ProductBloc>();

    if (cartBloc.state is! CartLoaded) return;

    final cartState = cartBloc.state as CartLoaded;
    final productState = productBloc.state;

    // For each cart item, check if prices match latest from ProductBloc
    for (final cartItem in cartState.cartItems) {
      // Find matching product in ProductBloc state
      final matchingProduct = productState.products.firstWhere(
        (p) =>
            p.id == cartItem.product.id &&
            p.kasur == cartItem.product.kasur &&
            p.divan == cartItem.product.divan &&
            p.headboard == cartItem.product.headboard &&
            p.sorong == cartItem.product.sorong &&
            p.ukuran == cartItem.product.ukuran &&
            p.brand == cartItem.product.brand &&
            p.area == cartItem.product.area &&
            p.channel == cartItem.product.channel,
        orElse: () => cartItem.product,
      );

      // If prices differ, show notification (but don't block checkout yet)
      if (matchingProduct.endUserPrice != cartItem.product.endUserPrice) {
        CustomToast.showToast(
          "Harga produk ${cartItem.product.kasur} telah diperbarui. Harga Anda: ${cartItem.netPrice.toStringAsFixed(0)}, Harga terbaru: ${matchingProduct.endUserPrice.toStringAsFixed(0)}",
          ToastType.warning,
          duration: 4,
        );
      }
    }
  }

  /// Show location error dialog
  void _showLocationErrorDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
                          style: TextStyle(
                            fontFamily: 'Inter',
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
                          style: TextStyle(
                            fontFamily: 'Inter',
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
                        style: TextStyle(
                          fontFamily: 'Inter',
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
                        style: TextStyle(
                          fontFamily: 'Inter',
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
                  onPressed: _isValidatingLocation
                      ? null
                      : () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            setState(() {
                              _isValidatingLocation = true;
                            });

                            try {
                              // Validate location before proceeding
                              final locationValid =
                                  await _validateLocation(context);
                              if (locationValid) {
                                if (mounted) {
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
                              // If location not valid, stay in dialog
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isValidatingLocation = false;
                                });
                              }
                            }
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
                  child: _isValidatingLocation
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Memvalidasi lokasi...',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize:
                                    ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 17,
                                  desktop: 18,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
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
      style: TextStyle(
        fontFamily: 'Inter',
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
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: TextStyle(
          fontFamily: 'Inter',
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
          style: TextStyle(
            fontFamily: 'Inter',
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
              style: TextStyle(
                fontFamily: 'Inter',
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
              style: TextStyle(
                fontFamily: 'Inter',
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
