import 'approval_inbox_utils.dart';
import 'approval_prior_check.dart';

int _detailRowId(Map<String, dynamic> detail) {
  final raw = detail['id'] ?? detail['order_letter_detail_id'];
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}

/// Dedup baris discount: utamakan id baris; fallback approver+level.
String _discountMergeKey(Map<String, dynamic> disc) {
  final id = discountRowId(disc);
  if (id > 0) return 'id:$id';
  final approver = discountApproverId(disc);
  final level = resolveApproverLevel(disc);
  return 'a:${approver}_l:$level';
}

List<Map<String, dynamic>> _mergeDiscountLists(
  List<dynamic> existing,
  List<dynamic> incoming,
) {
  final byKey = <String, Map<String, dynamic>>{};
  final noKey = <Map<String, dynamic>>[];

  void absorb(List<dynamic> source) {
    for (final d in source) {
      if (d is! Map) continue;
      final map = Map<String, dynamic>.from(d);
      final key = _discountMergeKey(map);
      if (key == 'a:_l:0') {
        noKey.add(map);
        continue;
      }
      byKey.putIfAbsent(key, () => map);
    }
  }

  absorb(existing);
  absorb(incoming);
  return [...byKey.values, ...noKey];
}

/// Gabungkan detail dari wrap tambahan ke shell SP yang sudah ada.
/// Detail dengan id sama → merge discount; tanpa id → append.
void _mergeDetailsIntoShell(
  Map<String, dynamic> shell,
  List<dynamic> incomingDetails,
) {
  final existing = (shell['order_letter_details'] as List<dynamic>? ?? [])
      .whereType<Map<dynamic, dynamic>>()
      .map(Map<String, dynamic>.from)
      .toList();

  final byId = <int, Map<String, dynamic>>{};
  final withoutId = <Map<String, dynamic>>[];
  for (final detail in existing) {
    final id = _detailRowId(detail);
    if (id > 0) {
      byId[id] = detail;
    } else {
      withoutId.add(detail);
    }
  }

  for (final raw in incomingDetails) {
    if (raw is! Map) continue;
    final detail = Map<String, dynamic>.from(raw);
    final id = _detailRowId(detail);
    if (id > 0 && byId.containsKey(id)) {
      final target = byId[id]!;
      target['order_letter_discount'] = _mergeDiscountLists(
        target['order_letter_discount'] as List<dynamic>? ?? const [],
        detail['order_letter_discount'] as List<dynamic>? ?? const [],
      );
    } else if (id > 0) {
      byId[id] = detail;
    } else {
      withoutId.add(detail);
    }
  }

  final merged = [...byId.values, ...withoutId];
  shell['order_letter_details'] = sortOrderLetterDetailsByLineNumber(merged);
}

/// Merge wraps API yang share `order_letter.id` / `no_sp`.
/// Keep-first membuang baris ASM/RSM yang hidup di wrap berikutnya.
List<Map<String, dynamic>> mergeApprovalInboxWraps(List<dynamic> wraps) {
  final grouped = <dynamic, Map<String, dynamic>>{};
  for (final wrap in wraps) {
    if (wrap is! Map) continue;
    final wrapMap = Map<String, dynamic>.from(wrap);
    final letter = wrapMap['order_letter'] as Map<String, dynamic>? ?? {};
    final key = letter['id'] ?? letter['no_sp'] ?? Object.hash(wrapMap, null);
    final incomingDetails =
        wrapMap['order_letter_details'] as List<dynamic>? ?? const [];

    if (!grouped.containsKey(key)) {
      final shell = Map<String, dynamic>.from(wrapMap);
      shell['order_letter_details'] = <dynamic>[];
      _mergeDetailsIntoShell(shell, incomingDetails);
      grouped[key] = shell;
    } else {
      _mergeDetailsIntoShell(grouped[key]!, incomingDetails);
    }
  }
  return grouped.values.toList();
}
