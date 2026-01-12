/// Use case untuk check apakah bonus harus di-upload ke server
class ShouldUploadBonusUseCase {
  bool call(String name, int quantity) {
    if (name.isEmpty) return false;
    final trimmed = name.trim();
    if (trimmed == '0') return false;
    if (trimmed == '-') return false;
    if (quantity <= 0) return false;
    return true;
  }
}
