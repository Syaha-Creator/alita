class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

// Exception untuk masalah jaringan
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}
