import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../theme/app_colors.dart';

/// Widget untuk menampilkan syarat dan ketentuan
class TermsSection extends StatelessWidget {
  const TermsSection({super.key});

  static const List<String> _terms = [
    'Konsumen wajib melunasi 100% nilai pesanan sebelum melakukan pengiriman / penyerahan barang pesanan. Pelunasan dilakukan selambat-lambatnya 3 hari kerja sebelum jadwal pengiriman / penyerahan yang dijadwalkan.',
    'Barang yang sudah dipesan / dibeli, tidak dapat ditukar atau dikembalikan.',
    'Uang muka yang telah dibayarkan tidak dapat dikembalikan.',
    'Sleep Center berhak mengubah tanggal pengiriman dengan sebelumnya memberitahukan kepada konsumen.',
    'Surat Pesanan yang sudah lewat 3 (Tiga) bulan namun belum dikirim harus dilunasi jika tidak akan dianggap batal dan uang muka tidak dapat dikembalikan.',
    'Apabila konsumen menunda pengiriman selama lebih dari 2 (Dua) Bulan dari tanggal kirim awal, SP dianggap batal dan uang muka tidak dapat dikembalikan.',
    'Pembeli akan dikenakan biaya tambahan untuk pengiriman, pembongkaran, pengambilan furnitur dll yang disebabkan adanya kesulitan/ketidakcocokan penempatan furnitur di tempat atau ruangan yang dikehendaki oleh pembeli.',
    'Jika pengiriman dilakukan lebih dari 1 (Satu) kali, konsumen wajib melunasi pembelian sebelum pengiriman pertama.',
    'Untuk tipe dan ukuran khusus, pelunasan harus dilakukan saat pemesanan dan tidak dapat dibatalkan/diganti.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : AppColors.warning.withValues(alpha: 0.1), // Status color dengan opacity
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.2)
                    : AppColors.warning.withValues(alpha: 0.3), // Status color dengan opacity
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : AppColors.warning.withValues(alpha: 0.2), // Status color dengan opacity
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: isDark ? colorScheme.primary : AppColors.warning, // Status color
                  size: 20,
                ),
              ),
              const SizedBox(width: AppPadding.p12),
              Text(
                'SYARAT DAN KETENTUAN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? colorScheme.onSurface : AppColors.warning, // Status color
                ),
              ),
            ],
          ),
        ),
        // Content section
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < _terms.length; i++) ...[
                _TermsItem(
                  number: '${i + 1}',
                  text: _terms[i],
                ),
                if (i < _terms.length - 1) const SizedBox(height: AppPadding.p12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TermsItem extends StatelessWidget {
  final String number;
  final String text;

  const _TermsItem({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDark ? colorScheme.primaryContainer : AppColors.accentLight.withValues(alpha: 0.15), // 10% dengan opacity
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? colorScheme.onPrimaryContainer : AppColors.accentLight, // 10% - Accent
              ),
            ),
          ),
        ),
        const SizedBox(width: AppPadding.p12),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? colorScheme.onSurface : null,
            ),
          ),
        ),
      ],
    );
  }
}
