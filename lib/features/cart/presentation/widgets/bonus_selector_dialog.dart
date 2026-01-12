import 'package:flutter/material.dart';
import '../../../../config/app_constant.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../theme/app_colors.dart';
import '../../../../services/accessories_service.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';

class BonusSelectorDialog extends StatefulWidget {
  final List<AccessoryEntity> accessories;
  final int bonusIndex;
  final int productId;
  final double netPrice;
  final int currentQuantity;
  final String cartLineId;

  const BonusSelectorDialog({
    super.key,
    required this.accessories,
    required this.bonusIndex,
    required this.productId,
    required this.netPrice,
    required this.currentQuantity,
    required this.cartLineId,
  });

  @override
  State<BonusSelectorDialog> createState() => _BonusSelectorDialogState();
}

class _BonusSelectorDialogState extends State<BonusSelectorDialog> {
  List<AccessoryEntity> filteredAccessories = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredAccessories = widget.accessories;
    _searchController.addListener(_filterAccessories);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterAccessories);
    _searchController.dispose();
    _customController.dispose();
    super.dispose();
  }

  void _filterAccessories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredAccessories = widget.accessories;
      } else {
        filteredAccessories = widget.accessories.where((accessory) {
          final itemName = accessory.item.toLowerCase();
          final brand = accessory.brand.toLowerCase();
          final ukuran = accessory.ukuran.toLowerCase();
          return itemName.contains(query) ||
              brand.contains(query) ||
              ukuran.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Pilih Item Bonus',
        style: TextStyle(
            fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari item bonus...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: AppPadding.p16),
            Expanded(
              child: filteredAccessories.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada item yang ditemukan',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? AppColors.textSecondaryDark 
                                : AppColors.textSecondaryLight),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredAccessories.length + 1, // +1 for Custom
                      itemBuilder: (context, index) {
                        // Custom option as first item
                        if (index == 0) {
                          return ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text(
                              'Custom',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Masukkan item bonus custom',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                              ),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (dialogCtx) {
                                  return AlertDialog(
                                    title: const Text(
                                      'Item Bonus Custom',
                                      style: TextStyle(fontFamily: 'Inter'),
                                    ),
                                    content: TextField(
                                      controller: _customController,
                                      autofocus: true,
                                      decoration: const InputDecoration(
                                        hintText: 'Masukkan nama item bonus...',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogCtx),
                                        child: const Text(
                                          'Batal',
                                          style: TextStyle(fontFamily: 'Inter'),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          if (_customController.text.isNotEmpty) {
                                            context
                                                .read<CartBloc>()
                                                .add(UpdateCartBonus(
                                                  productId: widget.productId,
                                                  netPrice: widget.netPrice,
                                                  bonusIndex: widget.bonusIndex,
                                                  bonusName:
                                                      _customController.text,
                                                  bonusQuantity:
                                                      widget.currentQuantity,
                                                  cartLineId: widget.cartLineId,
                                                ));
                                            Navigator.pop(dialogCtx);
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: const Text(
                                          'Simpan',
                                          style: TextStyle(fontFamily: 'Inter'),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        }

                        // Regular accessory items
                        final accessory = filteredAccessories[index - 1];
                        final displayText = accessory.ukuran.isNotEmpty
                            ? '${accessory.item} (${accessory.ukuran})'
                            : accessory.item;

                        return ListTile(
                          title: Text(
                            displayText,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'Brand: ${accessory.brand}',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Theme.of(context).brightness == Brightness.dark 
                                ? AppColors.textSecondaryDark 
                                : AppColors.textSecondaryLight),
                          ),
                          onTap: () {
                            context.read<CartBloc>().add(UpdateCartBonus(
                                  productId: widget.productId,
                                  netPrice: widget.netPrice,
                                  bonusIndex: widget.bonusIndex,
                                  bonusName: displayText,
                                  bonusQuantity: widget.currentQuantity,
                                  cartLineId: widget.cartLineId,
                                ));
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Batal',
            style: TextStyle(
                fontFamily: 'Inter', color: AppColors.textSecondaryLight),
          ),
        ),
      ],
    );
  }
}
