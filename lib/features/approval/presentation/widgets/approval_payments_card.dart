import 'package:flutter/material.dart';

import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/detail_payment_item_row.dart';
import '../../../../core/widgets/detail_payments_section.dart';
import '../../../../core/widgets/detail_section_label.dart';
import '../../../../core/widgets/detail_surface_card.dart';
import '../../../../core/widgets/image_viewer_dialog.dart';

/// Payments info card for the approval detail page.
///
/// Lists each payment entry (method, bank, amount) with an optional
/// receipt image thumbnail that opens [ImageViewerDialog] on tap.
class ApprovalPaymentsCard extends StatelessWidget {
  final List<dynamic> payments;

  const ApprovalPaymentsCard({
    super.key,
    required this.payments,
  });

  static String _fmt(num value) => AppFormatters.currencyIdr(value);

  @override
  Widget build(BuildContext context) {
    return DetailSurfaceCard(
      child: DetailPaymentsSection(
        header: const DetailSectionLabel(title: 'Informasi Pembayaran'),
        items: payments.map((entry) {
          final p = entry as Map<String, dynamic>;
          final method = p['payment_method']?.toString() ?? '-';
          final bank = p['payment_bank']?.toString() ?? '-';
          final amount =
              double.tryParse(p['payment_amount']?.toString() ?? '0') ?? 0;
          final imageUrl = p['image']?.toString() ?? '';
          return DetailPaymentItemRow(
            method: method,
            bank: bank,
            amountText: _fmt(amount),
            receiptImageUrl: imageUrl,
            onTapReceipt: imageUrl.isNotEmpty
                ? () => _showImageDialog(context, imageUrl)
                : null,
          );
        }).toList(),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    ImageViewerDialog.show(
      context: context,
      imageUrl: imageUrl,
      borderRadius: 12,
    );
  }
}
