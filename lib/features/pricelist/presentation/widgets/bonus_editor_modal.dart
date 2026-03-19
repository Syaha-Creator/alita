import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/action_button_bar.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../logic/accessory_provider.dart';

/// Removes redundant trailing size duplication in bonus display names
/// (e.g. "X 090x200 090x200" → "X 090x200").
String cleanBonusDisplayName(String name) {
  final s = name.trim();
  final parts = s.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    final last = parts.last;
    final prev = parts[parts.length - 2];
    if (last == prev &&
        RegExp(r'^\d+x\d+$', caseSensitive: false).hasMatch(last)) {
      return parts.sublist(0, parts.length - 1).join(' ');
    }
  }
  return s;
}

/// Shows the bonus editor modal bottom sheet.
///
/// [defaultBonuses] is the list of factory-default bonuses.
/// [isBonusCustomized] indicates if the user has already customized bonuses.
/// [customBonuses] holds the current custom bonus list.
/// [onSave] is called with the new bonus list when the user taps "Simpan Perubahan".
void showBonusEditorModal(
  BuildContext context, {
  required List<Map<String, dynamic>> defaultBonuses,
  required bool isBonusCustomized,
  required List<Map<String, dynamic>> customBonuses,
  required void Function(List<Map<String, dynamic>> newBonuses) onSave,
}) {
  List<Map<String, dynamic>> tempBonuses =
      (isBonusCustomized ? customBonuses : defaultBonuses)
          .map(
            (e) => Map<String, dynamic>.from(e)
              ..putIfAbsent('max_qty', () => ((e['qty'] as int?) ?? 1) * 2),
          )
          .toList();
  String searchQuery = '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final accAsync = ref.watch(accessoryProvider);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SheetScaffold(
              topRadius: 20,
              includeBottomSafePadding: false,
              bottomSpacing: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    final availableAcc = accAsync.value ?? [];
                    final filteredAcc = availableAcc.where((a) {
                      final searchString =
                          '${a.tipe} ${a.ukuran}'.toLowerCase();
                      return searchString.contains(
                        searchQuery.toLowerCase(),
                      );
                    }).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sesuaikan Bonus',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daftar bonus',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                if (tempBonuses.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Text(
                                      'Belum ada bonus. Tambah dari aksesoris di bawah.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                else
                                  ...tempBonuses.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final b = entry.value;
                                    final pl = (b['pl'] as num?)?.toDouble();
                                    final qty = (b['qty'] as int?) ?? 1;
                                    final maxQty = (b['max_qty'] as int?) ?? 1;
                                    return Container(
                                      margin: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.card_giftcard,
                                            color: AppColors.accent,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  cleanBonusDisplayName(
                                                    b['name']?.toString() ?? '',
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (pl != null && pl > 0)
                                                  const SizedBox(height: 2),
                                                if (pl != null && pl > 0)
                                                  Text(
                                                    'Senilai Rp ${AppFormatters.currencyIdrNoSymbol(pl)}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  qty == 1
                                                      ? Icons.delete_outline
                                                      : Icons
                                                          .remove_circle_outline,
                                                  size: 22,
                                                  color: qty == 1
                                                      ? AppColors.error
                                                      : AppColors.accent,
                                                ),
                                                onPressed: () =>
                                                    setModalState(() {
                                                  if (qty == 1) {
                                                    tempBonuses.removeAt(
                                                      index,
                                                    );
                                                  } else {
                                                    tempBonuses[index]['qty'] =
                                                        qty - 1;
                                                  }
                                                }),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 36,
                                                  minHeight: 36,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                ),
                                                child: Text(
                                                  '$qty / $maxQty',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.add_circle_outline,
                                                  size: 22,
                                                  color: qty >= maxQty
                                                      ? AppColors.textTertiary
                                                      : AppColors.accent,
                                                ),
                                                onPressed: qty >= maxQty
                                                    ? null
                                                    : () => setModalState(() {
                                                          tempBonuses[index]
                                                              ['qty'] = qty + 1;
                                                        }),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 36,
                                                  minHeight: 36,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Cari & Tambah Aksesoris Pengganti:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      AppSearchField(
                                        onChanged: (value) => setModalState(
                                          () => searchQuery = value,
                                        ),
                                        hintText:
                                            'Ketik nama aksesoris (cth: Pillow)...',
                                        hintStyle: const TextStyle(
                                          fontSize: 13,
                                        ),
                                        prefixIconSize: 20,
                                        prefixIconColor: AppColors.textTertiary,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 0,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        isDense: true,
                                      ),
                                      const SizedBox(height: 8),
                                      if (accAsync.isLoading)
                                        const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: CircularProgressIndicator
                                                .adaptive(),
                                          ),
                                        )
                                      else if (availableAcc.isEmpty)
                                        const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Text(
                                              'Aksesoris tidak tersedia.',
                                              style: TextStyle(
                                                color: AppColors.textTertiary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        )
                                      else if (filteredAcc.isEmpty)
                                        const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Text(
                                              'Aksesoris tidak ditemukan.',
                                              style: TextStyle(
                                                color: AppColors.textTertiary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          constraints: const BoxConstraints(
                                            maxHeight: 180,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppColors.border,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            color: AppColors.surfaceLight,
                                          ),
                                          child: ListView.separated(
                                            shrinkWrap: true,
                                            itemCount: filteredAcc.length,
                                            separatorBuilder:
                                                (context, index) =>
                                                    const Divider(
                                              height: 1,
                                            ),
                                            itemBuilder: (context, index) {
                                              final acc = filteredAcc[index];
                                              final t = acc.tipe.trim();
                                              final u = acc.ukuran.trim();
                                              final accDisplayName = u
                                                          .isEmpty ||
                                                      t.toLowerCase().contains(
                                                            u.toLowerCase(),
                                                          )
                                                  ? t
                                                  : '$t ($u)';
                                              return ListTile(
                                                dense: true,
                                                title: Text(
                                                  accDisplayName,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  'Rp ${AppFormatters.currencyIdrNoSymbol(acc.pricelist)}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AppColors.textTertiary,
                                                  ),
                                                ),
                                                trailing: const Icon(
                                                  Icons.add_circle,
                                                  color: AppColors.accent,
                                                ),
                                                onTap: () {
                                                  setModalState(() {
                                                    tempBonuses.add({
                                                      'name': accDisplayName,
                                                      'qty': 1,
                                                      'max_qty': 2,
                                                      'pl': acc.pricelist,
                                                      'is_custom': true,
                                                      'item_num': acc.itemNum,
                                                    });
                                                    searchQuery = '';
                                                  });
                                                  FocusScope.of(
                                                    context,
                                                  ).unfocus();
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ActionButtonBar(
                          height: 48,
                          borderRadius: 12,
                          primaryLabel: 'Simpan Perubahan',
                          primaryBackgroundColor: AppColors.accent,
                          primaryForegroundColor: AppColors.onPrimary,
                          primaryLabelStyle: const TextStyle(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          onPrimaryPressed: () {
                            onSave(List.from(tempBonuses));
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
