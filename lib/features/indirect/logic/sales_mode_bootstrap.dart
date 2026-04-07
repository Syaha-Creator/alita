import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/sales_mode.dart';
import '../../../core/utils/telemetry_access.dart';
import '../../cart/logic/cart_provider.dart';
import 'indirect_session_provider.dart';
import 'sales_mode_provider.dart';

/// Non-admin: mode diturunkan dari profil (`address_number` → indirect, selain itu direct).
/// Admin: tidak mengubah mode (mereka memilih di [SalesHubPage]).
///
/// Jika mode berubah, keranjang dan sesi toko indirect dikosongkan agar konsisten
/// dengan perilaku kartu di hub.
Future<void> syncSalesModeForNonAdminUser(
  WidgetRef ref, {
  required int userId,
  required String? addressNumber,
}) async {
  if (TelemetryAccess.canChooseSalesMode(userId)) return;

  final trimmed = addressNumber?.trim() ?? '';
  final hasAddr =
      trimmed.isNotEmpty && trimmed.toLowerCase() != 'null';
  final target = hasAddr ? SalesMode.indirect : SalesMode.direct;
  final current = ref.read(salesModeProvider);
  if (current != target) {
    await ref.read(cartProvider.notifier).clearCart();
    ref.read(indirectSessionProvider.notifier).clear();
  }
  await ref.read(salesModeProvider.notifier).setMode(target);
}
