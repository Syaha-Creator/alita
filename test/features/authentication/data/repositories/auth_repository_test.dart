import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:alitapricelist/core/error/exceptions.dart';
import 'package:alitapricelist/features/authentication/data/models/auth_model.dart';
import 'package:alitapricelist/features/authentication/data/repositories/auth_repository.dart';
import 'package:alitapricelist/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:alitapricelist/features/authentication/data/datasources/auth_local_data_source.dart';
import 'package:alitapricelist/services/api_client.dart';

import 'auth_repository_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  group('AuthRepository Tests', () {
    late AuthRepository repository;
    late MockApiClient mockApiClient;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Load test env file to provide required API keys (absolute path)
      final envPath =
          '${Directory.current.path}/test/.env_test'; // ensure file is found
      await dotenv.load(fileName: envPath);
    });

    setUp(() {
      mockApiClient = MockApiClient();
      final remoteDataSource = AuthRemoteDataSourceImpl(apiClient: mockApiClient);
      final localDataSource = AuthLocalDataSourceImpl();
      repository = AuthRepository(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
    });

    group('login', () {
      test('should return AuthModel on successful login', () async {
        // Arrange
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          data: {
            'access_token': 'test_token_123',
            'refresh_token': 'refresh_token_123',
            'token_type': 'Bearer',
            'id': 1,
            'name': 'Test User',
            'email': 'test@example.com',
            'area_id': 1,
            'area': 'Jabodetabek',
          },
        );

        when(mockApiClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result =
            await repository.login('test@example.com', 'password123');

        // Assert
        expect(result, isA<AuthModel>());
        expect(result.accessToken, 'test_token_123');
        expect(result.refreshToken, 'refresh_token_123');
        expect(result.id, 1);
        expect(result.name, 'Test User');
        verify(mockApiClient.post(any, data: anyNamed('data'))).called(1);
      });

      test('should throw NetworkException on connection timeout', () async {
        // Arrange
        when(mockApiClient.post(any, data: anyNamed('data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        // Act & Assert
        expect(
          () => repository.login('test@example.com', 'password123'),
          throwsA(isA<NetworkException>()),
        );
      });

      test('should throw NetworkException on connection error', () async {
        // Arrange
        when(mockApiClient.post(any, data: anyNamed('data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.connectionError,
          ),
        );

        // Act & Assert
        expect(
          () => repository.login('test@example.com', 'password123'),
          throwsA(isA<NetworkException>()),
        );
      });

      test('should throw ServerException on 401 error (wrong credentials)',
          () async {
        // Arrange
        when(mockApiClient.post(any, data: anyNamed('data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            response: Response(
              requestOptions: RequestOptions(path: '/test'),
              statusCode: 401,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        // Act & Assert
        expect(
          () => repository.login('wrong@example.com', 'wrongpassword'),
          throwsA(isA<ServerException>()),
        );
      });

      test('should throw ServerException on 500 error', () async {
        // Arrange
        when(mockApiClient.post(any, data: anyNamed('data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/test'),
            response: Response(
              requestOptions: RequestOptions(path: '/test'),
              statusCode: 500,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        // Act & Assert
        expect(
          () => repository.login('test@example.com', 'password123'),
          throwsA(isA<ServerException>()),
        );
      });

      test('should throw Exception when status code is not 200', () async {
        // Arrange
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: null,
        );

        when(mockApiClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.login('test@example.com', 'password123'),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw Exception when response data is null', () async {
        // Arrange
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          data: null,
        );

        when(mockApiClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.login('test@example.com', 'password123'),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw Exception when response data is not Map', () async {
        // Arrange
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          data: 'not a map',
        );

        when(mockApiClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.login('test@example.com', 'password123'),
          throwsA(isA<Exception>()),
        );
      });

      test('should call API with correct parameters', () async {
        // Arrange
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          data: {
            'token': 'test_token_123',
            'refresh_token': 'refresh_token_123',
            'user': {
              'id': 1,
              'name': 'Test User',
              'email': 'test@example.com',
            },
            'area_id': 1,
            'area_name': 'Jabodetabek',
          },
        );

        when(mockApiClient.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.login('test@example.com', 'password123');

        // Assert
        // Note: client_id and client_secret are now in URL query parameters, not in body
        verify(mockApiClient.post(
          any,
          data: argThat(
            predicate<Map<String, dynamic>>(
              (data) =>
                  data['email'] == 'test@example.com' &&
                  data['password'] == 'password123',
            ),
            named: 'data',
          ),
        )).called(1);
      });
    });
  });
}
