import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/selection_bottom_sheet.dart';
import '../../data/utils/approval_wraps_nominal_sum.dart';
import '../../logic/approval_inbox_provider.dart';
import 'approval_inbox_filter_bar.dart';
import 'approval_inbox_order_list.dart';

Widget approvalInboxTotalBanner(double sum) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(
      AppLayoutTokens.space16,
      AppLayoutTokens.space4,
      AppLayoutTokens.space16,
      AppLayoutTokens.space8,
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayoutTokens.space16,
        vertical: AppLayoutTokens.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
        boxShadow: [AppLayoutTokens.cardShadowSoft],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Total Nominal SP disetujui',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            AppFormatters.currencyIdrFlooredWhole(sum),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    ),
  );
}

void openApprovalCreatorSheet(
  BuildContext context,
  WidgetRef ref, {
  required List<String> options,
  required String? selected,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SelectionBottomSheet<String?>(
      title: 'Pembuat SP',
      items: <String?>[null, ...options],
      selectedItem: selected,
      labelBuilder: (s) => s == null
          ? 'Semua pembuat'
          : AppFormatters.titleCase(s.toLowerCase()),
      onItemSelected: (s) =>
          ref.read(approvalInboxProvider.notifier).setCreatorFilter(s),
    ),
  );
}

void openApprovalWorkPlaceSheet(
  BuildContext context,
  WidgetRef ref, {
  required List<String> options,
  required String? selected,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SelectionBottomSheet<String?>(
      title: 'Lokasi / toko',
      items: <String?>[null, ...options],
      selectedItem: selected,
      labelBuilder: (s) => s == null
          ? 'Semua lokasi'
          : AppFormatters.titleCase(s.toLowerCase()),
      onItemSelected: (s) => ref
          .read(approvalInboxProvider.notifier)
          .setHistoryWorkPlaceFilter(s),
    ),
  );
}

String _countCaption({
  required int filtered,
  required int total,
  required String noun,
  required bool hasActiveFilter,
}) {
  if (hasActiveFilter) return '$filtered dari $total $noun';
  return '$total $noun';
}

/// Tab Menunggu: filter pembuat + daftar SP.
class ApprovalInboxPendingTab extends ConsumerWidget {
  const ApprovalInboxPendingTab({
    super.key,
    required this.onRefresh,
  });

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalInboxProvider);
    final options = state.pendingCreatorOptions;
    final orders = state.filteredPendingApprovals;
    final sum = sumNominalFromApprovedSpOrderWrapsOnly(orders);
    final isSearchEmpty = orders.isEmpty &&
        state.pendingApprovals.isNotEmpty &&
        state.searchQuery.isNotEmpty;
    final isCreatorEmpty = orders.isEmpty &&
        !isSearchEmpty &&
        state.pendingApprovals.isNotEmpty &&
        state.creatorFilter != null;
    final hasCreatorFilter = state.creatorFilter != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (options.isNotEmpty)
          ApprovalInboxFilterBar(
            chips: [
              ApprovalInboxFilterChipSpec(
                icon: Icons.person_outline_rounded,
                allLabel: 'Semua pembuat',
                selectedValue: state.creatorFilter,
                onTap: () => openApprovalCreatorSheet(
                  context,
                  ref,
                  options: options,
                  selected: state.creatorFilter,
                ),
              ),
            ],
            countCaption: _countCaption(
              filtered: orders.length,
              total: state.pendingApprovals.length,
              noun: 'SP',
              hasActiveFilter: hasCreatorFilter,
            ),
          ),
        if (orders.isNotEmpty && sum > 0) approvalInboxTotalBanner(sum),
        Expanded(
          child: ApprovalInboxOrderList(
            orders: orders,
            isPending: true,
            onRefresh: onRefresh,
            emptyDueToSearch: isSearchEmpty,
            emptyDueToCreatorFilter: isCreatorEmpty,
          ),
        ),
      ],
    );
  }
}

/// Tab Selesai: filter pembuat + lokasi + daftar riwayat.
class ApprovalInboxHistoryTab extends ConsumerWidget {
  const ApprovalInboxHistoryTab({
    super.key,
    required this.onRefresh,
  });

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalInboxProvider);
    final workPlaceOptions = state.historyWorkPlaceOptions;
    final creatorOptions = state.historyCreatorOptions;
    final filtered = state.filteredHistoryApprovals;
    final sum = sumNominalFromApprovedSpOrderWrapsOnly(filtered);

    final isSearchEmpty = filtered.isEmpty &&
        state.historyApprovals.isNotEmpty &&
        state.searchQuery.isNotEmpty;
    final isCreatorEmpty = filtered.isEmpty &&
        !isSearchEmpty &&
        state.historyApprovals.isNotEmpty &&
        state.creatorFilter != null;
    final isWorkPlaceFilterEmpty = filtered.isEmpty &&
        !isSearchEmpty &&
        !isCreatorEmpty &&
        state.historyApprovals.isNotEmpty &&
        state.historyWorkPlaceFilter != null;

    final chips = <ApprovalInboxFilterChipSpec>[
      if (creatorOptions.isNotEmpty)
        ApprovalInboxFilterChipSpec(
          icon: Icons.person_outline_rounded,
          allLabel: 'Semua pembuat',
          selectedValue: state.creatorFilter,
          onTap: () => openApprovalCreatorSheet(
            context,
            ref,
            options: creatorOptions,
            selected: state.creatorFilter,
          ),
        ),
      if (workPlaceOptions.isNotEmpty)
        ApprovalInboxFilterChipSpec(
          icon: Icons.storefront_outlined,
          allLabel: 'Semua lokasi',
          selectedValue: state.historyWorkPlaceFilter,
          onTap: () => openApprovalWorkPlaceSheet(
            context,
            ref,
            options: workPlaceOptions,
            selected: state.historyWorkPlaceFilter,
          ),
        ),
    ];

    final hasActiveFilter = state.creatorFilter != null ||
        state.historyWorkPlaceFilter != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (chips.isNotEmpty)
          ApprovalInboxFilterBar(
            chips: chips,
            countCaption: _countCaption(
              filtered: filtered.length,
              total: state.historyApprovals.length,
              noun: 'riwayat',
              hasActiveFilter: hasActiveFilter,
            ),
          ),
        if (filtered.isNotEmpty) approvalInboxTotalBanner(sum),
        Expanded(
          child: ApprovalInboxOrderList(
            orders: filtered,
            isPending: false,
            onRefresh: onRefresh,
            emptyDueToWorkPlaceFilter: isWorkPlaceFilterEmpty,
            emptyDueToCreatorFilter: isCreatorEmpty,
            emptyDueToSearch: isSearchEmpty,
          ),
        ),
      ],
    );
  }
}
