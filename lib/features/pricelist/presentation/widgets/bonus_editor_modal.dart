import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/action_button_bar.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../logic/accessory_provider.dart';

/// Removes redundant trailing size duplication in bonus display names
/// (e.g. "X 090x200 090x200" → "X 090x200").
String cleanBonusDisplayName(String name) {
  final s = name.trim();
  final parts = s.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    final last = parts.last;
    final prev = parts[parts.length - 2];
    if (last == prev &&
        RegExp(r'^\d+x\d+$', caseSensitive: false).hasMatch(last)) {
      return parts.sublist(0, parts.length - 1).join(' ');
    }
  }
  return s;
}

/// Tinggi perkiraan satu baris bonus (untuk indikator scroll).
const double _kBonusRowHeight = 74;

/// Tinggi maks area daftar bonus (scroll internal; tidak memakan seluruh layar).
const double _kBonusPanelMaxHeight = 240;

/// Bayangan sangat lembut untuk kartu bonus (Material 3–style elevation ringan).
final List<BoxShadow> _kBonusCardShadow = [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.12),
    blurRadius: 8,
    offset: const Offset(0, 2),
  ),
];

/// Latar panel lembut (bonus / aksesoris) tanpa border tegas.
Color _panelTint(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return Color.alphaBlend(
    scheme.surfaceContainerHighest.withValues(alpha: 0.45),
    AppColors.surface,
  );
}

/// Perkiraan konten list bonus (padding + item + separator) vs tinggi panel.
bool _bonusListLikelyScrolls(int itemCount, double panelHeight) {
  if (itemCount <= 0) return false;
  const padV = AppLayoutTokens.space8 * 2;
  final items = itemCount * _kBonusRowHeight;
  final seps = math.max(0, itemCount - 1) * AppLayoutTokens.space12;
  return padV + items + seps > panelHeight - 1;
}

/// List bonus dengan [Scrollbar], gradient bawah saat masih bisa digeser, dan controller.
class _ScrollHintBonusList extends StatefulWidget {
  const _ScrollHintBonusList({
    required this.itemCount,
    required this.itemBuilder,
    required this.panelTint,
    required this.showAffordances,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Color panelTint;
  final bool showAffordances;

  @override
  State<_ScrollHintBonusList> createState() => _ScrollHintBonusListState();
}

class _ScrollHintBonusListState extends State<_ScrollHintBonusList> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _onScroll() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  bool get _hasMoreBelow {
    if (!widget.showAffordances || !_controller.hasClients) return false;
    final p = _controller.position;
    return p.maxScrollExtent > 0 && p.pixels < p.maxScrollExtent - 2;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Scrollbar(
          controller: _controller,
          thumbVisibility: widget.showAffordances,
          thickness: 3,
          radius: const Radius.circular(4),
          child: ListView.separated(
            controller: _controller,
            padding: const EdgeInsets.all(AppLayoutTokens.space8),
            physics: const BouncingScrollPhysics(),
            itemCount: widget.itemCount,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppLayoutTokens.space12),
            itemBuilder: widget.itemBuilder,
          ),
        ),
        if (_hasMoreBelow)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 32,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.panelTint.withValues(alpha: 0),
                      widget.panelTint.withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Shows the bonus editor modal bottom sheet.
///
/// [defaultBonuses] is the list of factory-default bonuses.
/// [isBonusCustomized] indicates if the user has already customized bonuses.
/// [customBonuses] holds the current custom bonus list.
/// [onSave] is called with the new bonus list when the user taps "Simpan Perubahan".
void showBonusEditorModal(
  BuildContext context, {
  required List<Map<String, dynamic>> defaultBonuses,
  required bool isBonusCustomized,
  required List<Map<String, dynamic>> customBonuses,
  required void Function(List<Map<String, dynamic>> newBonuses) onSave,
}) {
  // max_qty tidak dibatasi di custom pricelist — null berarti bebas.
  List<Map<String, dynamic>> tempBonuses =
      (isBonusCustomized ? customBonuses : defaultBonuses)
          .map((e) => Map<String, dynamic>.from(e)..remove('max_qty'))
          .toList();
  String searchQuery = '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final accAsync = ref.watch(accessoryProvider);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.85,
            width: double.infinity,
            child: SheetScaffold(
              topRadius: 20,
              contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  final availableAcc = accAsync.value ?? [];
                  final filteredAcc = availableAcc.where((a) {
                    final searchString =
                        '${a.tipe} ${a.ukuran}'.toLowerCase();
                    return searchString.contains(
                      searchQuery.toLowerCase(),
                    );
                  }).toList();

                  final bonusListScrollHint = _bonusListLikelyScrolls(
                    tempBonuses.length,
                    _kBonusPanelMaxHeight,
                  );

                  Widget bonusPanelBody() {
                    if (tempBonuses.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppLayoutTokens.space16,
                          ),
                          child: Text(
                            'Belum ada bonus. Tambah dari aksesoris di bawah.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ),
                      );
                    }
                    return _ScrollHintBonusList(
                      itemCount: tempBonuses.length,
                      panelTint: _panelTint(context),
                      showAffordances: bonusListScrollHint,
                      itemBuilder: (context, index) {
                        final b = tempBonuses[index];
                        return _BonusRowCard(
                          bonus: b,
                          index: index,
                          onRemoveOrDecrement: () => setModalState(() {
                            final qty = (b['qty'] as int?) ?? 1;
                            if (qty == 1) {
                              tempBonuses.removeAt(index);
                            } else {
                              tempBonuses[index]['qty'] = qty - 1;
                            }
                          }),
                          onIncrement: () => setModalState(() {
                            final qty = (b['qty'] as int?) ?? 1;
                            tempBonuses[index]['qty'] = qty + 1;
                          }),
                        );
                      },
                    );
                  }

                  Widget accessorySection() {
                    if (accAsync.isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppLayoutTokens.space16),
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      );
                    }
                    if (availableAcc.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppLayoutTokens.space16),
                          child: Text(
                            'Aksesoris tidak tersedia.',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }
                    if (filteredAcc.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppLayoutTokens.space16),
                          child: Text(
                            'Aksesoris tidak ditemukan.',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(AppLayoutTokens.space8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredAcc.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppLayoutTokens.space12),
                      itemBuilder: (context, index) {
                        final acc = filteredAcc[index];
                        final t = acc.tipe.trim();
                        final u = acc.ukuran.trim();
                        final accDisplayName = u.isEmpty ||
                                t.toLowerCase().contains(u.toLowerCase())
                            ? t
                            : '$t ($u)';

                        void addThisAccessory() {
                          setModalState(() {
                            tempBonuses.add({
                              'name': accDisplayName,
                              'qty': 1,
                              'pl': acc.pricelist,
                              'is_custom': true,
                              'item_num': acc.itemNum,
                            });
                            searchQuery = '';
                          });
                          FocusScope.of(context).unfocus();
                        }

                        return RepaintBoundary(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppLayoutTokens.radius10,
                              ),
                              boxShadow: [AppLayoutTokens.cardShadowSoft],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: addThisAccessory,
                                borderRadius: BorderRadius.circular(
                                  AppLayoutTokens.radius10,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppLayoutTokens.space16,
                                    vertical: AppLayoutTokens.space12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              accDisplayName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.textPrimary,
                                                    height: 1.25,
                                                  ),
                                            ),
                                            const SizedBox(
                                              height: AppLayoutTokens.space6,
                                            ),
                                            Text(
                                              'Rp ${AppFormatters.currencyIdrNoSymbol(acc.pricelist)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: AppColors
                                                        .textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        width: AppLayoutTokens.space12,
                                      ),
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: AppColors.accentLight,
                                          borderRadius: BorderRadius.circular(
                                            AppLayoutTokens.radius10,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppLayoutTokens.space10,
                                            vertical: AppLayoutTokens.space6,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.add_rounded,
                                                size: 18,
                                                color: AppColors.accent,
                                              ),
                                              const SizedBox(
                                                width: AppLayoutTokens.space4,
                                              ),
                                              Text(
                                                'Tambah',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors.accent,
                                                      fontSize: 12,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  final bonusHeader = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Daftar bonus',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                          ),
                          if (tempBonuses.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AppLayoutTokens.space8,
                              ),
                              child: Text(
                                '${tempBonuses.length} item',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: AppColors.textTertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      if (bonusListScrollHint && tempBonuses.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppLayoutTokens.space6,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.swipe_vertical_rounded,
                                size: 16,
                                color: AppColors.textTertiary.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                              const SizedBox(width: AppLayoutTokens.space6),
                              Expanded(
                                child: Text(
                                  'Geser daftar untuk melihat semua bonus',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textTertiary,
                                        fontSize: 11,
                                        height: 1.25,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );

                  final searchHeader = const FormFieldLabel(
                    'Cari & Tambah Aksesoris Pengganti',
                  );

                  final searchField = AppSearchField(
                    onChanged: (value) => setModalState(
                      () => searchQuery = value,
                    ),
                    hintText: 'Ketik nama aksesoris (cth: Pillow)…',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                    prefixIconSize: 20,
                    prefixIconColor: AppColors.textSecondary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    isDense: false,
                  );

                  Widget wrapBonusPanel(Widget child) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: _panelTint(context),
                        borderRadius:
                            BorderRadius.circular(AppLayoutTokens.radius16),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppLayoutTokens.radius16),
                        child: child,
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sesuaikan Bonus',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppLayoutTokens.space20),
                      bonusHeader,
                      const SizedBox(height: AppLayoutTokens.space10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: _kBonusPanelMaxHeight,
                        ),
                        child: wrapBonusPanel(bonusPanelBody()),
                      ),
                      const SizedBox(height: AppLayoutTokens.space20),
                      searchHeader,
                      const SizedBox(height: AppLayoutTokens.space10),
                      searchField,
                      const SizedBox(height: AppLayoutTokens.space12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppLayoutTokens.radius16,
                          ),
                          child: ColoredBox(
                            color: _panelTint(context),
                            child: accessorySection(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppLayoutTokens.space20),
                      ActionButtonBar(
                        height: 48,
                        borderRadius: 12,
                        primaryLabel: 'Simpan Perubahan',
                        primaryBackgroundColor: AppColors.accent,
                        primaryForegroundColor: AppColors.onPrimary,
                        primaryLabelStyle: const TextStyle(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        onPrimaryPressed: () {
                          onSave(List.from(tempBonuses));
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    ),
  );
}


class _BonusRowCard extends StatelessWidget {
  const _BonusRowCard({
    required this.bonus,
    required this.index,
    required this.onRemoveOrDecrement,
    required this.onIncrement,
  });

  final Map<String, dynamic> bonus;
  final int index;
  final VoidCallback onRemoveOrDecrement;
  final VoidCallback onIncrement;

  static const double _pillRadius = 20;

  @override
  Widget build(BuildContext context) {
    final pl = (bonus['pl'] as num?)?.toDouble();
    final qty = (bonus['qty'] as int?) ?? 1;
    final maxQty = bonus['max_qty'] as int?; // null = no limit

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayoutTokens.space14,
        vertical: AppLayoutTokens.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
        boxShadow: _kBonusCardShadow,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.card_giftcard_rounded,
            color: AppColors.accent,
            size: 22,
          ),
          const SizedBox(width: AppLayoutTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cleanBonusDisplayName(bonus['name']?.toString() ?? ''),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                ),
                if (pl != null && pl > 0) const SizedBox(height: AppLayoutTokens.space4),
                if (pl != null && pl > 0)
                  Text(
                    'Senilai Rp ${AppFormatters.currencyIdrNoSymbol(pl)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppLayoutTokens.space10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(_pillRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayoutTokens.space4,
                vertical: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: qty == 1 ? 'Hapus bonus' : 'Kurangi kuantitas',
                    icon: Icon(
                      qty == 1
                          ? Icons.delete_outline_rounded
                          : Icons.remove_rounded,
                      size: 18,
                      color: qty == 1 ? AppColors.error : AppColors.accent,
                    ),
                    onPressed: onRemoveOrDecrement,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                      maxWidth: 30,
                      maxHeight: 30,
                    ),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppLayoutTokens.space6,
                    ),
                    child: Text(
                      maxQty != null ? '$qty / $maxQty' : '$qty',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tambah kuantitas',
                    icon: Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: (maxQty != null && qty >= maxQty)
                          ? AppColors.textTertiary
                          : AppColors.accent,
                    ),
                    onPressed: (maxQty != null && qty >= maxQty) ? null : onIncrement,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                      maxWidth: 30,
                      maxHeight: 30,
                    ),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
