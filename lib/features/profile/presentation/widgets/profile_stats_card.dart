import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Mini dashboard: Pesanan Bulan Ini + Menunggu Approval / Antrean Persetujuan.
class ProfileStatsCard extends StatelessWidget {
  const ProfileStatsCard({
    super.key,
    required this.totalPesanan,
    required this.totalPending,
    required this.pendingLabel,
  });

  final String totalPesanan;
  final String totalPending;
  final String pendingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
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
                Text(
                  totalPesanan,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Pesanan Bulan Ini',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.accentBorder),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  totalPending,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  pendingLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
