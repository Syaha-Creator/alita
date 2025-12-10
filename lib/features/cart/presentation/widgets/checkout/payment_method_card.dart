import 'package:flutter/material.dart';
import '../../../../../core/utils/format_helper.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../theme/app_colors.dart';
import 'payment_method_model.dart';
import 'payment_helpers.dart';

/// Widget untuk menampilkan kartu metode pembayaran
/// Pure UI widget - semua logic di-handle oleh parent melalui callbacks
class PaymentMethodCard extends StatelessWidget {
  final PaymentMethod payment;
  final int index;
  final bool isDark;
  final VoidCallback onViewReceipt;
  final VoidCallback onDelete;

  const PaymentMethodCard({
    super.key,
    required this.payment,
    required this.index,
    required this.isDark,
    required this.onViewReceipt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveSpacing(
          context,
          mobile: 6,
          tablet: 8,
          desktop: 10,
        ),
      ),
      padding: ResponsiveHelper.getCardPadding(context),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(
            context,
            mobile: 6,
            tablet: 8,
            desktop: 10,
          ),
        ),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight, // 30% - Border
        ),
      ),
      child: Row(
        children: [
          // Payment Icon
          _buildPaymentIcon(context),
          SizedBox(
            width: ResponsiveHelper.getResponsiveSpacing(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
          // Payment Info
          Expanded(child: _buildPaymentInfo(context)),
          // Amount
          _buildAmountText(context),
          SizedBox(
            width: ResponsiveHelper.getResponsiveSpacing(
              context,
              mobile: 3,
              tablet: 4,
              desktop: 6,
            ),
          ),
          // Action Buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildPaymentIcon(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveHelper.getResponsiveSpacing(
          context,
          mobile: 6,
          tablet: 8,
          desktop: 10,
        ),
      ),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(
            context,
            mobile: 4,
            tablet: 6,
            desktop: 8,
          ),
        ),
      ),
      child: Icon(
        PaymentHelpers.getPaymentIcon(payment.methodType),
        size: ResponsiveHelper.getResponsiveIconSize(
          context,
          mobile: 14,
          tablet: 16,
          desktop: 18,
        ),
        color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
      ),
    );
  }

  Widget _buildPaymentInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          payment.methodName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 13,
                  tablet: 14,
                  desktop: 15,
                ),
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        if (payment.reference != null && payment.reference!.isNotEmpty) ...[
          SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(
              context,
              mobile: 2,
              tablet: 3,
              desktop: 4,
            ),
          ),
          Text(
            'Ref: ${payment.reference}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 10,
                    tablet: 11,
                    desktop: 12,
                  ),
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
        SizedBox(
          height: ResponsiveHelper.getResponsiveSpacing(
            context,
            mobile: 2,
            tablet: 3,
            desktop: 4,
          ),
        ),
        Row(
          children: [
            Icon(
              Icons.receipt,
              size: ResponsiveHelper.getResponsiveIconSize(
                context,
                mobile: 10,
                tablet: 12,
                desktop: 14,
              ),
              color: AppColors.success,
            ),
            SizedBox(
              width: ResponsiveHelper.getResponsiveSpacing(
                context,
                mobile: 3,
                tablet: 4,
                desktop: 5,
              ),
            ),
            Flexible(
              child: Text(
                'Struk tersedia',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 9,
                        tablet: 10,
                        desktop: 11,
                      ),
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountText(BuildContext context) {
    return Flexible(
      child: Text(
        FormatHelper.formatCurrency(payment.amount),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 13,
                tablet: 14,
                desktop: 15,
              ),
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onViewReceipt,
          icon: Icon(
            Icons.visibility,
            size: ResponsiveHelper.getResponsiveIconSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
            color: AppColors.success,
          ),
          constraints: BoxConstraints(
            minWidth: ResponsiveHelper.getMinTouchTargetSize(context),
            minHeight: ResponsiveHelper.getMinTouchTargetSize(context),
          ),
          padding: EdgeInsets.zero,
        ),
        IconButton(
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline,
            size: ResponsiveHelper.getResponsiveIconSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
            color: AppColors.error, // Status color
          ),
          constraints: BoxConstraints(
            minWidth: ResponsiveHelper.getMinTouchTargetSize(context),
            minHeight: ResponsiveHelper.getMinTouchTargetSize(context),
          ),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

