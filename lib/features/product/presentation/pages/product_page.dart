import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../navigation/navigation_service.dart';
import '../../../../navigation/route_path.dart';
import '../../../../services/auth_service.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/event/auth_event.dart';
import '../../../authentication/presentation/bloc/state/auth_state.dart';
import '../bloc/event/product_event.dart';
import '../bloc/product_bloc.dart';
import '../bloc/state/product_state.dart';
import '../widgets/product_card.dart';
import '../widgets/product_dropdown.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(FetchProducts());
  }

  Future<void> _logout() async {
    bool confirmLogout = await _showLogoutDialog();
    if (!confirmLogout || !mounted) return;

    context.read<AuthBloc>().add(AuthLogoutRequested());
    await AuthService.logout();

    if (!mounted) return;
    NavigationService.navigateAndReplace(RoutePaths.login);
  }

  Future<bool> _showLogoutDialog() async {
    if (!mounted) return false;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor:
                colorScheme.surface, // Menggunakan warna sesuai theme
            title: Text(
              "Konfirmasi Logout",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            content: Text(
              "Apakah Anda yakin ingin keluar?",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                style: TextButton.styleFrom(
                  foregroundColor: isDarkMode
                      ? Colors.cyanAccent // Lebih terang di Dark Mode
                      : colorScheme.secondary,
                ),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? Colors.red.shade700 : colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

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
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
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
                  /// ✅ Gunakan `ProductDropdown`
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
                    selectedChannel: state.selectedChannel,
                    onChannelChanged: (value) {
                      if (value != null) {
                        context
                            .read<ProductBloc>()
                            .add(UpdateSelectedChannel(value));
                      }
                    },
                    brands: state.availableBrands,
                    selectedBrand: state.selectedBrand,
                    onBrandChanged: (value) {
                      if (value != null) {
                        context
                            .read<ProductBloc>()
                            .add(UpdateSelectedBrand(value));
                      }
                    },
                    kasurs: state.availableKasurs,
                    selectedKasur: state.selectedKasur,
                    onKasurChanged: (value) {
                      if (value != null) {
                        context
                            .read<ProductBloc>()
                            .add(UpdateSelectedKasur(value));
                      }
                    },
                    divans: state.availableDivans,
                    selectedDivan: state.selectedDivan,
                    onDivanChanged: (value) {
                      if (value != null) {
                        context
                            .read<ProductBloc>()
                            .add(UpdateSelectedDivan(value));
                      }
                    },
                    headboards: state.availableHeadboards,
                    selectedHeadboard: state.selectedHeadboard,
                    onHeadboardChanged: (value) {
                      if (value != null) {
                        context
                            .read<ProductBloc>()
                            .add(UpdateSelectedHeadboard(value));
                      }
                    },
                    sorongs: state.availableSorongs,
                    selectedSorong: state.selectedSorong,
                    onSorongChanged: (value) {
                      if (value != null) {
                        context
                            .read<ProductBloc>()
                            .add(UpdateSelectedSorong(value));
                      }
                    },
                    sizes: state.availableSizes,
                    selectedSize: state.selectedSize,
                    onSizeChanged: (value) {
                      if (value != null) {
                        context
                            .read<ProductBloc>()
                            .add(UpdateSelectedUkuran(value));
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // ✅ Tampilkan daftar produk setelah tombol ditekan
                  ElevatedButton(
                    onPressed: state.selectedChannel != null
                        ? () {
                            context.read<ProductBloc>().add(ApplyFilters(
                                  selectedArea: state.selectedArea,
                                  selectedChannel: state.selectedChannel,
                                  selectedBrand: state.selectedBrand,
                                  selectedKasur: state.selectedKasur,
                                  selectedDivan: state.selectedDivan,
                                  selectedHeadboard: state.selectedHeadboard,
                                  selectedSorong: state.selectedSorong,
                                  selectedSize: state.selectedSize,
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

                  const SizedBox(height: 20),

                  // ✅ Tampilkan hasil produk yang telah difilter
                  if (state.filteredProducts.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.filteredProducts.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                              product: state.filteredProducts[index]);
                        },
                      ),
                    )
                  else if (state is ProductFiltered)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(
                        child: Text(
                          "Tidak ada produk yang cocok dengan filter.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
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
