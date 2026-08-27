import '../../../../core/utils/name_matcher.dart';

String _collapseWs(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

bool _nameMatchesAny(String candidate, Iterable<String> names) {
  final c = _collapseWs(candidate);
  if (c.isEmpty) return false;
  for (final raw in names) {
    final n = _collapseWs(raw);
    if (n.isNotEmpty && NameMatcher.softMatch(c, n)) return true;
  }
  return false;
}

/// True jika user login adalah pembuat SP.
///
/// Backend bisa mengembalikan `creator` sebagai **user id** (`"42"`) atau
/// **nama** (`"Muhammad Akbar"`). Checkout mengirim id; response list/detail
/// sering sudah di-resolve ke nama — keduanya harus diterima.
///
/// Nama di SP (`creator` / `creator_name`) sering dari `users.name` (login),
/// sementara nama profil app dari **CWE** (`contact_work_experiences`) bisa
/// beda ejaan/format — jadi cocokkan keduanya, plus `sales_code` sebagai
/// fallback identitas stabil.
bool isOrderCreator({
  required String orderCreator,
  String orderCreatorName = '',
  required int authUserId,
  int profileId = 0,
  String profileName = '',
  String authUserName = '',
  String orderSalesCode = '',
  String userSalesCode = '',
}) {
  final creatorRaw = orderCreator.trim();
  final candidateNames = <String>[profileName, authUserName];

  // 1) Numeric creator → cocokkan auth.userId / profile.id
  if (creatorRaw.isNotEmpty) {
    final asId = int.tryParse(creatorRaw);
    if (asId != null) {
      for (final id in [authUserId, profileId]) {
        if (id > 0 && id == asId) return true;
      }
    } else if (_nameMatchesAny(creatorRaw, candidateNames)) {
      // 2) creator = nama (bukan id) — CWE atau login
      return true;
    }
  }

  // 3) Fallback field creator_name
  if (_nameMatchesAny(orderCreatorName, candidateNames)) {
    return true;
  }

  // 4) sales_code / address_number — identitas yang lebih stabil dari nama
  final orderCode = orderSalesCode.trim().toLowerCase();
  final userCode = userSalesCode.trim().toLowerCase();
  if (orderCode.isNotEmpty && userCode.isNotEmpty && orderCode == userCode) {
    return true;
  }

  return false;
}
