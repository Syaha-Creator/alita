import 'package:dio/dio.dart';
import '../error/exceptions.dart';

/// Helper untuk convert DioException ke custom exceptions
/// 
/// Digunakan untuk standardize error handling di seluruh aplikasi
class ExceptionHelper {
  /// Convert DioException ke custom exception berdasarkan error type
  /// 
  /// Rules:
  /// - Connection timeout/error → NetworkException
  /// - Server error (5xx) → ServerException
  /// - Client error (4xx) → ServerException (dengan pesan yang lebih jelas)
  /// - Unknown error → ServerException
  static Exception convertDioException(DioException e) {
    // Network errors (timeout, connection error)
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException(
        "Request timeout. Server mungkin sedang sibuk. Silakan coba lagi.",
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return NetworkException(
        "Gagal terhubung ke server. Periksa koneksi internet Anda.",
      );
    }

    // Server errors (5xx)
    if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
      // Check for Phusion Passenger error (server down)
      if (e.response?.data is String &&
          (e.response?.data as String).contains("Phusion Passenger") &&
          (e.response?.data as String)
              .contains("Web application could not be started")) {
        return ServerException(
          "Server sedang dalam maintenance. Silakan coba lagi dalam beberapa saat.",
        );
      }

      return ServerException(
        "Server error (${e.response?.statusCode}). Silakan coba lagi dalam beberapa saat.",
      );
    }

    // Client errors (4xx)
    if (e.response?.statusCode != null && e.response!.statusCode! >= 400) {
      final statusCode = e.response!.statusCode!;
      String message;

      switch (statusCode) {
        case 400:
          message = "Request tidak valid. Periksa data yang dikirim.";
          break;
        case 401:
          message = "Tidak terautentikasi. Silakan login kembali.";
          break;
        case 403:
          message = "Akses ditolak. Anda tidak memiliki izin untuk operasi ini.";
          break;
        case 404:
          message = "Data tidak ditemukan.";
          break;
        default:
          message = "Error client ($statusCode). Periksa data yang dikirim.";
      }

      return ServerException(message);
    }

    // Unknown error
    return ServerException(
      "Terjadi kesalahan: ${e.message ?? 'Unknown error'}",
    );
  }

  /// Convert generic Exception ke ServerException
  /// 
  /// Digunakan untuk catch-all error handling
  static Exception convertGenericException(dynamic e) {
    if (e is ServerException || e is NetworkException || e is CacheException) {
      return e;
    }

    if (e is DioException) {
      return convertDioException(e);
    }

    return ServerException(
      "Terjadi kesalahan yang tidak diketahui: ${e.toString()}",
    );
  }
}

