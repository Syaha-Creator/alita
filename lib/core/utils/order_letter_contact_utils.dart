/// Helpers for `order_letter_contacts` (phone + ship flag).
abstract final class OrderLetterContactUtils {
  OrderLetterContactUtils._();

  /// `ship == true` means **penerima** pengiriman. Null/false = bukan baris penerima.
  static bool shipIsRecipient(dynamic v) {
    if (v == true || v == 1) return true;
    if (v == null || v == false) return false;
    final s = v.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  static List<Map<String, dynamic>> parseContactsList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => e is Map<String, dynamic>
            ? e
            : Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// `ship: false` (atau 0 / string "false") = nomor **pelanggan** di contacts, bukan penerima.
  static bool shipIsCustomerContactRow(dynamic ship) {
    if (ship == false) return true;
    if (ship == 0) return true;
    final s = ship?.toString().trim().toLowerCase();
    return s == 'false' || s == '0';
  }

  /// Nomor dari baris pelanggan (`ship: false`), urutan stabil, unik.
  static List<String> customerPhonesInOrder(
    List<Map<String, dynamic>> contacts,
  ) {
    final out = <String>[];
    for (final m in contacts) {
      if (!shipIsCustomerContactRow(m['ship'])) continue;
      final p = m['phone']?.toString().trim() ?? '';
      if (p.isEmpty || p == '-') continue;
      if (!out.contains(p)) out.add(p);
    }
    return out;
  }

  /// Kontak pelanggan dari contacts, lalu [fallbackPhone] (`order_letter.phone`) jika belum ada di list.
  static List<String> customerPhoneList(
    List<Map<String, dynamic>> contacts, {
    String fallbackPhone = '',
  }) {
    final out = <String>[];
    void addUnique(String raw) {
      final t = raw.trim();
      if (t.isEmpty || t == '-') return;
      if (!out.contains(t)) out.add(t);
    }
    for (final p in customerPhonesInOrder(contacts)) {
      addUnique(p);
    }
    addUnique(fallbackPhone);
    return out;
  }

  static List<String> customerPhoneListFromOrderData(
    Map<String, dynamic> orderData,
  ) {
    final list = parseContactsList(orderData['order_letter_contacts']);
    final letter = orderData['order_letter'] as Map<String, dynamic>? ?? {};
    final fallback = letter['phone']?.toString() ?? '';
    return customerPhoneList(list, fallbackPhone: fallback);
  }

  /// Nomor HP penerima (`ship: true`), urutan stabil, unik.
  static List<String> recipientPhonesInOrder(
    List<Map<String, dynamic>> contacts,
  ) {
    final out = <String>[];
    for (final m in contacts) {
      if (!shipIsRecipient(m['ship'])) continue;
      final p = m['phone']?.toString().trim() ?? '';
      if (p.isEmpty || p == '-') continue;
      if (!out.contains(p)) out.add(p);
    }
    return out;
  }

  /// Gabung untuk tampilan; [fallbackPhone] jika tidak ada kontak `ship: true`.
  static String recipientPhonesDisplay(
    List<Map<String, dynamic>> contacts, {
    String fallbackPhone = '',
  }) {
    final xs = recipientPhoneList(contacts, fallbackPhone: fallbackPhone);
    if (xs.isEmpty) return '';
    return xs.join(' / ');
  }

  /// Daftar nomor penerima (`ship: true`), atau [fallbackPhone] sebagai satu elemen.
  static List<String> recipientPhoneList(
    List<Map<String, dynamic>> contacts, {
    String fallbackPhone = '',
  }) {
    final xs = recipientPhonesInOrder(contacts);
    if (xs.isNotEmpty) return xs;
    final f = fallbackPhone.trim();
    if (f.isEmpty || f == '-') return [];
    return [f];
  }

  /// Dari map response API (root berisi `order_letter` + `order_letter_contacts`).
  static String recipientPhonesFromOrderData(Map<String, dynamic> orderData) {
    final list = parseContactsList(orderData['order_letter_contacts']);
    final letter = orderData['order_letter'] as Map<String, dynamic>? ?? {};
    final fallback = letter['phone']?.toString() ?? '';
    return recipientPhonesDisplay(list, fallbackPhone: fallback);
  }

  /// Sama seperti [recipientPhonesFromOrderData] tetapi sebagai list (aksi per nomor).
  static List<String> recipientPhoneListFromOrderData(
    Map<String, dynamic> orderData,
  ) {
    final list = parseContactsList(orderData['order_letter_contacts']);
    final letter = orderData['order_letter'] as Map<String, dynamic>? ?? {};
    final fallback = letter['phone']?.toString() ?? '';
    return recipientPhoneList(list, fallbackPhone: fallback);
  }

  /// Untuk tel:/WA: ambil segmen pertama jika ada beberapa nomor dipisah ` / `.
  static String firstDialablePhone(String joined) {
    final t = joined.trim();
    if (t.isEmpty) return '';
    return t.split('/').first.trim();
  }
}
