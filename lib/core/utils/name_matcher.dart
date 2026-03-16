/// Utility for tolerant person-name matching.
class NameMatcher {
  NameMatcher._();

  /// Soft-match two names to tolerate short forms from backend data.
  static bool softMatch(String name1, String name2) {
    if (name1.isEmpty || name2.isEmpty) return false;

    final n1 = name1.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').trim();
    final n2 = name2.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').trim();

    if (n1 == n2) return true;

    final parts1 = n1.split(' ');
    final parts2 = n2.split(' ');

    if (parts1.length > 1 && parts2.length > 1) {
      return parts1[0] == parts2[0] && parts1[1] == parts2[1];
    }

    return parts1.isNotEmpty && parts2.isNotEmpty && parts1[0] == parts2[0];
  }
}
