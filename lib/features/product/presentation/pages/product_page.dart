import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../../navigation/navigation_service.dart';
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
import '../../../../theme/app_colors.dart';

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
          title: const Text('Product List'),
          actions: [
            IconButton(
              icon: const Icon(Icons.approval),
              onPressed: () {
                context.go(RoutePaths.approvalMonitoring);
              },
              tooltip: 'Approval Monitoring',
            ),
            IconButton(
              icon: Icon(Icons.drafts),
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
                size: 28,
              ),
            ),
            LogoutButton(),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppPadding.p16),
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
                    style: TextStyle(
                      color: isDark ? AppColors.error : Colors.red,
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
                        color: isDark ? AppColors.warning : Colors.orange[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Area Belum Tersedia",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? AppColors.warning : Colors.orange[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Area tersebut belum tersedia pricelist",
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ProductBloc>().add(ResetProductState());
                          context
                              .read<ProductBloc>()
                              .add(InitializeDropdowns());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? AppColors.warning : Colors.orange[600],
                          foregroundColor: Colors.white,
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
                        (state.selectedBrand == BrandEnum.springair.value ||
                            state.selectedBrand == BrandEnum.therapedic.value))
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (state.selectedBrand ==
                                      BrandEnum.springair.value ||
                                  state.selectedBrand ==
                                      BrandEnum.therapedic.value)
                              ? (theme.brightness == Brightness.dark
                                  ? AppColors.accentDark.withOpacity(0.1)
                                  : Colors.blue[50])
                              : (theme.brightness == Brightness.dark
                                  ? AppColors.success.withOpacity(0.1)
                                  : Colors.green[50]),
                          border: Border.all(
                            color: (state.selectedBrand ==
                                        BrandEnum.springair.value ||
                                    state.selectedBrand ==
                                        BrandEnum.therapedic.value)
                                ? (theme.brightness == Brightness.dark
                                    ? AppColors.accentDark.withOpacity(0.3)
                                    : Colors.blue[200]!)
                                : (theme.brightness == Brightness.dark
                                    ? AppColors.success.withOpacity(0.3)
                                    : Colors.green[200]!),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: (state.selectedBrand ==
                                          BrandEnum.springair.value ||
                                      state.selectedBrand ==
                                          BrandEnum.therapedic.value)
                                  ? (isDark
                                      ? AppColors.accentDark
                                      : Colors.blue[600])
                                  : (isDark
                                      ? AppColors.success
                                      : Colors.green[600]),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Area Anda",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: (state.selectedBrand ==
                                                  BrandEnum.springair.value ||
                                              state.selectedBrand ==
                                                  BrandEnum.therapedic.value)
                                          ? (isDark
                                              ? AppColors.accentDark
                                              : Colors.blue[600])
                                          : (isDark
                                              ? AppColors.success
                                              : Colors.green[600]),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  // Show dropdown area for non-national brands
                                  if (state.selectedBrand != null &&
                                      state.selectedBrand !=
                                          BrandEnum.springair.value &&
                                      state.selectedBrand !=
                                          BrandEnum.therapedic.value) ...[
                                    DropdownButton<String>(
                                      key: ValueKey(state.selectedArea),
                                      value: state.selectedArea,
                                      underline: Container(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                      items: AreaEnum.values.map((area) {
                                        return DropdownMenuItem<String>(
                                          value: area.value,
                                          child: Text(area.value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          context.read<ProductBloc>().add(
                                              UpdateSelectedArea(newValue));
                                        }
                                      },
                                    ),
                                  ] else ...[
                                    Text(
                                      state.selectedArea ?? "Unknown",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ],
                                  if (state.selectedBrand ==
                                          BrandEnum.springair.value ||
                                      state.selectedBrand ==
                                          BrandEnum.therapedic.value)
                                    Text(
                                      "Brand ${state.selectedBrand} menggunakan Area Nasional untuk pencarian",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.accentDark
                                            : Colors.blue[600],
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
                                    color: (state.selectedBrand ==
                                                BrandEnum.springair.value ||
                                            state.selectedBrand ==
                                                BrandEnum.therapedic.value)
                                        ? (isDark
                                            ? AppColors.accentDark
                                                .withOpacity(0.2)
                                            : Colors.blue[100])
                                        : (isDark
                                            ? AppColors.success.withOpacity(0.2)
                                            : Colors.green[100]),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (state.selectedBrand ==
                                                BrandEnum.springair.value ||
                                            state.selectedBrand ==
                                                BrandEnum.therapedic.value)
                                        ? "Nasional"
                                        : "Default",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: (state.selectedBrand ==
                                                  BrandEnum.springair.value ||
                                              state.selectedBrand ==
                                                  BrandEnum.therapedic.value)
                                          ? (isDark
                                              ? AppColors.accentDark
                                              : Colors.blue[700])
                                          : (isDark
                                              ? AppColors.success
                                              : Colors.green[700]),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                // Show reset area button for non-national brands
                                if (state.userSelectedArea != null &&
                                    state.selectedBrand != null &&
                                    state.selectedBrand !=
                                        BrandEnum.springair.value &&
                                    state.selectedBrand !=
                                        BrandEnum.therapedic.value) ...[
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: "Reset ke area default",
                                    child: GestureDetector(
                                      onTap: () {
                                        context
                                            .read<ProductBloc>()
                                            .add(ResetUserSelectedArea());
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[100],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.refresh,
                                          size: 16,
                                          color: Colors.orange[700],
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
                          context
                              .read<ProductBloc>()
                              .add(UpdateSelectedArea(value));
                        }
                      },
                      isUserAreaSet: state.isUserAreaSet,
                      channels: ChannelEnum.values.map((e) => e.value).toList(),
                      selectedChannel: state.selectedChannel?.isEmpty ?? true
                          ? null
                          : state.selectedChannel,
                      onChannelChanged: (value) {
                        if (value != null) {
                          context
                              .read<ProductBloc>()
                              .add(UpdateSelectedChannel(value));
                        }
                      },
                      availableChannelEnums: ChannelEnum.values,
                      brands: BrandEnum.values.map((e) => e.value).toList(),
                      selectedBrand: state.selectedBrand?.isEmpty ?? true
                          ? null
                          : state.selectedBrand,
                      onBrandChanged: (value) {
                        if (value != null) {
                          context
                              .read<ProductBloc>()
                              .add(UpdateSelectedBrand(value));
                        }
                      },
                      availableBrandEnums: BrandEnum.values,
                      kasurs: state.availableKasurs,
                      selectedKasur: state.selectedKasur?.isEmpty ?? true
                          ? null
                          : state.selectedKasur,
                      onKasurChanged: (value) {
                        if (value != null) {
                          context
                              .read<ProductBloc>()
                              .add(UpdateSelectedKasur(value));
                        }
                      },
                      divans: state.availableDivans,
                      selectedDivan: state.selectedDivan?.isEmpty ?? true
                          ? null
                          : state.selectedDivan,
                      onDivanChanged: (value) {
                        if (value != null) {
                          context
                              .read<ProductBloc>()
                              .add(UpdateSelectedDivan(value));
                        }
                      },
                      headboards: state.availableHeadboards,
                      selectedHeadboard:
                          state.selectedHeadboard?.isEmpty ?? true
                              ? null
                              : state.selectedHeadboard,
                      onHeadboardChanged: (value) {
                        if (value != null) {
                          context
                              .read<ProductBloc>()
                              .add(UpdateSelectedHeadboard(value));
                        }
                      },
                      sorongs: state.availableSorongs,
                      selectedSorong: state.selectedSorong?.isEmpty ?? true
                          ? null
                          : state.selectedSorong,
                      onSorongChanged: (value) {
                        if (value != null) {
                          context
                              .read<ProductBloc>()
                              .add(UpdateSelectedSorong(value));
                        }
                      },
                      sizes: state.availableSizes,
                      selectedSize: state.selectedSize?.isEmpty ?? true
                          ? null
                          : state.selectedSize,
                      onSizeChanged: (value) {
                        if (value != null) {
                          context
                              .read<ProductBloc>()
                              .add(UpdateSelectedUkuran(value));
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
                                      if (state.selectedBrand ==
                                              BrandEnum.springair.value ||
                                          state.selectedBrand ==
                                              BrandEnum.therapedic.value) {
                                        areaToUse = AreaEnum.nasional.value;
                                      }
                                      context
                                          .read<ProductBloc>()
                                          .add(ApplyFilters(
                                            selectedArea: areaToUse,
                                            selectedChannel: state
                                                        .selectedChannel
                                                        ?.isEmpty ??
                                                    true
                                                ? null
                                                : state.selectedChannel,
                                            selectedBrand:
                                                state.selectedBrand?.isEmpty ??
                                                        true
                                                    ? null
                                                    : state.selectedBrand,
                                            selectedKasur:
                                                state.selectedKasur?.isEmpty ??
                                                        true
                                                    ? null
                                                    : state.selectedKasur,
                                            selectedDivan:
                                                state.selectedDivan?.isEmpty ??
                                                        true
                                                    ? null
                                                    : state.selectedDivan,
                                            selectedHeadboard: state
                                                        .selectedHeadboard
                                                        ?.isEmpty ??
                                                    true
                                                ? null
                                                : state.selectedHeadboard,
                                            selectedSorong:
                                                state.selectedSorong?.isEmpty ??
                                                        true
                                                    ? null
                                                    : state.selectedSorong,
                                            selectedSize:
                                                state.selectedSize?.isEmpty ??
                                                        true
                                                    ? null
                                                    : state.selectedSize,
                                          ));
                                      // Scroll ke tombol filter & reset, pastikan tepat di bawah AppBar
                                      await Future.delayed(
                                          const Duration(milliseconds: 100));
                                      final ctx =
                                          _filterButtonKey.currentContext;
                                      if (ctx != null) {
                                        final box = ctx.findRenderObject()
                                            as RenderBox?;
                                        if (box != null) {
                                          final position = box
                                              .localToGlobal(Offset.zero,
                                                  ancestor: null)
                                              .dy;
                                          final scrollOffset =
                                              _scrollController.offset +
                                                  position -
                                                  appBarHeight -
                                                  16; // 16 = padding
                                          _scrollController.animateTo(
                                            scrollOffset,
                                            duration: const Duration(
                                                milliseconds: 400),
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
                                size: 18,
                              ),
                              label: state.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(
                                      state.isUserAreaSet
                                          ? "Terapkan Filter"
                                          : "Tampilkan Produk",
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppPadding.p16,
                                    vertical: AppPadding.p12),
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
                                      context
                                          .read<ProductBloc>()
                                          .add(ResetFilters());
                                      // Scroll kembali ke posisi sebelum filter diterapkan
                                      await Future.delayed(
                                          const Duration(milliseconds: 100));
                                      if (_lastScrollOffset != null) {
                                        _scrollController.animateTo(
                                          _lastScrollOffset!,
                                          duration:
                                              const Duration(milliseconds: 400),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.refresh,
                                  color: Colors.white, size: 18),
                              label: const Text("Reset"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: state.isLoading
                                    ? Colors.grey.shade400
                                    : Colors.red.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppPadding.p16,
                                    vertical: AppPadding.p12),
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
                                    key:
                                        ValueKey(state.filteredProducts.length),
                                    itemCount: state.filteredProducts.length,
                                    itemBuilder: (context, index) {
                                      return ProductCard(
                                          product:
                                              state.filteredProducts[index]);
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
}
