import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/order_status.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../../../../core/widgets/date_range_filter_action.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
// AsyncStateView no longer needed — using .when() directly for offline-aware error
import '../../../../core/widgets/order_list_card_frame.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../data/models/order_history.dart';
import '../../logic/order_history_provider.dart';
import '../widgets/order_history_skeleton.dart';

class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage> {
  Color _statusColor(String status) =>
      OrderStatusX.fromRaw(status).listForegroundColor;

  IconData _statusIcon(String status) => OrderStatusX.fromRaw(status).icon;

  // ── Date filter helpers ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(orderHistoryProvider);
    final dateRange = ref.watch(dateFilterProvider);

    final filterText = AppFormatters.dateRangeFilterLabel(
      start: dateRange?.start,
      end: dateRange?.end,
      fallbackDate: DateTime.now(),
      includeEndYear: false,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Riwayat Pesanan',
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
            hasActiveFilter: dateRange != null,
            accentColor: AppColors.accent,
            onClear: () => ref.read(dateFilterProvider.notifier).state = null,
            onPick: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDateRange: dateRange,
                helpText: 'Pilih Rentang Tanggal',
              );
              if (picked != null) {
                ref.read(dateFilterProvider.notifier).state = picked;
              }
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: _buildBody(historyAsync),
    );
  }

  // ── Body (offline-aware error) ───────────────────────────────────

  Widget _buildBody(AsyncValue<List<OrderHistory>> historyAsync) {
    return historyAsync.when(
      loading: () => const OrderHistorySkeleton(),
      error: (err, _) {
        final isOffline = ref.watch(isOfflineProvider);
        return ErrorStateView(
          icon: isOffline
              ? Icons.wifi_off_rounded
              : Icons.error_outline_rounded,
          title: isOffline ? 'Sedang offline' : 'Gagal memuat data',
          message: isOffline
              ? 'Periksa koneksi internet Anda dan coba lagi.'
              : err.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(orderHistoryProvider),
          iconColor: isOffline ? AppColors.warning : AppColors.error,
          buttonColor: AppColors.accent,
          buttonTextColor: AppColors.onPrimary,
          messageStyle:
              const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        );
      },
      data: (orders) {
        if (orders.isEmpty) return _buildEmptyState();
        return RefreshIndicator.adaptive(
          color: AppColors.accent,
          onRefresh: () async {
            if (ref.read(isOfflineProvider)) {
              if (context.mounted) {
                AppFeedback.show(context,
                    message: 'Sedang offline — tidak bisa memuat ulang.',
                    type: AppFeedbackType.warning);
              }
              return;
            }
            ref.invalidate(orderHistoryProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            itemCount: orders.length,
            itemBuilder: (context, index) => AnimatedListItem(
              index: index,
              child: RepaintBoundary(
                child: _buildOrderCard(orders[index]),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Empty state ──────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return const EmptyStateView(
      icon: Icons.receipt_long_outlined,
      iconSize: 72,
      title: 'Belum ada pesanan',
      subtitle:
          'Coba ubah rentang tanggal atau tarik ke bawah untuk muat ulang',
      titleStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
      ),
      subtitleStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
    );
  }

  // ── Order card ───────────────────────────────────────────────────

  Widget _buildOrderCard(OrderHistory order) {
    final formattedDate = AppFormatters.shortDateId(order.orderDate);

    final statusColor = _statusColor(order.status);
    final statusIcon = _statusIcon(order.status);

    return OrderListCardFrame(
      referenceNo: order.noSp,
      trailingStatus: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusChip(
            label: order.status,
            icon: statusIcon,
            backgroundColor: statusColor.withValues(alpha: 0.1),
            foregroundColor: statusColor,
          ),
          if (order.isTakeAway) ...[
            const SizedBox(width: 6),
            StatusChip(
              label: 'Take Away',
              backgroundColor: AppColors.surfaceLight,
              foregroundColor: AppColors.textSecondary,
              border: Border.all(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.accentLight,
            child: Text(
              order.customerName.isNotEmpty
                  ? order.customerName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  order.mainItemsCount > 1
                      ? '${order.firstItemName}  +${order.mainItemsCount - 1} item lainnya'
                      : order.firstItemName,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (order.bonusItemsCount > 0) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.card_giftcard_rounded,
                        size: 12,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${order.bonusItemsCount} Bonus/Aksesoris',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
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
      dateText: formattedDate,
      totalText: AppFormatters.currencyIdr(order.totalAmount),
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/order_detail', extra: order);
      },
    );
  }
}
