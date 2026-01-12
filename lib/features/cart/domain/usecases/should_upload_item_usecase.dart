/// Use case untuk check apakah item value harus di-upload ke server
/// Returns false untuk empty, invalid, atau "tanpa" items
class ShouldUploadItemUseCase {
  bool call(String value) {
    if (value.isEmpty) return false;
    final trimmed = value.trim();
    if (trimmed == '-') return false;
    if (trimmed == '0') return false;
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('tanpa')) return false;
    if (lower == 'tidak ada kasur') return false;
    if (lower == 'tidak ada divan') return false;
    if (lower == 'tidak ada headboard') return false;
    if (lower == 'tidak ada sorong') return false;
    return true;
  }
}
