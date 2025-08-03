import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/widgets/quantity_control.dart';
import '../../../../services/accessories_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';

class EditBonusDialog extends StatefulWidget {
  final String currentBonusName;
  final int currentBonusQuantity;
  final int bonusIndex;
  final int productId;
  final double netPrice;

  const EditBonusDialog({
    super.key,
    required this.currentBonusName,
    required this.currentBonusQuantity,
    required this.bonusIndex,
    required this.productId,
    required this.netPrice,
  });

  @override
  State<EditBonusDialog> createState() => _EditBonusDialogState();
}

class _EditBonusDialogState extends State<EditBonusDialog> {
  List<ProductEntity> accessories = [];
  bool isLoading = true;
  String? selectedAccessory;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    quantity = widget.currentBonusQuantity;
    _loadAccessories();
  }

  // Helper method to extract base name from bonus name (remove size info)
  String _extractBaseName(String bonusName) {
    // Remove common size patterns like "90x200", "100x200", etc.
    final sizePattern = RegExp(r'\s*\(\d+x\d+\)$|\s*\d+x\d+$');
    return bonusName.replaceAll(sizePattern, '').trim();
  }

  Future<void> _loadAccessories() async {
    try {
      final accessoriesList = await AccessoriesService.getAccessories();
      setState(() {
        accessories = accessoriesList;
        isLoading = false;
        // Set selected accessory to current bonus name if it exists in accessories
        if (widget.currentBonusName.isNotEmpty) {
          // Try to find exact match first
          final exactMatch = accessories
              .where((acc) => acc.kasur == widget.currentBonusName)
              .toList();

          if (exactMatch.isNotEmpty) {
            // If found exact match, use the first one
            selectedAccessory =
                '${exactMatch.first.id}_${exactMatch.first.kasur}';
          } else {
            // Try to find partial match (base name without size)
            final baseName = _extractBaseName(widget.currentBonusName);
            final partialMatches = accessories
                .where((acc) =>
                    acc.kasur.toLowerCase().contains(baseName.toLowerCase()))
                .toList();

            if (partialMatches.isNotEmpty) {
              // If found partial match, use the first one
              selectedAccessory =
                  '${partialMatches.first.id}_${partialMatches.first.kasur}';
            } else if (accessories.isNotEmpty) {
              // If no match found, use first accessory but keep current name
              selectedAccessory =
                  '${accessories.first.id}_${accessories.first.kasur}';
            }
          }
        } else if (accessories.isNotEmpty) {
          selectedAccessory =
              '${accessories.first.id}_${accessories.first.kasur}';
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading accessories: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppPadding.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.accentDark.withOpacity(0.2)
                        : AppColors.accentLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    color:
                        isDark ? AppColors.accentDark : AppColors.accentLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Bonus Item',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'Pilih dan sesuaikan bonus item',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppPadding.p16),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Accessory Dropdown
              Text(
                'Pilih Accessory',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: selectedAccessory,
                  isExpanded: true,
                  underline: Container(),
                  hint: Text(
                    'Pilih accessory',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  items: accessories.map((accessory) {
                    // Create unique value by combining kasur name and ukuran
                    final displayText = accessory.ukuran.isNotEmpty
                        ? '${accessory.kasur} (${accessory.ukuran})'
                        : accessory.kasur;
                    final uniqueValue = '${accessory.id}_${accessory.kasur}';

                    return DropdownMenuItem<String>(
                      value: uniqueValue,
                      child: Text(
                        displayText,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAccessory = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: AppPadding.p16),

              // Quantity Control
              Text(
                'Jumlah',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: QuantityControl(
                  quantity: quantity,
                  onIncrement: () {
                    setState(() {
                      quantity++;
                    });
                  },
                  onDecrement: () {
                    if (quantity > 1) {
                      setState(() {
                        quantity--;
                      });
                    }
                  },
                ),
              ),
            ],
            const SizedBox(height: AppPadding.p24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppPadding.p12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedAccessory != null
                        ? () {
                            // Extract the actual kasur name from the selected value
                            final selectedAccessoryId =
                                selectedAccessory!.split('_')[0];
                            final selectedProduct = accessories.firstWhere(
                              (accessory) =>
                                  accessory.id.toString() ==
                                  selectedAccessoryId,
                              orElse: () => accessories.first,
                            );

                            // Use the display text from dropdown (includes size if available)
                            // This ensures the selected size is preserved
                            final displayText = selectedProduct
                                    .ukuran.isNotEmpty
                                ? '${selectedProduct.kasur} (${selectedProduct.ukuran})'
                                : selectedProduct.kasur;

                            // Use display text if user selected a different item
                            // Otherwise keep current name if it's the same base product
                            String bonusNameToUse;
                            if (widget.currentBonusName.isNotEmpty &&
                                selectedProduct.kasur ==
                                    widget.currentBonusName) {
                              // Exact match - keep current name
                              bonusNameToUse = widget.currentBonusName;
                            } else if (widget.currentBonusName.isNotEmpty &&
                                _extractBaseName(widget.currentBonusName) ==
                                    selectedProduct.kasur) {
                              // Same base product but different size - use display text with new size
                              bonusNameToUse = displayText;
                            } else {
                              // Different product or no current - use display text
                              bonusNameToUse = displayText;
                            }

                            if (widget.bonusIndex == -1) {
                              // Adding new bonus
                              context.read<CartBloc>().add(AddCartBonus(
                                    productId: widget.productId,
                                    netPrice: widget.netPrice,
                                    bonusName: bonusNameToUse,
                                    bonusQuantity: quantity,
                                  ));
                            } else {
                              // Updating existing bonus
                              context.read<CartBloc>().add(UpdateCartBonus(
                                    productId: widget.productId,
                                    netPrice: widget.netPrice,
                                    bonusIndex: widget.bonusIndex,
                                    bonusName: bonusNameToUse,
                                    bonusQuantity: quantity,
                                  ));
                            }
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.accentDark : AppColors.accentLight,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppPadding.p12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Simpan',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
