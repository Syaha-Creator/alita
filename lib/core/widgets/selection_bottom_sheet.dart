import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable selection sheet for choosing one item from a list.
///
/// Function:
/// - Menampilkan daftar pilihan dengan header title yang konsisten.
/// - Menandai item aktif dengan icon check.
/// - Mengembalikan item terpilih lewat callback dan menutup sheet otomatis.
class SelectionBottomSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final T? selectedItem;
  final String Function(T item) labelBuilder;
  final ValueChanged<T> onItemSelected;
  final double maxHeightFactor;

  const SelectionBottomSheet({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.labelBuilder,
    required this.onItemSelected,
    this.maxHeightFactor = 0.6,
  });

  static const double _headerHeight = 52;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final maxSheetHeight = MediaQuery.of(context).size.height * maxHeightFactor;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final maxListHeight = (availableHeight - _headerHeight - bottomPadding)
                .clamp(0.0, double.infinity);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxListHeight),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = item == selectedItem;
                      return ListTile(
                        title: Text(labelBuilder(item)),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check,
                                color: AppColors.accent,
                                size: 22,
                              )
                            : null,
                        onTap: () {
                          onItemSelected(item);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: bottomPadding),
              ],
            );
          },
        ),
      ),
    );
  }
}
