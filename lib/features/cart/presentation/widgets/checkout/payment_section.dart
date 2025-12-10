import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/cart_entity.dart';
import 'payment_method_card.dart';
import 'payment_method_model.dart';
import 'payment_summary.dart';
import 'payment_type_option.dart';

/// Widget untuk menampilkan section pembayaran
/// Mengelola tipe pembayaran dan daftar metode pembayaran
class PaymentSection extends StatelessWidget {
  final List<CartEntity> selectedItems;
  final double grandTotal;
  final bool isDark;
  final String paymentType;
  final List<PaymentMethod> paymentMethods;
  final double totalPaid;
  final ValueChanged<String> onPaymentTypeChanged;
  final VoidCallback onAddPaymentMethod;
  final void Function(String imagePath) onViewReceipt;
  final void Function(int index) onRemovePayment;

  const PaymentSection({
    super.key,
    required this.selectedItems,
    required this.grandTotal,
    required this.isDark,
    required this.paymentType,
    required this.paymentMethods,
    required this.totalPaid,
    required this.onPaymentTypeChanged,
    required this.onAddPaymentMethod,
    required this.onViewReceipt,
    required this.onRemovePayment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.shadowDark.withValues(alpha: 0.3)
                : AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildContent(context),
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
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.payment_outlined,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            size: 20,
          ),
          const SizedBox(width: AppPadding.p8),
          Text(
            'Informasi Pembayaran',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPaymentTypeSelector(context),
          SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),
          _buildPaymentMethodsHeader(context),
          const SizedBox(height: AppPadding.p12),
          _buildPaymentMethodsList(context),
          const SizedBox(height: AppPadding.p16),
          if (paymentMethods.isNotEmpty) _buildPaymentSummary(),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipe Pembayaran',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.surfaceLight : Colors.black,
              ),
        ),
        SizedBox(
          height: ResponsiveHelper.getResponsiveSpacing(
            context,
            mobile: 10,
            tablet: 12,
            desktop: 14,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: PaymentTypeOption(
                title: 'Lunas',
                subtitle: 'Bayar penuh',
                isSelected: paymentType == 'full',
                onTap: () => onPaymentTypeChanged('full'),
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: ResponsiveHelper.getResponsiveSpacing(
                context,
                mobile: 10,
                tablet: 12,
                desktop: 14,
              ),
            ),
            Expanded(
              child: PaymentTypeOption(
                title: 'DP',
                subtitle: 'Minimal 30%',
                isSelected: paymentType == 'partial',
                onTap: () => onPaymentTypeChanged('partial'),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metode Pembayaran',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
            ),
            Text(
              '* Struk pembayaran wajib diisi',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 10,
                    color: AppColors.error, // Status color
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: onAddPaymentMethod,
          icon: Icon(
            Icons.add,
            size: 16,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
          label: Text(
            'Tambah',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsList(BuildContext context) {
    if (paymentMethods.isEmpty) {
      return _buildEmptyPaymentMethods(context);
    }

    return Column(
      children: paymentMethods.asMap().entries.map((entry) {
        final index = entry.key;
        final payment = entry.value;
        return PaymentMethodCard(
          payment: payment,
          index: index,
          isDark: isDark,
          onViewReceipt: () => onViewReceipt(payment.receiptImagePath),
          onDelete: () => onRemovePayment(index),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyPaymentMethods(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.borderLight, // 30% - Border
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            size: 16,
          ),
          const SizedBox(width: AppPadding.p8),
          Text(
            'Belum ada metode pembayaran',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return PaymentSummary(
      grandTotal: grandTotal,
      totalPaid: totalPaid,
      isDark: isDark,
    );
  }
}
