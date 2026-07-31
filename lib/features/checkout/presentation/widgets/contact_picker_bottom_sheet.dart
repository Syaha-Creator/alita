import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../data/models/address_book_contact.dart';

/// Reusable bottom sheet to pick one contact from the server-side address
/// book (`/address_books`, filtered by the sales' own area).
///
/// Search is client-side only — the API has no name/phone search param, so
/// the full area list is fetched once and filtered here by
/// [AddressBookContact.name] or [AddressBookContact.phone].
class ContactPickerBottomSheet extends StatefulWidget {
  final List<AddressBookContact> contacts;

  const ContactPickerBottomSheet({super.key, required this.contacts});

  @override
  State<ContactPickerBottomSheet> createState() =>
      _ContactPickerBottomSheetState();
}

class _ContactPickerBottomSheetState extends State<ContactPickerBottomSheet> {
  String _query = '';

  List<AddressBookContact> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.contacts;
    return widget.contacts
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pilih Kontak Pelanggan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSearchField(
              hintText: 'Cari nama atau No. HP...',
              autofocus: false,
              filled: true,
              fillColor: AppColors.surfaceLight,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? EmptyStateView(
                    icon: widget.contacts.isEmpty
                        ? Icons.contacts_outlined
                        : Icons.search_off_rounded,
                    title: widget.contacts.isEmpty
                        ? 'Belum ada kontak di area ini'
                        : 'Kontak tidak ditemukan',
                    subtitle: widget.contacts.isEmpty
                        ? 'Isi form pelanggan secara manual.'
                        : 'Coba kata kunci nama atau No. HP lain.',
                    iconSize: 56,
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final contact = filtered[index];
                      return RepaintBoundary(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.08),
                            child: const Icon(
                              Icons.person,
                              color: AppColors.accent,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            contact.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: contact.phone.isNotEmpty
                              ? Text(
                                  contact.phone,
                                  style: const TextStyle(fontSize: 12),
                                )
                              : null,
                          onTap: () => Navigator.pop(context, contact),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
