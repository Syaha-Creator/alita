import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/network_guard.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../data/quotation_model.dart';
import '../../logic/quotation_list_provider.dart';
import '../../logic/quotation_pdf_generator.dart';
import '../widgets/quotation_card.dart';

// ─── Sort options ────────────────────────────────────────────────────────────

enum _SortMode {
  newestFirst('Terbaru'),
  oldestFirst('Terlama'),
  nameAZ('Nama A-Z'),
  priceHigh('Harga Tertinggi'),
  priceLow('Harga Terendah');

  const _SortMode(this.label);
  final String label;
}

/// Riwayat Penawaran — lists all locally-saved quotation drafts.
///
/// When [autoPdfQuotation] is provided (via route extra from checkout page),
/// auto-generates and shares the PDF after the page builds.
class QuotationHistoryPage extends ConsumerStatefulWidget {
  const QuotationHistoryPage({super.key, this.autoPdfQuotation});

  final QuotationModel? autoPdfQuotation;

  @override
  ConsumerState<QuotationHistoryPage> createState() =>
      _QuotationHistoryPageState();
}

class _QuotationHistoryPageState extends ConsumerState<QuotationHistoryPage> {
  bool _autoPdfTriggered = false;
  final _searchCtrl = TextEditingController();
  _SortMode _sortMode = _SortMode.newestFirst;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
    if (widget.autoPdfQuotation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerAutoPdf();
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _triggerAutoPdf() async {
    if (_autoPdfTriggered) return;
    _autoPdfTriggered = true;

    final q = widget.autoPdfQuotation;
    if (q == null || !mounted) return;

    final isOffline = ref.read(isOfflineProvider);
    if (ifOfflineShowFeedback(context, isOffline: isOffline)) return;
    AppFeedback.show(context,
        message: 'Membuat PDF penawaran…', type: AppFeedbackType.info);

    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin =
          box != null ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;
      await QuotationPdfGenerator.generateAndShare(q,
          sharePositionOrigin: origin);
    } catch (e) {
      if (mounted) {
        AppFeedback.show(context,
            message: 'Gagal membuat PDF: $e', type: AppFeedbackType.error);
      }
    }
  }

  List<QuotationModel> _filtered(List<QuotationModel> all) {
    var list = all;

    if (_searchQuery.isNotEmpty) {
      list = list.where((q) {
        final hay = '${q.customerName} '
                '${q.items.map((e) => e.product.name).join(' ')}'
            .toLowerCase();
        return hay.contains(_searchQuery);
      }).toList();
    }

    switch (_sortMode) {
      case _SortMode.newestFirst:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortMode.oldestFirst:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _SortMode.nameAZ:
        list.sort((a, b) => a.customerName
            .toLowerCase()
            .compareTo(b.customerName.toLowerCase()));
      case _SortMode.priceHigh:
        list.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
      case _SortMode.priceLow:
        list.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final allDrafts = ref.watch(quotationListProvider);
    final drafts = _filtered(List.of(allDrafts));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Penawaran'),
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        actions: [
          PopupMenuButton<_SortMode>(
            icon: const Icon(Icons.sort_rounded, size: 22),
            tooltip: 'Urutkan',
            onSelected: (v) => setState(() => _sortMode = v),
            itemBuilder: (_) => _SortMode.values
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          if (s == _sortMode)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(Icons.check_rounded,
                                  size: 16, color: AppColors.accent),
                            )
                          else
                            const SizedBox(width: 24),
                          Text(s.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (allDrafts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: AppSearchField(
                controller: _searchCtrl,
                hintText: 'Cari nama pelanggan atau produk…',
                hintStyle: const TextStyle(
                    fontSize: 13, color: AppColors.textTertiary),
                textStyle: const TextStyle(fontSize: 13),
                prefixIconSize: 20,
                prefixIconColor: AppColors.textTertiary,
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.5)),
                ),
                onChanged: (_) {},
              ),
            ),

          Expanded(
            child: allDrafts.isEmpty
                ? EmptyStateView(
                    icon: Icons.description_outlined,
                    title: 'Belum ada penawaran',
                    subtitle: 'Penawaran yang Anda simpan akan muncul di sini.',
                    action: FilledButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Buka Beranda'),
                    ),
                  )
                : drafts.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.search_off_rounded,
                        title: 'Tidak ditemukan',
                        subtitle: 'Coba kata kunci lain',
                      )
                    : RefreshIndicator.adaptive(
                        color: AppColors.accent,
                        onRefresh: () async =>
                            ref.invalidate(quotationListProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: drafts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final q = drafts[index];
                            return AnimatedListItem(
                              index: index,
                              child: Dismissible(
                                key: ValueKey(q.id),
                                direction: DismissDirection.endToStart,
                                background: _buildSwipeBackground(),
                                confirmDismiss: (_) =>
                                    _confirmSwipeDelete(context, q),
                                onDismissed: (_) =>
                                    _handleDismissed(context, q),
                                child: QuotationCard(quotation: q),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 24),
          SizedBox(height: 4),
          Text('Hapus',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error)),
        ],
      ),
    );
  }

  Future<bool> _confirmSwipeDelete(
      BuildContext context, QuotationModel q) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Draft'),
            content: Text('Hapus penawaran untuk "${q.customerName}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _handleDismissed(BuildContext context, QuotationModel q) {
    ref.read(quotationListProvider.notifier).remove(q.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Penawaran "${q.customerName}" dihapus'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: AppColors.accent,
            onPressed: () {
              ref.read(quotationListProvider.notifier).add(q);
            },
          ),
        ),
      );
  }
}
