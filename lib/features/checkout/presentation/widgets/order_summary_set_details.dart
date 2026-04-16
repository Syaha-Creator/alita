import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';

/// Set component breakdown section shown in checkout order summary item.
///
/// Mirrors [CartItemCard] expanded rincian: Kasur, Divan, Sandaran, Sorong
/// with SKU lines so ringkasan pesanan matches keranjang.
class OrderSummarySetDetails extends StatelessWidget {
  final String kasurLabel;
  final String kasurSku;
  final bool showKasur;
  final String divanLabel;
  final String divanSku;
  final bool showDivan;
  final String headboardLabel;
  final String headboardSku;
  final bool showHeadboard;
  final String sorongLabel;
  final String sorongSku;
  final bool showSorong;

  const OrderSummarySetDetails({
    super.key,
    required this.kasurLabel,
    required this.kasurSku,
    required this.showKasur,
    required this.divanLabel,
    required this.divanSku,
    required this.showDivan,
    required this.headboardLabel,
    required this.headboardSku,
    required this.showHeadboard,
    required this.sorongLabel,
    required this.sorongSku,
    required this.showSorong,
  });

  static const _labelStyle = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  static const _nameStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const _skuStyle = TextStyle(
    fontSize: 11,
    color: AppColors.textTertiary,
  );

  /// Splits "Kasur: Nama Produk" → prefix "Kasur: " + body "Nama Produk".
  static (String prefix, String name) _splitComponentLabel(String full) {
    final i = full.indexOf(': ');
    if (i < 0) {
      return ('', full);
    }
    return (full.substring(0, i + 2), full.substring(i + 2));
  }

  Widget _componentRow(String fullLabel, String sku) {
    final (prefix, name) = _splitComponentLabel(fullLabel);
    final skuText = sku.isNotEmpty ? sku : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: const TextStyle(height: 1.35),
            children: [
              if (prefix.isNotEmpty) ...[
                TextSpan(text: prefix, style: _labelStyle),
                TextSpan(text: name, style: _nameStyle),
              ] else
                TextSpan(text: fullLabel, style: _nameStyle),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'SKU: $skuText',
          style: _skuStyle.copyWith(height: 1.25),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (showKasur) _componentRow(kasurLabel, kasurSku),
      if (showDivan) _componentRow(divanLabel, divanSku),
      if (showHeadboard) _componentRow(headboardLabel, headboardSku),
      if (showSorong) _componentRow(sorongLabel, sorongSku),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rincian Set:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppLayoutTokens.space10),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppLayoutTokens.space8),
          rows[i],
        ],
      ],
    );
  }
}
