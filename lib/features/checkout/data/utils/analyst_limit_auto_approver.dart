import '../../../../core/utils/app_telemetry.dart';
import '../../../../core/utils/log.dart';
import '../models/checkout_models.dart';
import '../services/order_letter_limit_service.dart';

/// Auto-approves pending Analyst-level (`approver_level_id: 4`) discount
/// rows across ALL [PendingDetail]s of ONE order, when the order's total
/// `discount_extra_price` for that analyst fits within their remaining
/// approval limit (`GET /order_letter_limits`).
///
/// Runs once per order submission (create or edit), summing the nominal
/// across every cart item/component first — a per-item check would be
/// wrong, since several items can share the same Analyst approver and
/// together exceed their limit even if each item alone would fit.
///
/// Mirrors the existing "Program Bulanan" auto-approve pattern in
/// [CheckoutDiscountBuilder] (`approved: true` set at build time instead of
/// `null`), but driven by a live remote limit check instead of a fixed
/// business rule.
///
/// **Fail-safe, not fail-open:** if the limit API fails, times out, or the
/// available limit is not enough, matching rows are left untouched
/// (`approved: null`) so the existing manual Analyst-approval flow still
/// applies. This call never blocks or throws into the checkout submission
/// pipeline.
class AnalystLimitAutoApprover {
  AnalystLimitAutoApprover({OrderLetterLimitService? limitService})
      : _limitService = limitService ?? OrderLetterLimitService();

  final OrderLetterLimitService _limitService;

  static const _autoApprovedLocationText =
      'Auto-approved sistem — limit tersedia';

  /// Buffer pengaman terhadap race condition check-then-act: `available`
  /// yang dibaca client bisa "basi" beberapa detik kalau ada SP lain dari
  /// analis yang sama sedang diproses bersamaan (belum tercatat di backend
  /// saat kita membaca limit). Mewajibkan sisa `available` setelah dipotong
  /// nominal order ini masih >= 10% dari nominal order ini sendiri, supaya
  /// overlap kecil antar-submit tidak langsung menembus limit riil.
  ///
  /// Ini MENGURANGI, bukan MENGHILANGKAN, race condition tersebut — closing
  /// gap itu sepenuhnya butuh atomic check-and-deduct di backend, yang tidak
  /// bisa dijamin dari client. Lihat dokumentasi kelas ini.
  static const _safetyMarginFraction = 0.10;

  Future<void> apply(List<PendingDetail> pendingDetails) async {
    final pendingAnalystRows = <Map<String, dynamic>>[];
    double totalNominal = 0;
    int? analystUserId;

    for (final detail in pendingDetails) {
      for (final disc in detail.discounts) {
        final level = disc['approver_level']?.toString().toLowerCase();
        if (level != 'analyst') continue;
        if (disc['approved'] != null) continue; // sudah diputuskan sebelumnya

        final nominal = (disc['discount_extra_price'] as num?)?.toDouble() ??
            (disc['discount_price'] as num?)?.toDouble() ??
            0.0;
        if (nominal <= 0) continue;

        totalNominal += nominal;
        analystUserId ??= (disc['approver'] as num?)?.toInt();
        pendingAnalystRows.add(disc);
      }
    }

    final resolvedAnalystUserId = analystUserId;
    if (pendingAnalystRows.isEmpty ||
        resolvedAnalystUserId == null ||
        resolvedAnalystUserId <= 0) {
      return; // Tidak ada baris Analyst yang butuh approval — tidak perlu cek limit.
    }

    final available =
        await _limitService.fetchAvailableLimit(resolvedAnalystUserId);
    if (available == null) {
      Log.warning(
        'Limit Analis tidak terbaca (API gagal/timeout) — '
        'fallback ke approval manual.',
        tag: 'AnalystLimitAutoApprover',
      );
      return;
    }

    final requiredAvailable = totalNominal * (1 + _safetyMarginFraction);
    if (available < requiredAvailable) {
      Log.info(
        'Limit Analis tidak cukup dengan margin pengaman '
        '(available=$available < required=$requiredAvailable, '
        'total=$totalNominal) — fallback ke approval manual.',
        tag: 'AnalystLimitAutoApprover',
      );
      return;
    }

    final now = DateTime.now().toIso8601String();
    for (final disc in pendingAnalystRows) {
      disc['approved'] = true;
      disc['approved_at'] = now;
      disc['lokasi_approval'] = _autoApprovedLocationText;
    }

    Log.info(
      'Analyst auto-approved: user_id=$analystUserId, '
      'total=$totalNominal, available sebelum=$available, '
      'rows=${pendingAnalystRows.length}',
      tag: 'AnalystLimitAutoApprover',
    );

    // Telemetry non-PII untuk tim ops/finance memantau volume & pola
    // auto-approve — juga jadi jejak audit kalau ternyata di kemudian hari
    // ditemukan limit "kebobolan" akibat race condition check-then-act
    // (lihat dokumentasi kelas ini) dan perlu ditindaklanjuti manual.
    AppTelemetry.event(
      'analyst_limit_auto_approved',
      data: {
        'analyst_user_id': analystUserId,
        'total_nominal': totalNominal,
        'available_before': available,
        'rows_count': pendingAnalystRows.length,
      },
      tag: 'AnalystLimitAutoApprover',
    );
  }
}
