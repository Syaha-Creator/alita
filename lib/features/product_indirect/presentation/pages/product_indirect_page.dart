import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../navigation/navigation_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../cart/domain/entities/cart_entity.dart';
import '../../../cart/presentation/pages/draft_checkout_page.dart';
import '../../../cart/presentation/widgets/cart_badge.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart';
import '../../../product/presentation/bloc/product_state.dart';
import '../../../product/presentation/widgets/logout_button.dart';
import '../../../product/presentation/widgets/product_card.dart';
import '../../../product/presentation/widgets/product_page/product_page_widgets.dart';
import '../../../../core/widgets/whatsapp_dialog.dart';
import '../../data/models/store_model.dart';
import '../bloc/indirect_store_cubit.dart';
import '../widgets/indirect_product_dropdown.dart';

class ProductIndirectPage extends StatefulWidget {
  const ProductIndirectPage({super.key});

  @override
  State<ProductIndirectPage> createState() => _ProductIndirectPageState();
}

class _ProductIndirectPageState extends State<ProductIndirectPage>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _filterButtonKey = GlobalKey();
  double? _lastScrollOffset;

  late IndirectStoreCubit _storeCubit;

  /// Selected sub-brand untuk SA (Spring Air)
  String? _selectedSubBrand;

  /// Selected channel (Toko / Massindo Fair - Toko)
  String? _selectedChannel;

  /// Flag untuk track apakah sudah fetch stores pertama kali
  bool _hasInitiallyFetched = false;

  @override
  void initState() {
    super.initState();
    _storeCubit = IndirectStoreCubit();
    WidgetsBinding.instance.addObserver(this);
    context.read<ProductBloc>().add(InitializeDropdowns());

    // Fetch stores on init using user's address_number
    _fetchStoresOnInit();
  }

  /// Fetch stores saat halaman pertama kali dibuka
  Future<void> _fetchStoresOnInit() async {
    if (_hasInitiallyFetched) return;
    _hasInitiallyFetched = true;

    final addressNumber = await AuthService.getCurrentUserAddressNumber();
    if (addressNumber != null && addressNumber.isNotEmpty) {
      _storeCubit.fetchStoresBySalesCode(salesCode: addressNumber);
    }
  }

  /// Manual refresh stores - dipanggil dari tombol refresh
  /// Ini akan clear selection dan fetch ulang data toko
  Future<void> _manualRefreshStores() async {
    // Reset selection
    setState(() {
      _selectedSubBrand = null;
      _selectedChannel = null;
    });
    _storeCubit.clearSelectedStore();

    // Fetch fresh data
    final addressNumber = await AuthService.getCurrentUserAddressNumber();
    if (addressNumber != null && addressNumber.isNotEmpty) {
      _storeCubit.fetchStoresBySalesCode(salesCode: addressNumber);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _storeCubit.close();
    super.dispose();
  }

  /// Get area name dari branch code
  String? _getAreaNameFromBranch(String? branch) {
    if (branch == null) return null;
    return AreaCodes.getAreaName(branch);
  }

  /// Get effective area untuk store
  /// SA & TH menggunakan Nasional, lainnya dari branch
  String? _getEffectiveArea(StoreModel store) {
    if (store.usesNationalArea) {
      return 'Nasional';
    }
    return _getAreaNameFromBranch(store.branch);
  }

  /// Handle ketika store dipilih
  void _onStoreSelected(BuildContext context, StoreModel store) {
    _storeCubit.selectStore(store);

    // Reset sub-brand dan set default channel jika store berubah
    setState(() {
      _selectedSubBrand = null;
      _selectedChannel = 'Toko'; // Default channel
    });

    // Check if store has empty discounts
    if (store.storeDiscounts.isEmpty) {
      _showEmptyDiscountWarning(context, store);
      return;
    }

    // Jika store memerlukan sub-brand selection (SA), jangan fetch dulu
    if (store.needsSubBrandSelection) {
      // Tunggu user pilih sub-brand
      return;
    }

    // Untuk brand lain, langsung fetch products dengan default channel
    _fetchProductsForStore(context, store, store.brandName, _selectedChannel);
  }

  /// Show warning popup when store discounts are not configured
  void _showEmptyDiscountWarning(BuildContext context, StoreModel store) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 40,
            ),
          ),
          title: const Text(
            'Diskon Belum Tersedia',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Diskon untuk toko "${store.alphaName}" belum di-setting oleh sistem.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Silakan hubungi admin untuk mengatur diskon toko ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Clear the selected store
                  _storeCubit.clearSelectedStore();
                  setState(() {
                    _selectedSubBrand = null;
                    _selectedChannel = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Handle ketika sub-brand dipilih (untuk SA - Spring Air)
  void _onSubBrandSelected(BuildContext context, String? subBrand) {
    setState(() {
      _selectedSubBrand = subBrand;
    });

    if (subBrand == null) return;

    final storeState = _storeCubit.state;
    if (storeState is IndirectStoreLoaded && storeState.selectedStore != null) {
      _fetchProductsForStore(
        context,
        storeState.selectedStore!,
        subBrand,
        _selectedChannel,
      );
    }
  }

  /// Handle ketika channel dipilih
  void _onChannelChanged(BuildContext context, String? channel) {
    if (channel == null || channel == _selectedChannel) return;

    setState(() {
      _selectedChannel = channel;
    });

    // Fetch products dengan channel baru (tanpa redundansi)
    final storeState = _storeCubit.state;
    if (storeState is IndirectStoreLoaded && storeState.selectedStore != null) {
      final store = storeState.selectedStore!;
      final brandName = _selectedSubBrand ?? store.brandName;

      if (brandName != null) {
        _fetchProductsForStore(context, store, brandName, channel);
      }
    }
  }

  /// Fetch products untuk store dengan brand dan channel yang dipilih
  ///
  /// PENTING: Hanya mengirim FetchProductsByFilter, TIDAK mengirim
  /// UpdateSelectedBrand/Area/Channel karena akan menyebabkan race condition
  /// dan state corruption. FetchProductsByFilter sudah menyimpan nilai
  /// filter di state setelah fetch berhasil.
  void _fetchProductsForStore(
    BuildContext context,
    StoreModel store,
    String? brandName,
    String? channel,
  ) {
    if (brandName == null) return;

    // Use channel yang dipilih atau default ke 'Toko'
    final effectiveChannel = channel ?? 'Toko';

    // Get effective area (Nasional untuk SA/TH, branch untuk lainnya)
    final areaName = _getEffectiveArea(store);

    // Fetch products dengan parameter yang benar
    // TIDAK mengirim UpdateSelectedBrand/Area/Channel secara terpisah
    // karena akan menyebabkan race condition dimana UpdateSelectedChannel
    // mereset selectedBrand, dan seterusnya
    if (areaName != null) {
      context.read<ProductBloc>().add(
            FetchProductsByFilter(
              selectedArea: areaName,
              selectedChannel: effectiveChannel,
              selectedBrand: brandName,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double appBarHeight = kToolbarHeight;

    return BlocProvider.value(
      value: _storeCubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthInitial) {
                if (!mounted) return;
                NavigationService.navigateAndReplace(RoutePaths.login);
              }
              if (state is AuthSuccess) {
                context.read<ProductBloc>().add(InitializeDropdowns());
              }
            },
          ),
          BlocListener<ProductBloc, ProductState>(
            listener: (context, state) {
              if (state.showWhatsAppDialog &&
                  state.whatsAppBrand != null &&
                  state.whatsAppArea != null &&
                  state.whatsAppChannel != null) {
                showDialog(
                  context: context,
                  builder: (context) => WhatsAppDialog(
                    brand: state.whatsAppBrand!,
                    area: state.whatsAppArea!,
                    channel: state.whatsAppChannel!,
                  ),
                ).then((result) {
                  if (mounted && context.mounted) {
                    context.read<ProductBloc>().add(HideWhatsAppDialog());
                  }
                });
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: _buildAppBar(context, isDark),
          body: Padding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, productState) {
                if (productState is ProductLoading) {
                  return const LoadingState();
                }
                if (productState is ProductError) {
                  return EmptyState.error(
                    title: 'Error',
                    subtitle: productState.message,
                  );
                }
                if (productState.areaNotAvailable) {
                  return EmptyState.error(
                    icon: Icons.location_off,
                    title: "Area Belum Tersedia",
                    subtitle: "Area tersebut belum tersedia pricelist",
                    actionLabel: "Coba Lagi",
                    onAction: () {
                      context.read<ProductBloc>().add(ResetProductState());
                      context.read<ProductBloc>().add(InitializeDropdowns());
                    },
                  );
                }

                return BlocBuilder<IndirectStoreCubit, IndirectStoreState>(
                  builder: (context, storeState) {
                    return SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Indirect badge indicator
                          _buildModeBadge(theme),

                          // Dropdown section - Store first flow
                          IndirectProductDropdown(
                            isSetActive: productState.isSetActive,
                            onSetChanged: (value) {
                              context.read<ProductBloc>().add(ToggleSet(value));
                            },
                            // Stores - primary selection (dipilih pertama)
                            stores: storeState is IndirectStoreLoaded
                                ? storeState.stores
                                : [],
                            selectedStore: storeState is IndirectStoreLoaded
                                ? storeState.selectedStore
                                : null,
                            onStoreChanged: (store) {
                              if (store != null) {
                                _onStoreSelected(context, store);
                              } else {
                                _storeCubit.clearSelectedStore();
                                setState(() {
                                  _selectedSubBrand = null;
                                  _selectedChannel = null;
                                });
                              }
                            },
                            isLoadingStores: storeState is IndirectStoreLoading,
                            onRefreshStores: () => _manualRefreshStores(),
                            // Sub-brand selection (untuk SA - Spring Air)
                            selectedSubBrand: _selectedSubBrand,
                            onSubBrandChanged: (subBrand) {
                              _onSubBrandSelected(context, subBrand);
                            },
                            // Channel selection - user bisa pilih
                            availableChannels: productState.availableChannels,
                            selectedChannel: _selectedChannel,
                            onChannelChanged: (channel) {
                              _onChannelChanged(context, channel);
                            },
                            // Brand - sub-brand jika ada, atau brandName dari store
                            selectedBrand: _selectedSubBrand ??
                                (storeState is IndirectStoreLoaded
                                    ? storeState.selectedStore?.brandName
                                    : null),
                            // Area - Nasional untuk SA/TH, branch untuk lainnya
                            selectedArea: storeState is IndirectStoreLoaded &&
                                    storeState.selectedStore != null
                                ? _getEffectiveArea(storeState.selectedStore!)
                                : null,
                            // Product filters
                            kasurs: productState.availableKasurs,
                            selectedKasur:
                                productState.selectedKasur?.isEmpty ?? true
                                    ? null
                                    : productState.selectedKasur,
                            onKasurChanged: (value) {
                              if (value != null) {
                                context
                                    .read<ProductBloc>()
                                    .add(UpdateSelectedKasur(value));
                              }
                            },
                            divans: productState.availableDivans,
                            selectedDivan:
                                productState.selectedDivan?.isEmpty ?? true
                                    ? null
                                    : productState.selectedDivan,
                            onDivanChanged: (value) {
                              if (value != null) {
                                context
                                    .read<ProductBloc>()
                                    .add(UpdateSelectedDivan(value));
                              }
                            },
                            headboards: productState.availableHeadboards,
                            selectedHeadboard:
                                productState.selectedHeadboard?.isEmpty ?? true
                                    ? null
                                    : productState.selectedHeadboard,
                            onHeadboardChanged: (value) {
                              if (value != null) {
                                context
                                    .read<ProductBloc>()
                                    .add(UpdateSelectedHeadboard(value));
                              }
                            },
                            sorongs: productState.availableSorongs,
                            selectedSorong:
                                productState.selectedSorong?.isEmpty ?? true
                                    ? null
                                    : productState.selectedSorong,
                            onSorongChanged: (value) {
                              if (value != null) {
                                context
                                    .read<ProductBloc>()
                                    .add(UpdateSelectedSorong(value));
                              }
                            },
                            sizes: productState.availableSizes,
                            selectedSize:
                                productState.selectedSize?.isEmpty ?? true
                                    ? null
                                    : productState.selectedSize,
                            onSizeChanged: (value) {
                              if (value != null) {
                                context
                                    .read<ProductBloc>()
                                    .add(UpdateSelectedUkuran(value));
                              }
                            },
                            programs: productState.availablePrograms,
                            selectedProgram:
                                productState.selectedProgram?.isEmpty ?? true
                                    ? null
                                    : productState.selectedProgram,
                            isLoading: productState.isLoading,
                          ),

                          const SizedBox(height: AppPadding.p10),

                          // Filter buttons
                          FilterButtonsRow(
                            filterButtonKey: _filterButtonKey,
                            state: productState,
                            onApplyFilter: () => _applyFilters(
                              context,
                              productState,
                              appBarHeight,
                            ),
                            onResetFilter: () => _resetFilters(context),
                          ),

                          const SizedBox(height: AppPadding.p10),

                          // Content area
                          _buildContentArea(context, productState, storeState),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Fetch products for selected store
  Widget _buildModeBadge(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.p10),
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.p12,
        vertical: AppPadding.p6,
      ),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.business_rounded,
            size: 16,
            color: AppColors.purple,
          ),
          const SizedBox(width: AppPadding.p6),
          Text(
            'Mode: Indirect',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.purple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(
    BuildContext context,
    ProductState productState,
    IndirectStoreState storeState,
  ) {
    // Check if store is selected and get store data
    final selectedStore =
        storeState is IndirectStoreLoaded ? storeState.selectedStore : null;

    if (selectedStore == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: EmptyState(
          icon: Icons.store_outlined,
          title: "Pilih Toko",
          subtitle:
              "Silakan pilih Area, Channel, Brand, dan Toko untuk melihat produk.",
        ),
      );
    }

    // Get store discounts for price calculation
    final storeDiscounts = selectedStore.storeDiscounts;
    final storeDiscountDisplay = selectedStore.discountDisplayString;

    // Create IndirectStoreInfo for checkout
    final storeInfo = IndirectStoreInfo(
      alphaName: selectedStore.alphaName,
      address: selectedStore.address,
      longAddressNumber: selectedStore.longAddressNumber ?? '',
      storeDiscounts: storeDiscounts,
      storeDiscountDisplay: storeDiscountDisplay,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: productState.isFilterApplied
          ? (productState.filteredProducts.isNotEmpty
              ? SizedBox(
                  key: ValueKey(
                    // Use product IDs to create a unique key
                    // This ensures proper rebuild when products change
                    'products_${productState.filteredProducts.map((p) => p.id).join('_')}',
                  ),
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: ListView.builder(
                    itemCount: productState.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = productState.filteredProducts[index];
                      return ProductCard(
                        key: ValueKey('product_${product.id}_$index'),
                        product: product,
                        isIndirect: true,
                        storeDiscounts: storeDiscounts,
                        storeDiscountDisplay: storeDiscountDisplay,
                        storeInfo: storeInfo,
                      );
                    },
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyState.noData(
                    icon: Icons.search_off,
                    title: "Produk Tidak Ditemukan",
                    subtitle:
                        "Coba ubah kriteria filter Anda untuk menemukan produk yang lain.",
                  ),
                ))
          : const Padding(
              padding: EdgeInsets.only(top: 20),
              child: EmptyState(
                icon: Icons.filter_list,
                title: "Pilih Filter",
                subtitle:
                    "Silakan pilih kriteria filter dan klik tombol 'Terapkan Filter' untuk melihat produk.",
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.surfaceDark,
                    AppColors.surfaceDark.withValues(alpha: 0.95),
                  ]
                : [
                    AppColors.purple,
                    AppColors.purple.withValues(alpha: 0.85),
                  ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: ResponsiveHelper.getAppBarHeight(context),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? AppColors.textPrimaryDark : Colors.white,
        ),
        onPressed: () => context.go(RoutePaths.home),
        tooltip: 'Kembali',
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryDark.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.business_rounded,
              color: isDark ? AppColors.primaryDark : Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: AppPadding.p8),
          Text(
            'Indirect',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : Colors.white,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 15,
                    tablet: 17,
                    desktop: 19,
                  ),
                ),
          ),
        ],
      ),
      actions: [
        _buildAppBarAction(
          icon: Icons.approval_rounded,
          tooltip: 'Approval',
          isDark: isDark,
          onPressed: () => context.go(RoutePaths.approvalMonitoring),
        ),
        _buildAppBarAction(
          icon: Icons.folder_open_rounded,
          tooltip: 'Draft',
          isDark: isDark,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DraftCheckoutPage(),
            ),
          ),
        ),
        CartBadge(
          onTap: () => context.push(RoutePaths.cart),
          child: Icon(
            Icons.shopping_cart_rounded,
            size: 22,
            color: isDark ? AppColors.textPrimaryDark : Colors.white,
          ),
        ),
        LogoutButton(
          iconColor: isDark ? AppColors.textPrimaryDark : Colors.white,
        ),
      ],
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Icon(
          icon,
          color: isDark ? AppColors.textPrimaryDark : Colors.white,
          size: 22,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 20,
      ),
    );
  }

  Future<void> _applyFilters(
    BuildContext context,
    ProductState state,
    double appBarHeight,
  ) async {
    _lastScrollOffset = _scrollController.offset;

    // Gunakan nilai dari store selection, bukan dari ProductState dropdown
    final storeState = _storeCubit.state;
    String? areaToUse;
    String? brandToUse;
    String? channelToUse = _selectedChannel;

    if (storeState is IndirectStoreLoaded && storeState.selectedStore != null) {
      final store = storeState.selectedStore!;
      areaToUse = _getEffectiveArea(store);
      brandToUse = _selectedSubBrand ?? store.brandName;
    }

    context.read<ProductBloc>().add(
          ApplyFilters(
            selectedArea: areaToUse,
            selectedChannel: channelToUse,
            selectedBrand: brandToUse,
            selectedKasur: state.selectedKasur?.isEmpty ?? true
                ? null
                : state.selectedKasur,
            selectedDivan: state.selectedDivan?.isEmpty ?? true
                ? null
                : state.selectedDivan,
            selectedHeadboard: state.selectedHeadboard?.isEmpty ?? true
                ? null
                : state.selectedHeadboard,
            selectedSorong: state.selectedSorong?.isEmpty ?? true
                ? null
                : state.selectedSorong,
            selectedSize:
                state.selectedSize?.isEmpty ?? true ? null : state.selectedSize,
            selectedProgram: state.selectedProgram?.isEmpty ?? true
                ? null
                : state.selectedProgram,
          ),
        );

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final ctx = _filterButtonKey.currentContext;
    if (ctx != null && ctx.mounted) {
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null) {
        final position = box.localToGlobal(Offset.zero, ancestor: null).dy;
        final scrollOffset =
            _scrollController.offset + position - appBarHeight - 16;
        _scrollController.animateTo(
          scrollOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _resetFilters(BuildContext context) async {
    // Reset local state
    setState(() {
      _selectedSubBrand = null;
      _selectedChannel = null;
    });

    context.read<ProductBloc>().add(ResetFilters());
    _storeCubit.clearSelectedStore();

    // Re-fetch stores
    _fetchStoresOnInit();

    await Future.delayed(const Duration(milliseconds: 100));
    if (_lastScrollOffset != null) {
      _scrollController.animateTo(
        _lastScrollOffset!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }
}
