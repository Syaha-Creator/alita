import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../navigation/navigation_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../cart/presentation/pages/draft_checkout_page.dart';
import '../../../cart/presentation/widgets/cart_badge.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../widgets/logout_button.dart';
import '../widgets/product_card.dart';
import '../widgets/product_dropdown.dart';
import '../widgets/product_page/product_page_widgets.dart';
import '../../../../core/widgets/whatsapp_dialog.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _filterButtonKey = GlobalKey();
  double? _lastScrollOffset;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(InitializeDropdowns());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double appBarHeight = kToolbarHeight;
    return MultiBlocListener(
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
                // Hide dialog after user interaction
                if (mounted && context.mounted) {
                  context.read<ProductBloc>().add(HideWhatsAppDialog());
                }
              });
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
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
                        AppColors.primaryLight,
                        AppColors.primaryLight.withValues(alpha: 0.85),
                      ],
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: ResponsiveHelper.getAppBarHeight(context),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryDark.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: isDark ? AppColors.primaryDark : Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppPadding.p10),
              Text(
                'Product List',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : Colors.white,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
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
                MaterialPageRoute(builder: (context) => const DraftCheckoutPage()),
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
        ),
        body: Padding(
          padding: ResponsiveHelper.getResponsivePadding(context),
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is ProductLoading) {
                return const LoadingState();
              }
              if (state is ProductError) {
                return EmptyState.error(
                  title: 'Error',
                  subtitle: state.message,
                );
              }
              if (state.areaNotAvailable) {
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

              return SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show area info
                    if (state.isUserAreaSet ||
                        isNationalBrand(state.selectedBrand))
                      AreaInfoSection(
                        state: state,
                        getValidSelectedArea: _getValidSelectedArea,
                      ),
                    ProductDropdown(
                      isSetActive: state.isSetActive,
                      onSetChanged: (value) {
                        context.read<ProductBloc>().add(ToggleSet(value));
                      },
                      selectedArea: state.selectedArea,
                      onAreaChanged: (value) {
                        if (value != null) {
                          context.read<ProductBloc>().add(
                                UpdateSelectedArea(value),
                              );
                        }
                      },
                      isUserAreaSet: state.isUserAreaSet,
                      channels: state.availableChannels,
                      selectedChannel: state.selectedChannel?.isEmpty ?? true
                          ? null
                          : state.selectedChannel,
                      onChannelChanged: (value) {
                        if (value != null) {
                          context.read<ProductBloc>().add(
                                UpdateSelectedChannel(value),
                              );
                        }
                      },
                      availableChannelModels: state.availableChannelModels,
                      brands: state.availableBrands,
                      selectedBrand: state.selectedBrand?.isEmpty ?? true
                          ? null
                          : state.selectedBrand,
                      onBrandChanged: (value) {
                        if (value != null) {
                          context.read<ProductBloc>().add(
                                UpdateSelectedBrand(value),
                              );
                        }
                      },
                      availableBrandModels:
                          state.availableBrandModels, // Only API data
                      kasurs: state.availableKasurs,
                      selectedKasur: state.selectedKasur?.isEmpty ?? true
                          ? null
                          : state.selectedKasur,
                      onKasurChanged: (value) {
                        if (value != null) {
                          context.read<ProductBloc>().add(
                                UpdateSelectedKasur(value),
                              );
                        }
                      },
                      divans: state.availableDivans,
                      selectedDivan: state.selectedDivan?.isEmpty ?? true
                          ? null
                          : state.selectedDivan,
                      onDivanChanged: (value) {
                        if (value != null) {
                          context.read<ProductBloc>().add(
                                UpdateSelectedDivan(value),
                              );
                        }
                      },
                      headboards: state.availableHeadboards,
                      selectedHeadboard:
                          state.selectedHeadboard?.isEmpty ?? true
                              ? null
                              : state.selectedHeadboard,
                      onHeadboardChanged: (value) {
                        if (value != null) {
                          context.read<ProductBloc>().add(
                                UpdateSelectedHeadboard(value),
                              );
                        }
                      },
                      sorongs: state.availableSorongs,
                      selectedSorong: state.selectedSorong?.isEmpty ?? true
                          ? null
                          : state.selectedSorong,
                      onSorongChanged: (value) {
                        if (value != null) {
                          context.read<ProductBloc>().add(
                                UpdateSelectedSorong(value),
                              );
                        }
                      },
                      sizes: state.availableSizes,
                      selectedSize: state.selectedSize?.isEmpty ?? true
                          ? null
                          : state.selectedSize,
                      onSizeChanged: (value) {
                        if (value != null) {
                          context.read<ProductBloc>().add(
                                UpdateSelectedUkuran(value),
                              );
                        }
                      },
                      programs: state.availablePrograms,
                      selectedProgram: state.selectedProgram?.isEmpty ?? true
                          ? null
                          : state.selectedProgram,
                      isLoading: state.isLoading,
                    ),
                    const SizedBox(height: AppPadding.p10),
                    // Show filter buttons
                    FilterButtonsRow(
                      filterButtonKey: _filterButtonKey,
                      state: state,
                      onApplyFilter: () =>
                          _applyFilters(context, state, appBarHeight),
                      onResetFilter: () => _resetFilters(context),
                    ),
                    const SizedBox(height: AppPadding.p10),
                    // Content area
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: state.isFilterApplied
                          ? (state.filteredProducts.isNotEmpty
                              ? SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  child: ListView.builder(
                                    key: ValueKey(
                                      state.filteredProducts.length,
                                    ),
                                    itemCount: state.filteredProducts.length,
                                    itemBuilder: (context, index) {
                                      final product =
                                          state.filteredProducts[index];
                                      return ProductCard(
                                        key: ValueKey('product_${product.id}'),
                                        product: product,
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
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
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

  String _getValidSelectedArea(ProductState state) {
    if (state.selectedArea != null && state.selectedArea!.isNotEmpty) {
      return state.selectedArea!;
    }
    return "Nasional";
  }

  /// Apply filters and scroll to filter button
  Future<void> _applyFilters(
      BuildContext context, ProductState state, double appBarHeight) async {
    // Save scroll position before applying filter
    _lastScrollOffset = _scrollController.offset;

    // Use helper to get effective area
    String? areaToUse = getEffectiveArea(
      state.selectedArea?.isEmpty ?? true ? null : state.selectedArea,
      state.selectedBrand,
    );

    context.read<ProductBloc>().add(
          ApplyFilters(
            selectedArea: areaToUse,
            selectedChannel: state.selectedChannel?.isEmpty ?? true
                ? null
                : state.selectedChannel,
            selectedBrand: state.selectedBrand?.isEmpty ?? true
                ? null
                : state.selectedBrand,
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

    // Scroll to filter button, right below AppBar
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

  /// Reset filters and scroll back to previous position
  Future<void> _resetFilters(BuildContext context) async {
    context.read<ProductBloc>().add(ResetFilters());

    // Scroll back to previous position
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
