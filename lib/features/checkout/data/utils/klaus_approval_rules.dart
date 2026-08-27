import 'checkout_channel_resolver.dart';

/// Aturan auto-assign RSM Klaus — **Direct (S1) saja** (bukan SO / MM).
///
/// Jika channel = S1 DAN [workPlaceId] ∈ {1937, 6015} DAN [spvId] ∈ {4147, 1019},
/// Pak Klaus ([klausUserId] = 5247) wajib menjadi Level-3 RSM di chain approval
/// — termasuk tanpa diskon / tanpa bonus.
class KlausApprovalRules {
  const KlausApprovalRules._();

  static const int klausUserId = 5247;
  static const Set<int> workPlaceIds = {1937, 6015};
  static const Set<int> spvIds = {4147, 1019};

  /// Rocky Suwandi (1019) / Ahmad Rizaldi (4147) di lokasi Klaus, channel Direct.
  static bool isActive({
    required int? workPlaceId,
    required int? spvId,
    String? orderChannel,
    bool isIndirectSale = false,
  }) {
    if (isIndirectSale) return false;
    final channel = (orderChannel ?? '').trim().toUpperCase();
    // Hanya Direct S1 — SO (indirect) dan MM tidak ikut.
    if (channel != CheckoutChannelResolver.channelS1) return false;

    final wp = workPlaceId ?? 0;
    final spv = spvId ?? 0;
    if (wp <= 0 || spv <= 0) return false;
    return workPlaceIds.contains(wp) && spvIds.contains(spv);
  }
}
