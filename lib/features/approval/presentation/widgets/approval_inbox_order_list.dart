import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../../../../core/widgets/empty_state_view.dart';
import 'approval_card_item.dart';

/// Daftar SP inbox (Menunggu / Selesai) + empty state + pull-to-refresh.
class ApprovalInboxOrderList extends StatelessWidget {
  const ApprovalInboxOrderList({
    super.key,
    required this.orders,
    required this.isPending,
    required this.onRefresh,
    this.emptyDueToWorkPlaceFilter = false,
    this.emptyDueToCreatorFilter = false,
    this.emptyDueToSearch = false,
  });

  final List<dynamic> orders;
  final bool isPending;
  final Future<void> Function() onRefresh;
  final bool emptyDueToWorkPlaceFilter;
  final bool emptyDueToCreatorFilter;
  final bool emptyDueToSearch;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator.adaptive(
        color: AppColors.accent,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            _EmptyApprovalInbox(
              isPending: isPending,
              emptyDueToWorkPlaceFilter: emptyDueToWorkPlaceFilter,
              emptyDueToCreatorFilter: emptyDueToCreatorFilter,
              emptyDueToSearch: emptyDueToSearch,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator.adaptive(
      color: AppColors.accent,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, isPending ? 20 : 8, 16, 100),
        itemCount: orders.length,
        itemBuilder: (context, index) => AnimatedListItem(
          index: index,
          child: RepaintBoundary(
            child: ApprovalCardItem(
              orderWrap: orders[index],
              isPending: isPending,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyApprovalInbox extends StatelessWidget {
  const _EmptyApprovalInbox({
    required this.isPending,
    required this.emptyDueToWorkPlaceFilter,
    required this.emptyDueToCreatorFilter,
    required this.emptyDueToSearch,
  });

  final bool isPending;
  final bool emptyDueToWorkPlaceFilter;
  final bool emptyDueToCreatorFilter;
  final bool emptyDueToSearch;

  @override
  Widget build(BuildContext context) {
    final String title;
    final String subtitle;
    if (emptyDueToSearch) {
      title = 'Tidak ditemukan';
      subtitle = 'Tidak ada SP yang cocok dengan pencarian Anda.';
    } else if (emptyDueToCreatorFilter) {
      title = 'Tidak ada untuk pembuat ini';
      subtitle = 'Ubah filter pembuat atau pilih Semua pembuat.';
    } else if (emptyDueToWorkPlaceFilter) {
      title = 'Tidak ada untuk lokasi ini';
      subtitle = 'Ubah filter lokasi / toko atau pilih Semua lokasi.';
    } else {
      title = isPending ? 'Semua sudah disetujui!' : 'Belum ada riwayat.';
      subtitle = isPending
          ? 'Tidak ada antrean persetujuan saat ini.'
          : 'Belum ada riwayat persetujuan diskon.';
    }

    return EmptyStateView(
      icon: emptyDueToSearch || emptyDueToCreatorFilter
          ? Icons.search_off_rounded
          : (isPending
              ? Icons.check_circle_outline_rounded
              : Icons.receipt_long_outlined),
      iconSize: 72,
      title: title,
      subtitle: subtitle,
      titleStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
      ),
      subtitleStyle:
          const TextStyle(fontSize: 13, color: AppColors.textTertiary),
    );
  }
}
