import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Payment info section body: renders payment cards with optional multi-payment summary.
///
/// Extracted from [CheckoutPage] build method to reduce file size.
class CheckoutPaymentInfoSection extends StatelessWidget {
  final int paymentCount;
  final bool isMultiPayment;
  final IndexedWidgetBuilder paymentCardBuilder;
  final Widget paymentSummary;

  const CheckoutPaymentInfoSection({
    super.key,
    required this.paymentCount,
    required this.isMultiPayment,
    required this.paymentCardBuilder,
    required this.paymentSummary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < paymentCount; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border),
            const SizedBox(height: 4),
          ],
          paymentCardBuilder(context, i),
        ],
        if (isMultiPayment) ...[
          const SizedBox(height: 16),
          paymentSummary,
        ],
      ],
    );
  }
}
