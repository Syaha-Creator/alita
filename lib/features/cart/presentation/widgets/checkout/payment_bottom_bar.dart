import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/utils/format_helper.dart';
import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/cart_entity.dart';
import 'payment_method_model.dart';

/// Widget untuk menampilkan bottom bar pembayaran di checkout
/// Pure UI widget - semua logic di-handle oleh parent melalui callbacks
class PaymentBottomBar extends StatelessWidget {
  final List<CartEntity> selectedItems;
  final double grandTotal;
  final bool isDark;
  final List<PaymentMethod> paymentMethods;
  final String paymentType; // 'full' or 'partial' (DP)
  final VoidCallback onSubmitOrder;
  final VoidCallback onSaveDraft;
  final bool isIndirectCheckout;

  const PaymentBottomBar({
    super.key,
    required this.selectedItems,
    required this.grandTotal,
    required this.isDark,
    required this.paymentMethods,
    required this.paymentType,
    required this.onSubmitOrder,
    required this.onSaveDraft,
    this.isIndirectCheckout = false,
  });

  // Calculate payment completion status inside the widget
  bool _isPaymentComplete() {
    // For indirect checkout, payment is not required
    if (isIndirectCheckout) return true;
    
    if (paymentMethods.isEmpty) return false;

    // Calculate total paid from payment methods
    // Use integer arithmetic to avoid floating point precision issues
    // Rupiah doesn't have decimal places, so we can safely use integers
    final totalPaidInt = paymentMethods.fold<int>(
        0, (sum, payment) => sum + payment.amount.round());
    final grandTotalInt = grandTotal.round();

    // For 'full' payment type: must pay 100%
    // For 'partial' (DP) payment type: must pay at least 30%
    if (paymentType == 'full') {
      return totalPaidInt >= grandTotalInt;
    } else {
      // DP - minimal 30%
      final minimumDp = (grandTotalInt * 0.3).round();
      return totalPaidInt >= minimumDp;
    }
  }

  // Get minimum required payment amount
  int _getMinimumPayment() {
    final grandTotalInt = grandTotal.round();
    if (paymentType == 'full') {
      return grandTotalInt;
    } else {
      // DP - minimal 30%
      return (grandTotalInt * 0.3).round();
    }
  }

  // Get payment status text
  String _getPaymentStatusText() {
    if (paymentMethods.isEmpty) {
      if (paymentType == 'full') {
        return 'Belum ada pembayaran';
      } else {
        return 'DP min: ${FormatHelper.formatCurrency(_getMinimumPayment().toDouble())}';
      }
    }

    // Use integer arithmetic to avoid floating point precision issues
    final totalPaidInt = paymentMethods.fold<int>(
        0, (sum, payment) => sum + payment.amount.round());
    final grandTotalInt = grandTotal.round();
    final minimumPayment = _getMinimumPayment();

    if (paymentType == 'full') {
      if (totalPaidInt >= grandTotalInt) {
        return 'Pembayaran lengkap';
      } else {
        final remainingInt = grandTotalInt - totalPaidInt;
        return 'Sisa: ${FormatHelper.formatCurrency(remainingInt.toDouble())}';
      }
    } else {
      // DP mode
      if (totalPaidInt >= minimumPayment) {
        return 'DP tercukupi';
      } else {
        final remainingDp = minimumPayment - totalPaidInt;
        return 'Kurang DP: ${FormatHelper.formatCurrency(remainingDp.toDouble())}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get keyboard height to add padding
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            // Add keyboard height to bottom padding to prevent button from being hidden
            20 + keyboardHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Total Summary Card
              _buildTotalSummaryCard(context),
              const SizedBox(height: AppPadding.p16),
              // Action Buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.primaryDark.withValues(alpha: 0.2)
              : AppColors.primaryLight.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Pesanan',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: AppPadding.p2),
              Text(
                FormatHelper.formatCurrency(grandTotal),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryDark.withValues(alpha: 0.1)
                  : AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Draft Button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSaveDraft,
            icon: Icon(
              Icons.save_outlined,
              size: 16,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
            label: Text(
              'Simpan Draft',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  isDark ? AppColors.primaryDark : AppColors.primaryLight,
              side: BorderSide(
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: AppPadding.p12),
        // Main Action Button
        Builder(
          builder: (context) {
            final isComplete = _isPaymentComplete();
            final statusText = isIndirectCheckout 
                ? 'Siap Submit' 
                : _getPaymentStatusText();
            return Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isComplete ? onSubmitOrder : null,
                icon: Icon(
                  isComplete ? Icons.shopping_cart_checkout : Icons.lock,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  isComplete ? 'Buat Surat Pesanan' : statusText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isComplete
                      ? AppColors.success
                      : AppColors.disabledLight, // Status color
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.disabledLight, // Status color
                  disabledForegroundColor: Colors.white70,
                  elevation: isComplete ? 2 : 0,
                  shadowColor: isComplete
                      ? AppColors.success.withValues(alpha: 0.4)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
