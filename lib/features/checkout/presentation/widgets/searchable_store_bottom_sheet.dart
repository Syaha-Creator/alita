import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/network_image_view.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../data/models/store_model.dart';
import '../../logic/store_provider.dart';

/// Baris teks untuk satu item toko: jika [StoreModel.name] kosong, baris nama disembunyikan.
List<Widget> _storeTileTextRows(StoreModel store) {
  const primaryStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  const secondaryStyle = TextStyle(
    fontSize: 11,
    color: AppColors.textSecondary,
  );
  const tertiaryStyle = TextStyle(
    fontSize: 10,
    color: AppColors.textTertiary,
    fontWeight: FontWeight.w500,
  );

  final name = store.name.trim();
  final loc = store.displayLocLine;
  final categoryLine = store.displayCategoryTitleCase;

  if (name.isNotEmpty) {
    final out = <Widget>[
      Text(
        store.displayNameTitleCase,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: primaryStyle,
      ),
    ];
    if (loc.isNotEmpty) {
      out.add(const SizedBox(height: 2));
      out.add(
        Text(
          loc,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: secondaryStyle,
        ),
      );
    }
    if (categoryLine.isNotEmpty) {
      out.add(const SizedBox(height: 2));
      out.add(
        Text(
          categoryLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tertiaryStyle,
        ),
      );
    }
    return out;
  }

  final primary = store.displayLabelOrFallback;
  final out = <Widget>[
    Text(
      primary,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: primaryStyle,
    ),
  ];
  if (categoryLine.isNotEmpty && primary != categoryLine) {
    out.add(const SizedBox(height: 2));
    out.add(
      Text(
        categoryLine,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: tertiaryStyle,
      ),
    );
  }
  return out;
}

/// Full-screen-ish bottom sheet for picking a store.
///
/// Returns the selected [StoreModel] via `Navigator.pop`.
/// Usage:
/// ```dart
/// final store = await SearchableStoreBottomSheet.show(context);
/// ```
class SearchableStoreBottomSheet extends ConsumerStatefulWidget {
  const SearchableStoreBottomSheet({super.key});

  /// Convenience launcher — returns the selected store or null.
  static Future<StoreModel?> show(BuildContext context) {
    return showModalBottomSheet<StoreModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SearchableStoreBottomSheet(),
    );
  }

  @override
  ConsumerState<SearchableStoreBottomSheet> createState() =>
      _SearchableStoreBottomSheetState();
}

class _SearchableStoreBottomSheetState
    extends ConsumerState<SearchableStoreBottomSheet> {
  String _query = '';

  List<StoreModel> _filter(List<StoreModel> stores) {
    final trimmed = _query.trim();
    if (trimmed.isEmpty) return stores;
    final q = trimmed.toLowerCase();
    return stores.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.city.toLowerCase().contains(q) ||
          s.area.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final storeAsync = ref.watch(storeListProvider);

    return SizedBox(
      height: screenHeight * 0.82,
      child: SheetScaffold(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayoutTokens.space16,
                vertical: AppLayoutTokens.space8,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pilih Lokasi Toko',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    color: AppColors.textSecondary,
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Sticky search bar ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayoutTokens.space16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius:
                      BorderRadius.circular(AppLayoutTokens.radius10),
                ),
                child: AppSearchField(
                  hintText: 'Cari nama toko, kota, atau area...',
                  autofocus: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  onChanged: (v) => setState(() => _query = v),
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  prefixIconSize: 20,
                  clearIconSize: 18,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppLayoutTokens.space12,
                    vertical: AppLayoutTokens.space12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppLayoutTokens.space10),
            const Divider(height: 1, color: AppColors.divider),

            // ── List content ───────────────────────────────────
            Expanded(
              child: storeAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor:
                        AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
                error: (error, _) => ErrorStateView(
                  title: 'Gagal Memuat Toko',
                  message: error.toString(),
                  onRetry: () =>
                      ref.invalidate(storeListProvider),
                ),
                data: (stores) {
                  final filtered = _filter(stores);

                  if (filtered.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.storefront_outlined,
                      title: _query.isEmpty
                          ? 'Belum ada data toko'
                          : 'Tidak ditemukan',
                      subtitle: _query.isEmpty
                          ? 'Data toko belum tersedia'
                          : 'Coba kata kunci lain',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppLayoutTokens.space8,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 72,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, index) {
                      final store = filtered[index];
                      return _StoreTile(
                        store: store,
                        onTap: () => Navigator.pop(context, store),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single store row ──────────────────────────────────────────────

class _StoreTile extends StatelessWidget {
  const _StoreTile({required this.store, required this.onTap});

  final StoreModel store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppLayoutTokens.space16,
          vertical: AppLayoutTokens.space10,
        ),
        child: Row(
          children: [
            // ── Leading image / icon ──
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppLayoutTokens.radius8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: store.image.isNotEmpty
                    ? NetworkImageView(
                        imageUrl: store.image,
                        width: 44,
                        height: 44,
                        memCacheWidth: 88,
                        semanticLabel: store.displayLabelOrFallback,
                      )
                    : Container(
                        color: AppColors.surfaceLight,
                        child: const Icon(
                          Icons.storefront_rounded,
                          size: 22,
                          color: AppColors.textTertiary,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: AppLayoutTokens.space12),

            // ── Text content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _storeTileTextRows(store),
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
