import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_choice_chip.dart';
import '../../data/models/item_lookup.dart';
import 'product_anchor_type.dart';

/// Product configurator: cascading selection of size, color/fabric, purchase type,
/// divan, headboard, and sorong components.
class ProductConfiguratorSection extends StatelessWidget {
  final AnchorType anchorType;
  final List<String> availableSizes;
  final List<String> availableDivans;
  final List<String> availableHeadboards;
  final List<String> availableSorongs;
  final String effectiveSize;
  final String effectiveDivan;
  final String effectiveHeadboard;
  final String effectiveSorong;
  final bool isKasurOnly;

  // Lookup data per component
  final List<ItemLookup> kasurLookups;
  final ItemLookup? effectiveKasurLookup;
  final ValueChanged<ItemLookup> onKasurLookupSelected;
  final List<ItemLookup> divanLookups;
  final ItemLookup? effectiveDivanLookup;
  final ValueChanged<ItemLookup> onDivanLookupSelected;
  final List<ItemLookup> headboardLookups;
  final ItemLookup? effectiveHeadboardLookup;
  final ValueChanged<ItemLookup> onHeadboardLookupSelected;
  final List<ItemLookup> sorongLookups;
  final ItemLookup? effectiveSorongLookup;
  final ValueChanged<ItemLookup> onSorongLookupSelected;

  // Custom fabric/color state per component
  final bool isKasurCustom;
  final bool isDivanCustom;
  final bool isHeadboardCustom;
  final bool isSorongCustom;
  final TextEditingController customKasurCtrl;
  final TextEditingController customDivanCtrl;
  final TextEditingController customHbCtrl;
  final TextEditingController customSorongCtrl;
  final VoidCallback onKasurCustomTap;
  final VoidCallback onDivanCustomTap;
  final VoidCallback onHeadboardCustomTap;
  final VoidCallback onSorongCustomTap;

  // Callbacks
  final ValueChanged<String> onSizeSelected;
  final ValueChanged<String> onDivanSelected;
  final ValueChanged<String> onHeadboardSelected;
  final ValueChanged<String> onSorongSelected;
  final VoidCallback onKasurOnlyTap;
  final VoidCallback onSetTap;

  /// Trigger setState in parent when custom text changes (for rebuild).
  final VoidCallback onCustomTextChanged;

  const ProductConfiguratorSection({
    super.key,
    required this.anchorType,
    required this.availableSizes,
    required this.availableDivans,
    required this.availableHeadboards,
    required this.availableSorongs,
    required this.effectiveSize,
    required this.effectiveDivan,
    required this.effectiveHeadboard,
    required this.effectiveSorong,
    required this.isKasurOnly,
    required this.kasurLookups,
    required this.effectiveKasurLookup,
    required this.onKasurLookupSelected,
    required this.divanLookups,
    required this.effectiveDivanLookup,
    required this.onDivanLookupSelected,
    required this.headboardLookups,
    required this.effectiveHeadboardLookup,
    required this.onHeadboardLookupSelected,
    required this.sorongLookups,
    required this.effectiveSorongLookup,
    required this.onSorongLookupSelected,
    required this.isKasurCustom,
    required this.isDivanCustom,
    required this.isHeadboardCustom,
    required this.isSorongCustom,
    required this.customKasurCtrl,
    required this.customDivanCtrl,
    required this.customHbCtrl,
    required this.customSorongCtrl,
    required this.onKasurCustomTap,
    required this.onDivanCustomTap,
    required this.onHeadboardCustomTap,
    required this.onSorongCustomTap,
    required this.onSizeSelected,
    required this.onDivanSelected,
    required this.onHeadboardSelected,
    required this.onSorongSelected,
    required this.onKasurOnlyTap,
    required this.onSetTap,
    required this.onCustomTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSetOptions;
    if (anchorType == AnchorType.kasur) {
      hasSetOptions = true;
    } else if (anchorType == AnchorType.divan) {
      hasSetOptions = availableHeadboards.any(
        (h) => !h.trim().toLowerCase().contains('tanpa'),
      );
    } else {
      hasSetOptions = false;
    }

    final availableDivansForSet = availableDivans
        .where((d) => !d.trim().toLowerCase().contains('tanpa'))
        .toList();

    final headboardsForSet = availableHeadboards
        .where((h) => !h.trim().toLowerCase().contains('tanpa'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Konfigurasi Produk',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        if (hasSetOptions) _buildTipePembelianRow(context),
        _buildHorizontalOptions(
          context,
          'Ukuran',
          availableSizes,
          effectiveSize,
          onSizeSelected,
        ),
        if (anchorType == AnchorType.kasur)
          _buildColorOptions(
            context,
            'Warna / Kain Kasur',
            kasurLookups,
            effectiveKasurLookup,
            onKasurLookupSelected,
            isCustomSelected: isKasurCustom,
            customController: customKasurCtrl,
            onCustomTap: onKasurCustomTap,
          )
        else if (anchorType == AnchorType.divan)
          _buildColorOptions(
            context,
            'Warna / Kain Divan',
            divanLookups,
            effectiveDivanLookup,
            onDivanLookupSelected,
            isCustomSelected: isDivanCustom,
            customController: customDivanCtrl,
            onCustomTap: onDivanCustomTap,
          )
        else if (anchorType == AnchorType.headboard)
          _buildColorOptions(
            context,
            'Warna / Kain Sandaran',
            headboardLookups,
            effectiveHeadboardLookup,
            onHeadboardLookupSelected,
            isCustomSelected: isHeadboardCustom,
            customController: customHbCtrl,
            onCustomTap: onHeadboardCustomTap,
          )
        else
          _buildColorOptions(
            context,
            'Warna / Kain Sorong',
            sorongLookups,
            effectiveSorongLookup,
            onSorongLookupSelected,
            isCustomSelected: isSorongCustom,
            customController: customSorongCtrl,
            onCustomTap: onSorongCustomTap,
          ),
        if (hasSetOptions && !isKasurOnly) ...[
          if (anchorType == AnchorType.kasur) ...[
            _buildHorizontalOptions(
              context,
              'Pilih Divan',
              availableDivansForSet,
              effectiveDivan,
              onDivanSelected,
            ),
            _buildColorOptions(
              context,
              'Warna / Kain Divan',
              divanLookups,
              effectiveDivanLookup,
              onDivanLookupSelected,
              isCustomSelected: isDivanCustom,
              customController: customDivanCtrl,
              onCustomTap: onDivanCustomTap,
            ),
          ],
          _buildHorizontalOptions(
            context,
            'Pilih Sandaran',
            headboardsForSet,
            effectiveHeadboard,
            onHeadboardSelected,
          ),
          if (anchorType != AnchorType.headboard &&
              !effectiveHeadboard.trim().toLowerCase().contains('tanpa'))
            _buildColorOptions(
              context,
              'Warna / Kain Sandaran',
              headboardLookups,
              effectiveHeadboardLookup,
              onHeadboardLookupSelected,
              isCustomSelected: isHeadboardCustom,
              customController: customHbCtrl,
              onCustomTap: onHeadboardCustomTap,
            ),
        ],
        if (!isKasurOnly && availableSorongs.length > 1) ...[
          _buildHorizontalOptions(
            context,
            'Sorong',
            availableSorongs,
            effectiveSorong,
            onSorongSelected,
          ),
          if (!effectiveSorong.trim().toLowerCase().contains('tanpa'))
            _buildColorOptions(
              context,
              'Warna / Kain Sorong',
              sorongLookups,
              effectiveSorongLookup,
              onSorongLookupSelected,
              isCustomSelected: isSorongCustom,
              customController: customSorongCtrl,
              onCustomTap: onSorongCustomTap,
            ),
        ],
      ],
    );
  }

  Widget _buildColorOptions(
    BuildContext context,
    String title,
    List<ItemLookup> options,
    ItemLookup? selected,
    void Function(ItemLookup) onSelect, {
    bool isCustomSelected = false,
    TextEditingController? customController,
    VoidCallback? onCustomTap,
  }) {
    if (options.isEmpty && customController == null) {
      return const SizedBox.shrink();
    }

    String lookupKey(ItemLookup lookup) {
      final tipe = lookup.tipe.trim().toLowerCase();
      final ukuran = lookup.ukuran.trim().toLowerCase();
      final itemNum = lookup.itemNum.trim().toLowerCase();
      final kain = (lookup.jenisKain ?? '').trim().toLowerCase();
      final warna = (lookup.warnaKain ?? '').trim().toLowerCase();
      return '$tipe|$ukuran|$itemNum|$kain|$warna';
    }

    final seen = <String>{};
    final uniqueOptions = options.where((lookup) {
      final key = lookupKey(lookup);
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            children: [
              ...uniqueOptions.map((lookup) {
                final isSelected = !isCustomSelected &&
                    selected != null &&
                    lookupKey(selected) == lookupKey(lookup);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: AppChoiceChip(
                    label: lookup.displayLabel,
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) onSelect(lookup);
                    },
                  ),
                );
              }),
              if (customController != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: AppChoiceChip(
                    label: 'Custom',
                    selected: isCustomSelected,
                    onSelected: (_) => onCustomTap?.call(),
                  ),
                ),
            ],
          ),
        ),
        if (isCustomSelected && customController != null) ...[
          const SizedBox(height: 8),
          TextField(
            controller: customController,
            onChanged: (_) => onCustomTextChanged(),
            decoration: InputDecoration(
              hintText: 'Tulis nama kain / warna custom…',
              hintStyle:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.accent,
                  width: 1.5,
                ),
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTipePembelianRow(BuildContext context) {
    final satuanLabel =
        anchorType == AnchorType.divan ? 'Divan Saja' : 'MattressOnly';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: TipePembelianCard(
              title: satuanLabel,
              isSelected: isKasurOnly,
              onTap: onKasurOnlyTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TipePembelianCard(
              title: 'Beli Set',
              isSelected: !isKasurOnly,
              onTap: onSetTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalOptions(
    BuildContext context,
    String title,
    List<String> options,
    String selected,
    void Function(String) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            children: options.map((option) {
              final isSelected = option == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: AppChoiceChip(
                  label: option,
                  selected: isSelected,
                  onSelected: (value) {
                    if (value) onSelect(option);
                  },
                  showCheckmark: true,
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Purchase type card: "MattressOnly" / "Beli Set" toggle.
///
/// Matches the Soft Selection pattern used by [AppChoiceChip].
class TipePembelianCard extends StatefulWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const TipePembelianCard({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<TipePembelianCard> createState() => _TipePembelianCardState();
}

class _TipePembelianCardState extends State<TipePembelianCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.isSelected;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) => _scaleCtrl.reverse(),
      onTapCancel: () => _scaleCtrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: sel ? AppColors.accentLight : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? AppColors.accent : AppColors.border,
              width: sel ? 1.5 : 1,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: sel ? AppColors.accent : AppColors.textSecondary,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
