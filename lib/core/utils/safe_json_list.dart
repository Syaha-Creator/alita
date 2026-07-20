import 'log.dart';

/// Coerces a dynamically-typed JSON value into `List<Map<String, dynamic>>`,
/// skipping any element that isn't a Map.
///
/// Use this instead of `.cast<Map<String, dynamic>>()` whenever the source is
/// untrusted (API response, disk cache, legacy payload) — `.cast` throws a
/// `TypeError` the moment one element doesn't match, while this returns the
/// valid subset instead of crashing.
///
/// [fieldName] is only used for the warning log below — it does not affect
/// parsing. If [decoded] is present but not a `List` at all (e.g. the API
/// changed a field from a list to an object), that is a schema drift, not
/// "no data" — it is logged so it doesn't silently look like an empty list.
List<Map<String, dynamic>> safeMapList(dynamic decoded, {String? fieldName}) {
  if (decoded == null) return const [];
  if (decoded is! List) {
    Log.warning(
      'safeMapList: expected a List${fieldName != null ? ' for "$fieldName"' : ''} '
      'but got ${decoded.runtimeType} — returning empty list instead of the '
      'malformed data.',
    );
    return const [];
  }
  return [
    for (final e in decoded)
      if (e is Map) Map<String, dynamic>.from(e),
  ];
}
