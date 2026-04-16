import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';

/// Mini dashboard: nominal selesai/disahkan (kiri) + antrean (kanan).
///
/// Hanya tampilan ringkas (non-interaktif); detail lewat menu Riwayat / Persetujuan.
/// Struktur visual (gradasi, border, pemisah) dipertahankan; konten data-dense.
class ProfileStatsCard extends StatelessWidget {
  const ProfileStatsCard({
    super.key,
    required this.monthSuccessNominalCompact,
    required this.completedOrdersCount,
    required this.totalPending,
    required this.pendingSubtitle,
    this.completedOrdersCaption = 'Pesanan Selesai',
  });

  /// Dari [AppFormatters.currencyIdrCompact], atau `'...'` saat loading.
  final String monthSuccessNominalCompact;

  /// Jumlah SP / pesanan selesai (untuk subjudul kiri).
  final int completedOrdersCount;

  /// Teks setelah "Dari N " (mis. `Pesanan Selesai`, `SP disetujui`).
  final String completedOrdersCaption;

  /// Teks angka antrean / pending (boleh `'...'`).
  final String totalPending;

  /// Subjudul kolom kanan (mis. SP Menunggu Approval / Antrean Persetujuan).
  final String pendingSubtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppLayoutTokens.space20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accentLight, AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accentBorder, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      monthSuccessNominalCompact,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppLayoutTokens.space6),
                  Text(
                    'Dari $completedOrdersCount $completedOrdersCaption',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.accentBorder,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalPending,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warning,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: AppLayoutTokens.space6),
                  Text(
                    pendingSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
