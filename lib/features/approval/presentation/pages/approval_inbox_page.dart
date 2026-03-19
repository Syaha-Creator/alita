import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/date_range_filter_action.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../logic/approval_inbox_provider.dart';
import '../widgets/approval_card_item.dart';
import '../widgets/approval_inbox_skeleton.dart';

class ApprovalInboxPage extends ConsumerStatefulWidget {
  const ApprovalInboxPage({super.key});

  @override
  ConsumerState<ApprovalInboxPage> createState() => _ApprovalInboxPageState();
}

class _ApprovalInboxPageState extends ConsumerState<ApprovalInboxPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(approvalInboxProvider);

    final hasDateFilter = state.startDate != null && state.endDate != null;
    final filterText = AppFormatters.dateRangeFilterLabel(
      start: state.startDate,
      end: state.endDate,
      fallbackDate: DateTime.now(),
      includeEndYear: true,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Persetujuan Diskon',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 1,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          actions: [
            DateRangeFilterAction(
              label: filterText,
              hasActiveFilter: hasDateFilter,
              accentColor: AppColors.accent,
              onClear: () => ref
                  .read(approvalInboxProvider.notifier)
                  .clearDateFilter(),
              onPick: () async {
                final initialStart = state.startDate ??
                    DateTime.now().subtract(const Duration(days: 30));
                final initialEnd = state.endDate ?? DateTime.now();

                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: DateTimeRange(
                    start: initialStart,
                    end: initialEnd,
                  ),
                  helpText: 'Pilih Rentang Tanggal',
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.accent,
                        onPrimary: AppColors.onPrimary,
                        onSurface: AppColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  ),
                );

                if (picked != null) {
                  ref
                      .read(approvalInboxProvider.notifier)
                      .updateDateFilter(picked.start, picked.end);
                }
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicatorPadding: const EdgeInsets.all(4),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: AppColors.accent,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: AppColors.onPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Menunggu'),
                  Tab(text: 'Selesai'),
                ],
              ),
            ),
          ),
        ),
        body: state.isLoading && state.pendingApprovals.isEmpty
            ? const ApprovalInboxSkeleton()
            : state.error != null
                ? _buildErrorView(state.error!)
                : TabBarView(
                    children: [
                      _buildListView(state.pendingApprovals, true),
                      _buildListView(state.historyApprovals, false),
                    ],
                  ),
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────

  Widget _buildErrorView(String error) {
    return ErrorStateView(
      title: 'Gagal memuat data',
      message: error.replaceFirst('Exception: ', ''),
      onRetry: () => ref.read(approvalInboxProvider.notifier).fetchInbox(),
      iconColor: AppColors.error,
      buttonColor: AppColors.accent,
      buttonTextColor: AppColors.onPrimary,
      messageStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────

  Widget _buildEmptyState(bool isPending) {
    return EmptyStateView(
      icon: isPending
          ? Icons.check_circle_outline_rounded
          : Icons.receipt_long_outlined,
      iconSize: 72,
      title: isPending ? 'Semua sudah disetujui!' : 'Belum ada riwayat.',
      subtitle: isPending
          ? 'Tidak ada antrean persetujuan saat ini.'
          : 'Belum ada riwayat persetujuan diskon.',
      titleStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
      ),
      subtitleStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
    );
  }

  // ── List ─────────────────────────────────────────────────────────

  Widget _buildListView(List<dynamic> orders, bool isPending) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => ref.read(approvalInboxProvider.notifier).fetchInbox(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            _buildEmptyState(isPending),
          ],
        ),
      );
    }

    return RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => ref.read(approvalInboxProvider.notifier).fetchInbox(),
        child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        itemCount: orders.length,
        itemBuilder: (context, index) => RepaintBoundary(
          child: ApprovalCardItem(
            orderWrap: orders[index],
            isPending: isPending,
          ),
        ),
      ),
    );
  }

}
