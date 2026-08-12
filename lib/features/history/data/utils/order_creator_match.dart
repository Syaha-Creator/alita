import '../../../../core/utils/name_matcher.dart';

String _collapseWs(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

/// True jika user login adalah pembuat SP.
///
/// Backend bisa mengembalikan `creator` sebagai **user id** (`"42"`) atau
/// **nama** (`"Muhammad Akbar"`). Checkout mengirim id; response list/detail
/// sering sudah di-resolve ke nama — keduanya harus diterima.
bool isOrderCreator({
  required String orderCreator,
  String orderCreatorName = '',
  required int authUserId,
  int profileId = 0,
  String profileName = '',
}) {
  final creatorRaw = orderCreator.trim();
  final me = _collapseWs(profileName);

  // 1) Numeric creator → cocokkan auth.userId / profile.id
  if (creatorRaw.isNotEmpty) {
    final asId = int.tryParse(creatorRaw);
    if (asId != null) {
      for (final id in [authUserId, profileId]) {
        if (id > 0 && id == asId) return true;
      }
    } else if (me.isNotEmpty &&
        NameMatcher.softMatch(_collapseWs(creatorRaw), me)) {
      // 2) creator = nama (bukan id)
      return true;
    }
  }

  // 3) Fallback field creator_name
  final name = _collapseWs(orderCreatorName);
  if (name.isNotEmpty && me.isNotEmpty) {
    return NameMatcher.softMatch(name, me);
  }
  return false;
}
