import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/widgets/section_card.dart';

/// Menjelaskan bahwa penawaran hanya di perangkat, snapshot harga, dan PDF lokal.
class QuotationDeviceOnlyNotice extends StatelessWidget {
  const QuotationDeviceOnlyNotice({super.key, this.compact = false});

  /// Satu blok ringkas di daftar riwayat.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Semantics(
        container: true,
        label:
            'Penawaran disimpan hanya di perangkat ini. Saat koneksi kembali di halaman ini, harga bisa diselaraskan otomatis. Tombol Checkout menarik harga server dulu bila online. PDF bisa dibuat tanpa internet.',
        child: Container(
          padding: const EdgeInsets.all(AppLayoutTokens.space12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.phone_android_outlined,
                size: 20,
                color: AppColors.textTertiary,
              ),
              SizedBox(width: AppLayoutTokens.space10),
              Expanded(
                child: Text(
                  'Hanya di perangkat ini · Online: sinkron otomatis saat kembali · Checkout: refresh harga dulu',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SectionCard(
      padding: const EdgeInsets.all(AppLayoutTokens.space14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: AppColors.accent.withValues(alpha: 0.85),
              ),
              const SizedBox(width: AppLayoutTokens.space10),
              const Expanded(
                child: Text(
                  'Penyimpanan lokal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayoutTokens.space8),
          const Text(
            'Data tidak disinkron ke server. Harga dan item mengikuti snapshot saat Anda menyimpan; untuk memperbarui, edit lewat keranjang lalu simpan ulang.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppLayoutTokens.space8),
          const Text(
            'Saat koneksi kembali di halaman ini, daftar penawaran diselaraskan otomatis dengan pricelist server (jika channel/brand dikenali). Tombol Checkout juga menarik harga terbaru dulu sebagai konfirmasi sebelum Buat Surat Pesanan; di SP Anda tetap bisa pakai ikon sinkron bila perlu.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppLayoutTokens.space8),
          const Text(
            'PDF dibuat sepenuhnya di perangkat (Offline). Bagikan file lewat aplikasi yang tersedia. Beberapa opsi (mis. WhatsApp Web) baru jalan saat online.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
