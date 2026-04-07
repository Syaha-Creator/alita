import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/sales_mode.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/log.dart';
import '../../../../core/utils/area_utils.dart';
import '../../../../core/utils/store_display_utils.dart';
import '../../../../core/widgets/filter_pill.dart';
import '../../../../core/widgets/selection_bottom_sheet.dart';
import '../../../auth/logic/auth_provider.dart';
import '../../../indirect/data/models/assigned_store.dart';
import '../../../indirect/logic/indirect_session_provider.dart';
import '../../../indirect/logic/sales_mode_provider.dart';
import '../../logic/indirect_catalog_filter_utils.dart';
import '../../logic/product_provider.dart';

/// Format area name for display (Title Case, no uppercase).
String _toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

void _showSelectionBottomSheet({
  required BuildContext context,
  required String title,
  required List<String> items,
  required String? selectedItem,
  required String Function(String item) labelBuilder,
  required ValueChanged<String> onItemSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SelectionBottomSheet<String>(
      title: title,
      items: items,
      selectedItem: selectedItem,
      labelBuilder: labelBuilder,
      onItemSelected: onItemSelected,
    ),
  );
}

void _openIndirectStorePicker(BuildContext context, WidgetRef ref) {
  unawaited(_openIndirectStorePickerAsync(context, ref));
}

Future<void> _openIndirectStorePickerAsync(
  BuildContext context,
  WidgetRef ref,
) async {
  final session = ref.read(indirectSessionProvider);
  try {
    final stores = await ref.read(assignedStoresProvider.future);
    if (!context.mounted) return;
    if (stores.isEmpty) {
      AppFeedback.show(
        context,
        message:
            'Tidak ada toko assign untuk sales code Anda, sales code akun kosong, '
            'atau host indirect belum dikonfigurasi.',
        type: AppFeedbackType.warning,
        floating: true,
      );
      return;
    }
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => SelectionBottomSheet<AssignedStore>(
          title: 'Pilih toko',
          items: stores,
          selectedItem: session.selectedStore,
          labelBuilder: (s) => StoreDisplayUtils.assignedStoreRowLabel(
            alphaName: s.alphaName,
            catcode27: s.catcode27,
          ),
          onItemSelected: (s) {
            unawaited(
              ref.read(indirectSessionProvider.notifier).selectStore(s),
            );
          },
        ),
      ),
    );
  } catch (e, st) {
    Log.error(e, st, reason: 'assignedStoresProvider');
    if (context.mounted) {
      AppFeedback.show(
        context,
        message: 'Gagal memuat daftar toko. Periksa koneksi atau konfigurasi.',
        type: AppFeedbackType.error,
        floating: true,
      );
    }
  }
}

/// [indirectCatalogSyncTokenProvider] = `addressNumber|catcode27|tokoChannelsKey`.
/// True jika toko yang dipilih (alamat + kode katalog) sama — beda hanya daftar channel master.
bool _indirectCatalogStoreSliceUnchanged(String? prevToken, String nextToken) {
  if (prevToken == null) return false;
  final a = prevToken.split('|');
  final b = nextToken.split('|');
  if (a.length < 2 || b.length < 2) return prevToken == nextToken;
  return a[0] == b[0] && a[1] == b[1];
}

void _syncIndirectCatalogSelection(
  WidgetRef ref, {
  required bool realignBrandToStore,
}) {
  if (ref.read(salesModeProvider) != SalesMode.indirect) return;
  final store = ref.read(indirectSessionProvider).selectedStore;
  if (store == null) return;

  final tokoChannels = ref.read(catalogChannelsProvider);
  if (tokoChannels.isEmpty) return;

  final channelNotifier = ref.read(selectedChannelProvider.notifier);
  final currentCh = ref.read(selectedChannelProvider);

  if (currentCh == null || !tokoChannels.contains(currentCh)) {
    channelNotifier.state =
        IndirectCatalogFilterUtils.pickDefaultTokoChannel(tokoChannels);
  }

  final brands = ref.read(catalogBrandsProvider);
  _applyIndirectBrandChoice(
    ref,
    brands,
    realignBrandToStore: realignBrandToStore,
  );
}

void _syncIndirectBrandOnly(WidgetRef ref) {
  if (ref.read(salesModeProvider) != SalesMode.indirect) return;
  if (!ref.read(indirectSessionProvider).hasStore) return;
  final brands = ref.read(catalogBrandsProvider);
  _applyIndirectBrandChoice(ref, brands);
}

void _applyIndirectBrandChoice(
  WidgetRef ref,
  List<String> brands, {
  bool realignBrandToStore = false,
}) {
  final brandNotifier = ref.read(selectedBrandProvider.notifier);
  if (brands.isEmpty) {
    if (ref.read(salesModeProvider) == SalesMode.indirect &&
        ref.read(indirectSessionProvider).hasStore) {
      brandNotifier.state = null;
    }
    return;
  }

  final current = ref.read(selectedBrandProvider);
  final store = ref.read(indirectSessionProvider).selectedStore;
  final hasCatcode = store?.catcode27?.trim().isNotEmpty ?? false;

  // Toko punya catcode: brand harus dari daftar yang selaras; jangan biarkan Comforta
  // tetap terpilih setelah ganti ke toko SA, dll.
  // Ganti toko (alamat/catcode): selalu pakai brand utama daftar baru walau brand lama
  // masih ikut terbawa di master (daftar terlalu lebar).
  if (ref.read(salesModeProvider) == SalesMode.indirect && hasCatcode) {
    if (realignBrandToStore ||
        current == null ||
        !brands.contains(current)) {
      brandNotifier.state = brands.first;
    }
    return;
  }

  if (brands.length == 1) {
    brandNotifier.state = brands.first;
    return;
  }
  if (current != null && brands.contains(current)) return;
  brandNotifier.state = brands.first;
}

/// Cascading filter header: Area → Channel → Brand (horizontal quick dropdown pills)
class FilterHeaderWidget extends ConsumerWidget {
  const FilterHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIndirect = ref.watch(salesModeProvider) == SalesMode.indirect;
    final session = ref.watch(indirectSessionProvider);
    final hasIndirectStore = session.hasStore;

    // Prefetch + jaga [assignedStoresProvider] (autoDispose) tetap hidup di katalog indirect.
    if (isIndirect) {
      ref.watch(assignedStoresProvider);
    }

    // Sync: when areas load and selected is not in list, re-resolve default (fix Sumsel→Palembang etc)
    ref.listen<List<String>>(areasProvider, (prev, next) {
      if (ref.read(salesModeProvider) == SalesMode.indirect) return;
      if (next.isEmpty) return;
      final selected = ref.read(selectedAreaProvider);
      final inList = next.any((a) => a.toLowerCase() == selected.toLowerCase());
      if (!inList) {
        final auth = ref.read(authProvider);
        final userArea = auth.defaultArea.isNotEmpty ? auth.defaultArea : '';
        final resolved = AreaUtils.resolveDefaultArea(userArea, next);
        ref.read(selectedAreaProvider.notifier).state = resolved;
      }
    });

    ref.listen<String?>(indirectCatalogSyncTokenProvider, (prev, next) {
      if (next == null) return;
      final realignBrandToStore =
          !_indirectCatalogStoreSliceUnchanged(prev, next);
      _syncIndirectCatalogSelection(
        ref,
        realignBrandToStore: realignBrandToStore,
      );
    });

    ref.listen<String?>(selectedChannelProvider, (prev, next) {
      if (prev == next) return;
      _syncIndirectBrandOnly(ref);
    });

    final area = ref.watch(selectedAreaProvider);
    final selectedChannel = ref.watch(selectedChannelProvider);
    final selectedBrand = ref.watch(selectedBrandProvider);

    final areas = ref.watch(areasProvider);
    final channelSheetItems = isIndirect
        ? ref.watch(catalogChannelsProvider)
        : ref.watch(channelsProvider);
    final brandSheetItems = isIndirect && hasIndirectStore
        ? ref.watch(catalogBrandsProvider)
        : ref.watch(brandsProvider);

    final areaNotifier = ref.read(selectedAreaProvider.notifier);
    final channelNotifier = ref.read(selectedChannelProvider.notifier);
    final brandNotifier = ref.read(selectedBrandProvider.notifier);

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
        AppLayoutTokens.space16,
        AppLayoutTokens.space12,
        AppLayoutTokens.space16,
        AppLayoutTokens.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isIndirect) ...[
                  FilterPill(
                    icon: Icons.location_on,
                    text: _toTitleCase(area),
                    isActive: true,
                    onTap: () => _showSelectionBottomSheet(
                      context: context,
                      title: 'Pilih Area',
                      items: areas,
                      selectedItem: area,
                      labelBuilder: _toTitleCase,
                      onItemSelected: (value) {
                        areaNotifier.state = value;
                      },
                    ),
                  ),
                  const SizedBox(width: AppLayoutTokens.space8),
                ],
                if (isIndirect) ...[
                  FilterPill(
                    icon: Icons.store_mall_directory_outlined,
                    text: hasIndirectStore
                        ? StoreDisplayUtils.assignedStoreTitle(
                            session.selectedStore!.alphaName,
                          )
                        : 'Pilih toko',
                    isActive: hasIndirectStore,
                    onTap: () => _openIndirectStorePicker(context, ref),
                  ),
                  const SizedBox(width: AppLayoutTokens.space8),
                ],
                FilterPill(
                  icon: Icons.storefront,
                  text: selectedChannel ?? 'Channel',
                  isActive: selectedChannel != null,
                  onTap: () {
                    if (isIndirect && !hasIndirectStore) {
                      AppFeedback.plain(
                        context,
                        'Pilih toko di chip pertama terlebih dahulu.',
                        floating: true,
                      );
                      return;
                    }
                    if (isIndirect && channelSheetItems.isEmpty) {
                      AppFeedback.plain(
                        context,
                        'Tidak ada channel yang mengandung kata Toko.',
                        floating: true,
                      );
                      return;
                    }
                    _showSelectionBottomSheet(
                      context: context,
                      title: 'Pilih Channel',
                      items: channelSheetItems,
                      selectedItem: selectedChannel,
                      labelBuilder: (value) => value,
                      onItemSelected: (value) {
                        channelNotifier.state = value;
                        // Indirect + toko: jangan kosongkan brand; [_syncIndirectBrandOnly]
                        // menyamakan dengan daftar brand channel baru (tetap jika masih valid).
                        final indirect =
                            ref.read(salesModeProvider) == SalesMode.indirect;
                        final hasStore =
                            ref.read(indirectSessionProvider).hasStore;
                        if (!indirect || !hasStore) {
                          brandNotifier.state = null;
                        }
                      },
                    );
                  },
                ),
                const SizedBox(width: AppLayoutTokens.space8),
                FilterPill(
                  icon: Icons.sell_outlined,
                  text: selectedBrand ?? 'Brand',
                  isActive: selectedBrand != null,
                  onTap: () {
                    if (isIndirect && !hasIndirectStore) {
                      AppFeedback.plain(
                        context,
                        'Pilih toko di chip pertama terlebih dahulu.',
                        floating: true,
                      );
                      return;
                    }
                    if (selectedChannel == null) {
                      AppFeedback.plain(
                        context,
                        'Pilih Channel dulu',
                        floating: true,
                      );
                      return;
                    }
                    if (brandSheetItems.isEmpty) {
                      AppFeedback.plain(
                        context,
                        isIndirect && hasIndirectStore
                            ? 'Channel ini tidak punya brand yang selaras dengan toko. '
                                'Pilih channel lain.'
                            : 'Tidak ada brand untuk channel ini.',
                        floating: true,
                      );
                      return;
                    }
                    _showSelectionBottomSheet(
                      context: context,
                      title: 'Pilih Brand',
                      items: brandSheetItems,
                      selectedItem: selectedBrand,
                      labelBuilder: (value) => value,
                      onItemSelected: (value) {
                        brandNotifier.state = value;
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
