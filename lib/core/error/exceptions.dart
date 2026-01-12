class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

// Exception untuk masalah jaringan
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

// Exception untuk masalah cache/local storage
class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}

// Exception untuk validasi data
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}
