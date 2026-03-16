import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/order_status.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/async_state_view.dart';
import '../../../../core/widgets/date_range_filter_action.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/order_list_card_frame.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../data/models/order_history.dart';
import '../../logic/order_history_provider.dart';
import 'order_detail_page.dart';

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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Riwayat Pesanan',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          DateRangeFilterAction(
            label: filterText,
            hasActiveFilter: dateRange != null,
            accentColor: Colors.pink,
            onClear: () => ref.read(dateFilterProvider.notifier).state = null,
            onPick: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDateRange: dateRange,
                helpText: 'Pilih Rentang Tanggal',
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Colors.pink,
                      onPrimary: Colors.white,
                      onSurface: Colors.black87,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                ref.read(dateFilterProvider.notifier).state = picked;
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: AsyncStateView(
        state: historyAsync,
        loading: const Center(
          child: CircularProgressIndicator.adaptive(valueColor: AlwaysStoppedAnimation(Colors.pink), strokeWidth: 2),
        ),
        errorBuilder: (err, _) => ErrorStateView(
          title: 'Gagal memuat data',
          message: err.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(orderHistoryProvider),
          iconColor: Colors.red.shade300,
          buttonColor: Colors.pink,
          buttonTextColor: Colors.white,
          messageStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        dataBuilder: (orders) {
          if (orders.isEmpty) return _buildEmptyState();
          return RefreshIndicator(
            color: Colors.pink,
            onRefresh: () async => ref.invalidate(orderHistoryProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              itemCount: orders.length,
              itemBuilder: (context, index) => RepaintBoundary(
                child: _buildOrderCard(orders[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return EmptyStateView(
      icon: Icons.receipt_long_outlined,
      iconSize: 72,
      title: 'Belum ada pesanan',
      subtitle: 'Coba ubah rentang tanggal atau tarik ke bawah untuk muat ulang',
      titleStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
      ),
      subtitleStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
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
              backgroundColor: Colors.teal.shade50,
              foregroundColor: Colors.teal.shade700,
              border: Border.all(color: Colors.teal.shade200),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              textStyle: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
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
            backgroundColor: Colors.pink.shade50,
            child: Text(
              order.customerName.isNotEmpty
                  ? order.customerName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.pink,
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  order.mainItemsCount > 1
                      ? '${order.firstItemName}  +${order.mainItemsCount - 1} item lainnya'
                      : order.firstItemName,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                        color: Colors.pink,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${order.bonusItemsCount} Bonus/Aksesoris',
                        style: const TextStyle(
                          color: Colors.pink,
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OrderDetailPage(order: order)),
        );
      },
    );
  }
}
