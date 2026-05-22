import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout_tokens.dart';
import 'app_search_field.dart';
import 'sheet_scaffold.dart';

/// Reusable selection sheet for choosing one item from a list.
///
/// Function:
/// - Menampilkan daftar pilihan dengan header title yang konsisten.
/// - Menandai item aktif dengan icon check.
/// - Mengembalikan item terpilih lewat callback dan menutup sheet otomatis.
/// - Opsional: search bar aktif lewat [searchHint].
class SelectionBottomSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final T? selectedItem;
  final String Function(T item) labelBuilder;
  final ValueChanged<T> onItemSelected;
  final double maxHeightFactor;

  /// Jika diisi, search bar ditampilkan dan filter item sesuai query.
  /// Filter dilakukan terhadap hasil [labelBuilder] (case-insensitive).
  final String? searchHint;

  const SelectionBottomSheet({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.labelBuilder,
    required this.onItemSelected,
    this.maxHeightFactor = 0.6,
    this.searchHint,
  });

  @override
  State<SelectionBottomSheet<T>> createState() =>
      _SelectionBottomSheetState<T>();
}

class _SelectionBottomSheetState<T> extends State<SelectionBottomSheet<T>> {
  String _query = '';

  List<T> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items
        .where((item) =>
            widget.labelBuilder(item).toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasSearch = widget.searchHint != null;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight =
        MediaQuery.sizeOf(context).height * widget.maxHeightFactor;
    final filtered = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Semantics(
        container: true,
        label: 'Pilih opsi',
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: SheetScaffold(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (hasSearch) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppLayoutTokens.space16,
                      0,
                      AppLayoutTokens.space16,
                      AppLayoutTokens.space8,
                    ),
                    child: AppSearchField(
                      hintText: widget.searchHint!,
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      prefixIconSize: 18,
                      clearIconSize: 16,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppLayoutTokens.space12,
                        vertical: AppLayoutTokens.space10,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                ],
                Flexible(
                  child: filtered.isEmpty
                      ? Padding(
                          padding:
                              const EdgeInsets.all(AppLayoutTokens.space20),
                          child: Center(
                            child: Text(
                              'Tidak ditemukan',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textTertiary),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final isSelected = item == widget.selectedItem;
                            return RepaintBoundary(
                              child: ListTile(
                                title: Text(widget.labelBuilder(item)),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: AppColors.accent,
                                        size: 22,
                                      )
                                    : null,
                                onTap: () {
                                  widget.onItemSelected(item);
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
