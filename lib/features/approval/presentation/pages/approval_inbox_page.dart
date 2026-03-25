import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../../../../core/widgets/date_range_filter_action.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/selection_bottom_sheet.dart';
import '../../logic/approval_inbox_provider.dart';
import '../widgets/approval_card_item.dart';
import '../widgets/approval_history_work_place_filter_pill.dart';
import '../widgets/approval_inbox_skeleton.dart';

class ApprovalInboxPage extends ConsumerStatefulWidget {
  const ApprovalInboxPage({super.key});

  @override
  ConsumerState<ApprovalInboxPage> createState() => _ApprovalInboxPageState();
}

class _ApprovalInboxPageState extends ConsumerState<ApprovalInboxPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(approvalInboxProvider.notifier).fetchInbox();
    });
  }

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
              onClear: () =>
                  ref.read(approvalInboxProvider.notifier).clearDateFilter(),
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
                ? _buildErrorView(state.error ?? 'Terjadi kesalahan')
                : TabBarView(
                    children: [
                      _KeepAliveTab(
                        child: _buildListView(state.pendingApprovals, true),
                      ),
                      _KeepAliveTab(
                        child: _buildHistoryTabWithWorkPlaceFilter(state),
                      ),
                    ],
                  ),
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────

  Widget _buildErrorView(String error) {
    final isOffline = ref.watch(isOfflineProvider);
    return ErrorStateView(
      icon: isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      title: isOffline ? 'Sedang offline' : 'Gagal memuat data',
      message: isOffline
          ? 'Periksa koneksi internet Anda dan coba lagi.'
          : error.replaceFirst('Exception: ', ''),
      onRetry: () => ref.read(approvalInboxProvider.notifier).fetchInbox(),
      iconColor: isOffline ? AppColors.warning : AppColors.error,
      buttonColor: AppColors.accent,
      buttonTextColor: AppColors.onPrimary,
      messageStyle:
          const TextStyle(fontSize: 13, color: AppColors.textSecondary),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────

  Widget _buildEmptyState(
    bool isPending, {
    bool emptyDueToWorkPlaceFilter = false,
  }) {
    return EmptyStateView(
      icon: isPending
          ? Icons.check_circle_outline_rounded
          : Icons.receipt_long_outlined,
      iconSize: 72,
      title: emptyDueToWorkPlaceFilter
          ? 'Tidak ada untuk lokasi ini'
          : (isPending ? 'Semua sudah disetujui!' : 'Belum ada riwayat.'),
      subtitle: emptyDueToWorkPlaceFilter
          ? 'Ubah filter lokasi / toko atau pilih Semua lokasi.'
          : (isPending
              ? 'Tidak ada antrean persetujuan saat ini.'
              : 'Belum ada riwayat persetujuan diskon.'),
      titleStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
      ),
      subtitleStyle:
          const TextStyle(fontSize: 13, color: AppColors.textTertiary),
    );
  }

  // ── Tab Selesai: filter lokasi / toko ───────────────────────────

  Widget _buildHistoryTabWithWorkPlaceFilter(ApprovalInboxState state) {
    final options = state.historyWorkPlaceOptions;
    final filtered = state.filteredHistoryApprovals;

    if (options.isEmpty) {
      return _buildListView(filtered, false);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: ApprovalHistoryWorkPlaceFilterPill(
            selectedWorkPlace: state.historyWorkPlaceFilter,
            filteredCount: filtered.length,
            totalCount: state.historyApprovals.length,
            onTap: () => _openHistoryWorkPlaceSheet(state, options),
          ),
        ),
        Expanded(
          child: _buildListView(
            filtered,
            false,
            emptyDueToWorkPlaceFilter: filtered.isEmpty &&
                state.historyApprovals.isNotEmpty &&
                state.historyWorkPlaceFilter != null,
          ),
        ),
      ],
    );
  }

  void _openHistoryWorkPlaceSheet(
    ApprovalInboxState state,
    List<String> options,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SelectionBottomSheet<String?>(
        title: 'Lokasi / toko',
        items: <String?>[null, ...options],
        selectedItem: state.historyWorkPlaceFilter,
        labelBuilder: (s) => s == null
            ? 'Semua lokasi'
            : AppFormatters.titleCase(s.toLowerCase()),
        onItemSelected: (s) => ref
            .read(approvalInboxProvider.notifier)
            .setHistoryWorkPlaceFilter(s),
      ),
    );
  }

  // ── List ─────────────────────────────────────────────────────────

  Future<void> _onRefresh() async {
    if (ref.read(isOfflineProvider)) {
      if (context.mounted) {
        AppFeedback.show(
          context,
          message: 'Sedang offline — tidak bisa memuat ulang.',
          type: AppFeedbackType.warning,
        );
      }
      return;
    }
    await ref.read(approvalInboxProvider.notifier).fetchInbox();
  }

  Widget _buildListView(
    List<dynamic> orders,
    bool isPending, {
    bool emptyDueToWorkPlaceFilter = false,
  }) {
    if (orders.isEmpty) {
      return RefreshIndicator.adaptive(
        color: AppColors.accent,
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            _buildEmptyState(
              isPending,
              emptyDueToWorkPlaceFilter: emptyDueToWorkPlaceFilter,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator.adaptive(
      color: AppColors.accent,
      onRefresh: _onRefresh,
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

/// Minimal pass-through widget that keeps its child alive when switching tabs.
class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});

  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
