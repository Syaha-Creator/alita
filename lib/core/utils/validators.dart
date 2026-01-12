import '../error/exceptions.dart';

/// Utility class untuk validasi data
class Validators {
  /// Validate email format
  static void validateEmail(String email) {
    if (email.trim().isEmpty) {
      throw ValidationException('Email tidak boleh kosong');
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email.trim())) {
      throw ValidationException('Format email tidak valid');
    }
  }

  /// Validate phone number (minimal 10 digit)
  static void validatePhone(String phone) {
    if (phone.trim().isEmpty) {
      throw ValidationException('Nomor telepon tidak boleh kosong');
    }
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 10) {
      throw ValidationException(
        'Nomor telepon harus minimal 10 digit',
      );
    }
  }

  /// Validate required string field
  static void validateRequired(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ValidationException('$fieldName tidak boleh kosong');
    }
  }

  /// Validate non-negative number
  static void validateNonNegative(num value, String fieldName) {
    if (value < 0) {
      throw ValidationException('$fieldName tidak boleh negatif');
    }
  }

  /// Validate positive number
  static void validatePositive(num value, String fieldName) {
    if (value <= 0) {
      throw ValidationException('$fieldName harus lebih dari 0');
    }
  }

  /// Validate date string format (YYYY-MM-DD)
  static void validateDateString(String dateStr, String fieldName) {
    if (dateStr.trim().isEmpty) {
      throw ValidationException('$fieldName tidak boleh kosong');
    }
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(dateStr.trim())) {
      throw ValidationException(
        '$fieldName harus dalam format YYYY-MM-DD',
      );
    }
    try {
      final date = DateTime.parse(dateStr.trim());
      if (date.year < 1900 || date.year > 2100) {
        throw ValidationException(
          '$fieldName harus antara tahun 1900-2100',
        );
      }
    } catch (e) {
      throw ValidationException('$fieldName tidak valid: ${e.toString()}');
    }
  }

  /// Validate list is not empty
  static void validateListNotEmpty<T>(
    List<T> list,
    String fieldName,
  ) {
    if (list.isEmpty) {
      throw ValidationException('$fieldName tidak boleh kosong');
    }
  }

  /// Validate string length
  static void validateStringLength(
    String value,
    String fieldName,
    int minLength,
    int? maxLength,
  ) {
    final length = value.trim().length;
    if (length < minLength) {
      throw ValidationException(
        '$fieldName harus minimal $minLength karakter',
      );
    }
    if (maxLength != null && length > maxLength) {
      throw ValidationException(
        '$fieldName maksimal $maxLength karakter',
      );
    }
  }
}

