import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/empty_widget.dart';
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
                context.read<ProductBloc>().add(HideWhatsAppDialog());
              });
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          elevation: 0,
          toolbarHeight: ResponsiveHelper.getAppBarHeight(context),
          title: Text(
            'Product List',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.approval,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                size: ResponsiveHelper.getResponsiveIconSize(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 24,
                ),
              ),
              onPressed: () {
                context.go(RoutePaths.approvalMonitoring);
              },
              tooltip: 'Approval Monitoring',
            ),
            IconButton(
              icon: Icon(
                Icons.drafts,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                size: ResponsiveHelper.getResponsiveIconSize(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 24,
                ),
              ),
              tooltip: 'Draft Checkout',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DraftCheckoutPage()),
                );
              },
            ),
            CartBadge(
              onTap: () {
                context.push(RoutePaths.cart);
              },
              child: Icon(
                Icons.shopping_cart_outlined,
                size: ResponsiveHelper.getResponsiveIconSize(
                  context,
                  mobile: 24,
                  tablet: 26,
                  desktop: 28,
                ),
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            LogoutButton(),
          ],
        ),
        body: Padding(
          padding: ResponsiveHelper.getResponsivePadding(context),
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;

              if (state is ProductLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ProductError) {
                return Center(
                  child: Text(
                    state.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                );
              }
              if (state.areaNotAvailable) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 80,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Area Belum Tersedia",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Area tersebut belum tersedia pricelist",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ProductBloc>().add(ResetProductState());
                          context.read<ProductBloc>().add(
                                InitializeDropdowns(),
                              );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                        child: const Text("Coba Lagi"),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show area info
                    if (state.isUserAreaSet ||
                        (state.selectedBrand == "Spring Air" ||
                            state.selectedBrand == "Therapedic" ||
                            (state.selectedBrand
                                    ?.toLowerCase()
                                    .contains('spring air') ??
                                false)))
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (state.selectedBrand == "Spring Air" ||
                                  state.selectedBrand == "Therapedic" ||
                                  (state.selectedBrand
                                          ?.toLowerCase()
                                          .contains('spring air') ??
                                      false))
                              ? theme.colorScheme.primaryContainer
                                  .withOpacity(0.3)
                              : theme.colorScheme.secondaryContainer
                                  .withOpacity(0.3),
                          border: Border.all(
                            color: (state.selectedBrand == "Spring Air" ||
                                    state.selectedBrand == "Therapedic" ||
                                    (state.selectedBrand
                                            ?.toLowerCase()
                                            .contains('spring air') ??
                                        false))
                                ? theme.colorScheme.primary.withOpacity(0.3)
                                : theme.colorScheme.secondary.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: (state.selectedBrand == "Spring Air" ||
                                      state.selectedBrand == "Therapedic" ||
                                      (state.selectedBrand
                                              ?.toLowerCase()
                                              .contains('spring air') ??
                                          false))
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Area Anda",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          (state.selectedBrand ==
                                                      "Spring Air" ||
                                                  state.selectedBrand ==
                                                      "Therapedic" ||
                                                  (state
                                                          .selectedBrand
                                                          ?.toLowerCase()
                                                          .contains(
                                                              'spring air') ??
                                                      false))
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.secondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  // Show dropdown area for non-national brands
                                  if (state.selectedBrand != "Spring Air" &&
                                      state.selectedBrand != "Therapedic" &&
                                      !(state.selectedBrand
                                              ?.toLowerCase()
                                              .contains('spring air') ??
                                          false)) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButton<String>(
                                            key: ValueKey(state.selectedArea),
                                            value: _getValidSelectedArea(state),
                                            underline: Container(),
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                            items:
                                                state.availableAreas.isNotEmpty
                                                    ? state.availableAreas
                                                        .map((area) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: area,
                                                          child: Text(area),
                                                        );
                                                      }).toList()
                                                    : [
                                                        "Nasional",
                                                        "Jabodetabek",
                                                        "Bandung",
                                                        "Surabaya",
                                                        "Semarang",
                                                        "Yogyakarta",
                                                        "Solo",
                                                        "Malang",
                                                        "Denpasar",
                                                        "Medan",
                                                        "Palembang"
                                                      ].map((area) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: area,
                                                          child: Text(area),
                                                        );
                                                      }).toList(),
                                            onChanged: (String? newValue) {
                                              if (newValue != null) {
                                                context.read<ProductBloc>().add(
                                                      UpdateSelectedArea(
                                                          newValue),
                                                    );
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    Text(
                                      state.selectedArea ?? "Unknown",
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                  if (state.selectedBrand == "Spring Air" ||
                                      state.selectedBrand == "Therapedic" ||
                                      (state.selectedBrand
                                              ?.toLowerCase()
                                              .contains('spring air') ??
                                          false))
                                    Text(
                                      "Brand ${state.selectedBrand} menggunakan Area Nasional untuk pencarian",
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (state.selectedBrand == "Spring Air" ||
                                                state.selectedBrand ==
                                                    "Therapedic" ||
                                                (state.selectedBrand
                                                        ?.toLowerCase()
                                                        .contains(
                                                            'spring air') ??
                                                    false))
                                            ? theme.colorScheme.primaryContainer
                                                .withOpacity(0.5)
                                            : theme
                                                .colorScheme.secondaryContainer
                                                .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (state.selectedBrand == "Spring Air" ||
                                            state.selectedBrand ==
                                                "Therapedic" ||
                                            (state.selectedBrand
                                                    ?.toLowerCase()
                                                    .contains('spring air') ??
                                                false))
                                        ? "Nasional"
                                        : "Default",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          (state.selectedBrand ==
                                                      "Spring Air" ||
                                                  state.selectedBrand ==
                                                      "Therapedic" ||
                                                  (state.selectedBrand
                                                          ?.toLowerCase()
                                                          .contains(
                                                              'spring air') ??
                                                      false))
                                              ? theme.colorScheme
                                                  .onPrimaryContainer
                                              : theme.colorScheme
                                                  .onSecondaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                // Show reset area button for non-national brands
                                if (state.userSelectedArea != null &&
                                    state.selectedBrand != null &&
                                    state.selectedBrand != "Spring Air" &&
                                    state.selectedBrand != "Therapedic" &&
                                    !(state.selectedBrand
                                            ?.toLowerCase()
                                            .contains('spring air') ??
                                        false)) ...[
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: "Reset ke area default",
                                    child: GestureDetector(
                                      onTap: () {
                                        context.read<ProductBloc>().add(
                                              ResetUserSelectedArea(),
                                            );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme.errorContainer
                                              .withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.refresh,
                                          size: 16,
                                          color: theme
                                              .colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
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
                    Row(
                      key: _filterButtonKey,
                      children: [
                        Expanded(
                          child: Tooltip(
                            message: state.isUserAreaSet
                                ? "Terapkan filter yang dipilih untuk melihat produk"
                                : "Tampilkan produk berdasarkan filter yang dipilih",
                            child: ElevatedButton.icon(
                              onPressed: (state.selectedKasur != null &&
                                      state.selectedKasur!.isNotEmpty)
                                  ? () async {
                                      // Simpan posisi scroll sebelum filter diterapkan
                                      _lastScrollOffset =
                                          _scrollController.offset;
                                      String? areaToUse =
                                          state.selectedArea?.isEmpty ?? true
                                              ? null
                                              : state.selectedArea;
                                      if (state.selectedBrand == "Spring Air" ||
                                          state.selectedBrand == "Therapedic") {
                                        areaToUse = "Nasional";
                                      }
                                      context.read<ProductBloc>().add(
                                            ApplyFilters(
                                              selectedArea: areaToUse,
                                              selectedChannel: state
                                                          .selectedChannel
                                                          ?.isEmpty ??
                                                      true
                                                  ? null
                                                  : state.selectedChannel,
                                              selectedBrand: state.selectedBrand
                                                          ?.isEmpty ??
                                                      true
                                                  ? null
                                                  : state.selectedBrand,
                                              selectedKasur: state.selectedKasur
                                                          ?.isEmpty ??
                                                      true
                                                  ? null
                                                  : state.selectedKasur,
                                              selectedDivan: state.selectedDivan
                                                          ?.isEmpty ??
                                                      true
                                                  ? null
                                                  : state.selectedDivan,
                                              selectedHeadboard: state
                                                          .selectedHeadboard
                                                          ?.isEmpty ??
                                                      true
                                                  ? null
                                                  : state.selectedHeadboard,
                                              selectedSorong: state
                                                          .selectedSorong
                                                          ?.isEmpty ??
                                                      true
                                                  ? null
                                                  : state.selectedSorong,
                                              selectedSize:
                                                  state.selectedSize?.isEmpty ??
                                                          true
                                                      ? null
                                                      : state.selectedSize,
                                              selectedProgram: state
                                                          .selectedProgram
                                                          ?.isEmpty ??
                                                      true
                                                  ? null
                                                  : state.selectedProgram,
                                            ),
                                          );
                                      // Scroll ke tombol filter & reset, pastikan tepat di bawah AppBar
                                      await Future.delayed(
                                        const Duration(milliseconds: 100),
                                      );
                                      final ctx =
                                          _filterButtonKey.currentContext;
                                      if (ctx != null) {
                                        final box = ctx.findRenderObject()
                                            as RenderBox?;
                                        if (box != null) {
                                          final position = box
                                              .localToGlobal(
                                                Offset.zero,
                                                ancestor: null,
                                              )
                                              .dy;
                                          final scrollOffset =
                                              _scrollController.offset +
                                                  position -
                                                  appBarHeight -
                                                  16; // 16 = padding
                                          _scrollController.animateTo(
                                            scrollOffset,
                                            duration: const Duration(
                                              milliseconds: 400,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      }
                                    }
                                  : null,
                              icon: Icon(
                                state.isUserAreaSet
                                    ? Icons.filter_alt
                                    : Icons.search,
                                size: ResponsiveHelper.getResponsiveIconSize(
                                  context,
                                  mobile: 16,
                                  tablet: 17,
                                  desktop: 18,
                                ),
                              ),
                              label: state.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      state.isUserAreaSet
                                          ? "Terapkan Filter"
                                          : "Tampilkan Produk",
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper
                                            .getResponsiveFontSize(
                                          context,
                                          mobile: 14,
                                          tablet: 15,
                                          desktop: 16,
                                        ),
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (state.selectedBrand != null &&
                                        state.selectedBrand!.isNotEmpty)
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      ResponsiveHelper.getResponsiveSpacing(
                                    context,
                                    mobile: 12,
                                    tablet: 14,
                                    desktop: 16,
                                  ),
                                  vertical:
                                      ResponsiveHelper.getResponsiveSpacing(
                                    context,
                                    mobile: 10,
                                    tablet: 12,
                                    desktop: 14,
                                  ),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ),
                        if ((state.selectedChannel != null &&
                                state.selectedChannel!.isNotEmpty) ||
                            state.isFilterApplied) ...[
                          const SizedBox(width: 12),
                          Tooltip(
                            message: "Reset semua filter yang dipilih",
                            child: ElevatedButton.icon(
                              onPressed: state.isLoading
                                  ? null
                                  : () async {
                                      context.read<ProductBloc>().add(
                                            ResetFilters(),
                                          );
                                      // Scroll kembali ke posisi sebelum filter diterapkan
                                      await Future.delayed(
                                        const Duration(milliseconds: 100),
                                      );
                                      if (_lastScrollOffset != null) {
                                        _scrollController.animateTo(
                                          _lastScrollOffset!,
                                          duration: const Duration(
                                            milliseconds: 400,
                                          ),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                              icon: Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: ResponsiveHelper.getResponsiveIconSize(
                                  context,
                                  mobile: 16,
                                  tablet: 17,
                                  desktop: 18,
                                ),
                              ),
                              label: Text(
                                "Reset",
                                style: TextStyle(
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                    context,
                                    mobile: 14,
                                    tablet: 15,
                                    desktop: 16,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: state.isLoading
                                    ? Colors.grey.shade400
                                    : Colors.red.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      ResponsiveHelper.getResponsiveSpacing(
                                    context,
                                    mobile: 12,
                                    tablet: 14,
                                    desktop: 16,
                                  ),
                                  vertical:
                                      ResponsiveHelper.getResponsiveSpacing(
                                    context,
                                    mobile: 10,
                                    tablet: 12,
                                    desktop: 14,
                                  ),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppPadding.p10),
                    // Show filter buttons
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: state.isFilterApplied
                            ? (state.filteredProducts.isNotEmpty
                                ? ListView.builder(
                                    key: ValueKey(
                                      state.filteredProducts.length,
                                    ),
                                    itemCount: state.filteredProducts.length,
                                    itemBuilder: (context, index) {
                                      return ProductCard(
                                        product: state.filteredProducts[index],
                                      );
                                    },
                                  )
                                : const EmptyStateWidget(
                                    icon: Icons.search_off,
                                    title: "Produk Tidak Ditemukan",
                                    message:
                                        "Coba ubah kriteria filter Anda untuk menemukan produk yang lain.",
                                  ))
                            : const EmptyStateWidget(
                                icon: Icons.filter_list,
                                title: "Pilih Filter",
                                message:
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

  String _getValidSelectedArea(ProductState state) {
    if (state.selectedArea != null && state.selectedArea!.isNotEmpty) {
      return state.selectedArea!;
    }
    return "Nasional";
  }
}
