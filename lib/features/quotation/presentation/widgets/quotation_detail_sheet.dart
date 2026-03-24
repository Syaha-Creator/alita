import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/detail_info_row.dart';
import '../../../../core/widgets/detail_item_index_badge.dart';
import '../../../cart/data/cart_item.dart';
import '../../data/quotation_model.dart';

class QuotationDetailSheet extends StatelessWidget {
  const QuotationDetailSheet({super.key, required this.quotation});

  final QuotationModel quotation;

  double get _postage {
    if (quotation.postage.isEmpty) return 0;
    final digits = quotation.postage.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(digits) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final q = quotation;
    final address = [
      q.customerAddress,
      q.regionKecamatan,
      q.regionKota,
      q.regionProvinsi,
    ].where((s) => s.isNotEmpty).join(', ');

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 20, color: AppColors.accent),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Detail Penawaran',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                const _SectionTitle(title: 'Informasi Pelanggan'),
                const SizedBox(height: 8),
                _DetailCard(
                  children: [
                    DetailInfoRow(label: 'Nama', value: q.customerName),
                    if (q.customerPhone.isNotEmpty)
                      DetailInfoRow(label: 'Telepon', value: q.customerPhone),
                    if (q.customerPhone2.isNotEmpty)
                      DetailInfoRow(
                          label: 'Telepon 2', value: q.customerPhone2),
                    if (q.customerEmail.isNotEmpty)
                      DetailInfoRow(label: 'Email', value: q.customerEmail),
                    if (address.isNotEmpty)
                      DetailInfoRow(label: 'Alamat', value: address),
                    if (q.scCode.isNotEmpty)
                      DetailInfoRow(label: 'SC Code', value: q.scCode),
                    DetailInfoRow(
                      label: 'Tanggal',
                      value: AppFormatters.dateTimeId(
                          q.createdAt.toIso8601String()),
                    ),
                    if (q.requestDate case final reqDate?
                        when reqDate.isNotEmpty)
                      DetailInfoRow(
                        label: 'Tgl Pengiriman',
                        value: AppFormatters.dateTimeId(reqDate),
                      ),
                    if (q.isTakeAway)
                      const DetailInfoRow(
                          label: 'Pengambilan', value: 'Take Away'),
                  ],
                ),

                const SizedBox(height: 20),

                _SectionTitle(
                  title: 'Rincian Produk',
                  trailing: Text(
                    '${q.items.length} item',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...q.items.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProductItemCard(
                          index: e.key + 1,
                          item: e.value,
                        ),
                      ),
                    ),

                const SizedBox(height: 12),

                const _SectionTitle(title: 'Ringkasan Harga'),
                const SizedBox(height: 8),
                _DetailCard(
                  children: [
                    DetailInfoRow(
                      label: 'Subtotal',
                      value: AppFormatters.currencyIdr(q.subtotal),
                    ),
                    if (q.discount > 0)
                      DetailInfoRow(
                        label: 'Diskon',
                        value: '- ${AppFormatters.currencyIdr(q.discount)}',
                        valueStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    if (_postage > 0)
                      DetailInfoRow(
                        label: 'Ongkos Kirim',
                        value: AppFormatters.currencyIdr(_postage),
                      ),
                    const Divider(height: 16, color: AppColors.border),
                    DetailInfoRow(
                      label: 'Total',
                      value: AppFormatters.currencyIdr(q.totalPrice),
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      valueStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),

                if (q.notes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _SectionTitle(title: 'Catatan'),
                  const SizedBox(height: 8),
                  _DetailCard(
                    children: [
                      Text(
                        q.notes,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets (private to this file) ────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        if (trailing case final t?) ...[const Spacer(), t],
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1 && children[i] is DetailInfoRow)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ProductItemCard extends StatelessWidget {
  const _ProductItemCard({required this.index, required this.item});

  final int index;
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final p = item.product;

    bool hasComponent(String value) {
      final lower = value.trim().toLowerCase();
      return lower.isNotEmpty && !lower.contains('tanpa');
    }

    final components = <_ComponentInfo>[];

    if (p.isSet && hasComponent(p.divan)) {
      components.add(_ComponentInfo(
          label: 'Divan', name: p.divan, sku: item.divanSku,
          kain: item.divanKain, warna: item.divanWarna));
    }
    if (p.isSet && hasComponent(p.headboard)) {
      components.add(_ComponentInfo(
          label: 'Sandaran', name: p.headboard, sku: item.sandaranSku,
          kain: item.sandaranKain, warna: item.sandaranWarna));
    }
    if (p.isSet && hasComponent(p.sorong)) {
      components.add(_ComponentInfo(
          label: 'Sorong', name: p.sorong, sku: item.sorongSku,
          kain: item.sorongKain, warna: item.sorongWarna));
    }

    final bonuses = item.bonusSnapshots.where((b) => b.name.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailItemIndexBadge(index: index),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      [p.brand, if (p.ukuran.isNotEmpty) p.ukuran,
                        p.isSet ? 'Set Lengkap' : 'Kasur Saja'].join(' · '),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(AppFormatters.currencyIdr(item.totalPrice),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
                  Text('Qty: ${item.quantity}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textTertiary)),
                ],
              ),
            ],
          ),

          if (components.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: AppColors.border),
            ),
            Text('Rincian Set:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary.withValues(alpha: 0.8))),
            const SizedBox(height: 6),
            for (final comp in components)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('  •  ',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                    Expanded(
                      child: Text(_formatComponent(comp),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
          ],

          if (bonuses.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: AppColors.border),
            ),
            Text('Bonus / Aksesoris:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary.withValues(alpha: 0.8))),
            const SizedBox(height: 6),
            for (final bonus in bonuses)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Text('  •  ',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                    Expanded(
                      child: Text('${bonus.qty}x ${bonus.name}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ),
                    if (bonus.sku.isNotEmpty)
                      Text('SKU: ${bonus.sku}',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textTertiary)),
                  ],
                ),
              ),
          ],

          if (item.discount1 > 0 || item.discount2 > 0 ||
              item.discount3 > 0 || item.discount4 > 0) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: AppColors.border),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (item.discount1 > 0) _DiscountChip(label: 'D1: ${item.discount1}%'),
                if (item.discount2 > 0) _DiscountChip(label: 'D2: ${item.discount2}%'),
                if (item.discount3 > 0) _DiscountChip(label: 'D3: ${item.discount3}%'),
                if (item.discount4 > 0) _DiscountChip(label: 'D4: ${item.discount4}%'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatComponent(_ComponentInfo c) {
    final parts = <String>[c.label, c.name];
    if (c.kain.isNotEmpty) parts.add(c.kain);
    if (c.warna.isNotEmpty) parts.add(c.warna);
    if (c.sku.isNotEmpty) parts.add('(SKU: ${c.sku})');
    return parts.join(' · ');
  }
}

class _ComponentInfo {
  final String label, name, sku, kain, warna;
  const _ComponentInfo({
    required this.label, required this.name,
    this.sku = '', this.kain = '', this.warna = '',
  });
}

class _DiscountChip extends StatelessWidget {
  const _DiscountChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: AppColors.success)),
    );
  }
}
