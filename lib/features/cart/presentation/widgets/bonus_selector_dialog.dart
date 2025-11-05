import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    filteredAccessories = widget.accessories;
    _searchController.addListener(_filterAccessories);
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            const SizedBox(height: 16),
            Expanded(
              child: filteredAccessories.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada item yang ditemukan',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredAccessories.length,
                      itemBuilder: (context, index) {
                        final accessory = filteredAccessories[index];
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
                                color: Colors.grey[600]),
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
