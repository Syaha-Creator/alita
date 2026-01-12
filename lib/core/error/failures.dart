import 'package:equatable/equatable.dart';

/// Base class untuk semua failures
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];

  @override
  String toString() => message;
}

/// Failure untuk server errors
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

/// Failure untuk network errors
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred']);
}

/// Failure untuk cache errors
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

/// Failure untuk validation errors
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed']);
}
