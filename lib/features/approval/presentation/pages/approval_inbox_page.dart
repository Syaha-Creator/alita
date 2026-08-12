import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/date_range_filter_action.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/go_router_pop_scope.dart';
import '../../logic/approval_inbox_provider.dart';
import '../widgets/approval_inbox_skeleton.dart';
import '../widgets/approval_inbox_tabs.dart';

class ApprovalInboxPage extends ConsumerStatefulWidget {
  const ApprovalInboxPage({super.key});

  @override
  ConsumerState<ApprovalInboxPage> createState() => _ApprovalInboxPageState();
}

class _ApprovalInboxPageState extends ConsumerState<ApprovalInboxPage> {
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    // Freshness window di notifier mencegah double-fetch dengan profile/constructor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(approvalInboxProvider.notifier).fetchInbox();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(approvalInboxProvider);

    // Tanpa filter aktif, label menampilkan bulan berjalan — selaras default
    // backend saat `date_from`/`date_to` tidak dikirim.
    final hasDateFilter = state.startDate != null && state.endDate != null;
    final filterText = AppFormatters.dateRangeFilterLabel(
      start: state.startDate,
      end: state.endDate,
      fallbackDate: DateTime.now(),
      includeEndYear: true,
    );

    return GoRouterPopScope(
      fallbackLocation: '/',
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Kembali',
              onPressed: () => GoRouterPopScope.handlePop(
                context,
                fallbackLocation: '/',
              ),
            ),
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

                  if (!mounted) return;
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
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                          child: AppSearchField(
                            controller: _searchCtrl,
                            hintText: 'Cari No SP atau nama customer…',
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                            prefixIconSize: 20,
                            prefixIconColor: AppColors.textTertiary,
                            clearIconColor: AppColors.textTertiary,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            autocorrect: false,
                            enableSuggestions: false,
                            onChanged: (q) {
                              _searchDebounce?.cancel();
                              _searchDebounce = Timer(
                                const Duration(milliseconds: 250),
                                () => ref
                                    .read(approvalInboxProvider.notifier)
                                    .setSearchQuery(q),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _KeepAliveTab(
                                child: ApprovalInboxPendingTab(
                                  onRefresh: _onRefresh,
                                ),
                              ),
                              _KeepAliveTab(
                                child: ApprovalInboxHistoryTab(
                                  onRefresh: _onRefresh,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    final isOffline = ref.watch(isOfflineProvider);
    return ErrorStateView(
      icon: isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      title: isOffline ? 'Sedang offline' : 'Gagal memuat data',
      message: isOffline
          ? 'Periksa koneksi internet Anda dan coba lagi.'
          : error.replaceFirst('Exception: ', ''),
      onRetry: () =>
          ref.read(approvalInboxProvider.notifier).fetchInbox(force: true),
      iconColor: isOffline ? AppColors.warning : AppColors.error,
      buttonColor: AppColors.accent,
      buttonTextColor: AppColors.onPrimary,
      messageStyle:
          const TextStyle(fontSize: 13, color: AppColors.textSecondary),
    );
  }

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
    await ref.read(approvalInboxProvider.notifier).fetchInbox(force: true);
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
