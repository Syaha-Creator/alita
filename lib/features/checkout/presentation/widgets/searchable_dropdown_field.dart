import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/checkout_input_decoration.dart';
import '../../../../core/widgets/sheet_scaffold.dart';

/// Generic dropdown field that opens a searchable bottom-sheet picker.
///
/// [T] is the item type. Display strings are produced by [itemAsString].
/// Selection is communicated via [onChanged]; form validation uses
/// [selectedValue] being null as the "empty" signal.
class SearchableDropdownField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? selectedValue;
  final List<T> items;
  final String Function(T) itemAsString;
  final void Function(T) onChanged;

  const SearchableDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.selectedValue,
    required this.items,
    required this.itemAsString,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      validator: (_) => selectedValue == null ? '$label wajib dipilih' : null,
      builder: (FormFieldState<T> state) {
        return InkWell(
          onTap: () => _showSearchModal(
            context,
            onPicked: (val) {
              onChanged(val);
              state.didChange(val);
            },
          ),
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: CheckoutInputDecoration.dropdown(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 13),
              errorText: state.errorText,
              enabledBorderSide: BorderSide(
                color: state.hasError ? AppColors.error : AppColors.border,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              isDense: true,
              filled: false,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedValue != null ? itemAsString(selectedValue as T) : hint,
                    style: TextStyle(
                      fontSize: 13,
                      color: selectedValue != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSearchModal(
    BuildContext context, {
    required void Function(T) onPicked,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        String query = '';
        return StatefulBuilder(
          builder: (_, setStateSheet) {
            final filtered = items.where((item) {
              return itemAsString(item)
                  .toLowerCase()
                  .contains(query.toLowerCase());
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetCtx).size.height * 0.7,
                ),
                child: SheetScaffold(
                  topRadius: 16,
                  includeBottomSafePadding: false,
                  bottomSpacing: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pilih $label',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppSearchField(
                          autofocus: true,
                          hintText: 'Cari nama...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          onChanged: (val) =>
                              setStateSheet(() => query = val),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: filtered.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Nama tidak ditemukan',
                                    style: TextStyle(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    color: AppColors.divider,
                                  ),
                                  itemBuilder: (_, index) {
                                    final item = filtered[index];
                                    return RepaintBoundary(
                                      child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        itemAsString(item),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      onTap: () {
                                        onPicked(item);
                                        Navigator.pop(sheetCtx);
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
          },
        );
      },
    );
  }
}
