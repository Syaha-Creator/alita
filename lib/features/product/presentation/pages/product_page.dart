import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../navigation/navigation_service.dart';
import '../../../../navigation/route_path.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/state/auth_state.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../bloc/event/product_event.dart';
import '../bloc/product_bloc.dart';
import '../bloc/state/product_state.dart';
import '../widgets/logout_button.dart';
import '../widgets/product_card.dart';
import '../widgets/product_dropdown.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          if (!mounted) return;
          NavigationService.navigateAndReplace(RoutePaths.login);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Product Page"),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
            ),
            LogoutButton(),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is ProductLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ProductError) {
                return Center(
                  child: Text(
                    state.message,
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
              if (state.availableAreas.isEmpty) {
                return const Center(child: Text("Data tidak ditemukan"));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductDropdown(
                    isSetActive: state.isSetActive,
                    onSetChanged: (value) {
                      context.read<ProductBloc>().add(ToggleSet(value));
                    },
                    areas: state.availableAreas,
                    selectedArea: state.selectedArea,
                    onAreaChanged: (value) {
                      if (value != null) {
                        context
                            .read<ProductBloc>()
                            .add(UpdateSelectedArea(value));
                      }
                    },
                    channels: state.availableChannels,
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
                    brands: state.availableBrands,
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
                    selectedHeadboard: state.selectedHeadboard?.isEmpty ?? true
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
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: (state.selectedChannel != null &&
                            state.selectedChannel!.isNotEmpty)
                        ? () {
                            print("🔄 Menerapkan Filter...");
                            context.read<ProductBloc>().add(ApplyFilters(
                                  selectedArea:
                                      state.selectedArea?.isEmpty ?? true
                                          ? null
                                          : state.selectedArea,
                                  selectedChannel:
                                      state.selectedChannel?.isEmpty ?? true
                                          ? null
                                          : state.selectedChannel,
                                  selectedBrand:
                                      state.selectedBrand?.isEmpty ?? true
                                          ? null
                                          : state.selectedBrand,
                                  selectedKasur:
                                      state.selectedKasur?.isEmpty ?? true
                                          ? null
                                          : state.selectedKasur,
                                  selectedDivan:
                                      state.selectedDivan?.isEmpty ?? true
                                          ? null
                                          : state.selectedDivan,
                                  selectedHeadboard:
                                      state.selectedHeadboard?.isEmpty ?? true
                                          ? null
                                          : state.selectedHeadboard,
                                  selectedSorong:
                                      state.selectedSorong?.isEmpty ?? true
                                          ? null
                                          : state.selectedSorong,
                                  selectedSize:
                                      state.selectedSize?.isEmpty ?? true
                                          ? null
                                          : state.selectedSize,
                                ));
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.selectedChannel != null
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Center(
                      child: Text(
                        "Tampilkan Produk",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: state.filteredProducts.isNotEmpty
                          ? ListView.builder(
                              key: ValueKey(state.filteredProducts.length),
                              itemCount: state.filteredProducts.length,
                              itemBuilder: (context, index) {
                                return ProductCard(
                                    product: state.filteredProducts[index]);
                              },
                            )
                          : state.isFilterApplied
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search_off,
                                          size: 80, color: Colors.grey),
                                      const SizedBox(height: 10),
                                      Text(
                                        "Tidak ada produk yang cocok dengan filter.",
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
