/// Normalisasi field API `take_away` ke boolean.
///
/// Backend mengirim `null`, `true`/`false`, atau string `"TAKE AWAY"` (detail baris).
bool parseTakeAway(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  final s = value.toString().trim();
  if (s.isEmpty) return false;
  if (s.toUpperCase() == 'TAKE AWAY') return true;
  if (s == '1') return true;
  final lower = s.toLowerCase();
  if (lower == 'true' || lower == 'yes') return true;
  return false;
}
