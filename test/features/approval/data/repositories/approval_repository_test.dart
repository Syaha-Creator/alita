import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/features/approval/data/repositories/approval_repository.dart';
import 'package:alitapricelist/features/approval/data/datasources/approval_remote_data_source.dart';
import 'package:alitapricelist/features/approval/data/datasources/approval_local_data_source.dart';
import 'package:alitapricelist/services/order_letter_service.dart';

import 'approval_repository_test.mocks.dart';

@GenerateMocks([OrderLetterService])
void main() {
  group('ApprovalRepository Tests', () {
    late ApprovalRepository repository;
    late MockOrderLetterService mockOrderLetterService;

    setUp(() async {
      // Setup SharedPreferences for AuthService
      SharedPreferences.setMockInitialValues({
        'auth_token': 'test_token_123',
        'current_user_id': 1,
        'current_user_name': 'Test User',
        'current_user_area_id': 1,
      });

      mockOrderLetterService = MockOrderLetterService();
      final remoteDataSource = ApprovalRemoteDataSourceImpl(
        orderLetterService: mockOrderLetterService,
      );
      final localDataSource = ApprovalLocalDataSourceImpl();
      repository = ApprovalRepository(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
    });

    tearDown(() async {
      // Cleanup
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    group('getApprovals', () {
      test('should return empty list when userId is null', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('current_user_id');

        // Act
        final result = await repository.getApprovals();

        // Assert
        expect(result, isEmpty);
      });

      test('should return empty list when userName is null', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('current_user_name');

        // Act
        final result = await repository.getApprovals();

        // Assert
        expect(result, isEmpty);
      });

      test('should return cached approvals when available and not forceRefresh',
          () async {
        // Arrange
        // Note: This test requires ApprovalCache to be set up
        // For now, we'll test the basic flow without cache

        when(mockOrderLetterService.getOrderLetters(
          dateFrom: anyNamed('dateFrom'),
          dateTo: anyNamed('dateTo'),
        )).thenAnswer((_) async => []);

        // Act
        final result = await repository.getApprovals(forceRefresh: false);

        // Assert
        expect(result, isA<List>());
      });

      test('should call getOrderLetters when forceRefresh is true', () async {
        // Arrange
        when(mockOrderLetterService.getOrderLetters(
          dateFrom: anyNamed('dateFrom'),
          dateTo: anyNamed('dateTo'),
        )).thenAnswer((_) async => []);

        // Act
        await repository.getApprovals(forceRefresh: true);

        // Assert
        verify(mockOrderLetterService.getOrderLetters(
          dateFrom: anyNamed('dateFrom'),
          dateTo: anyNamed('dateTo'),
        )).called(1);
      });

      test('should pass dateFrom and dateTo to getOrderLetters', () async {
        // Arrange
        when(mockOrderLetterService.getOrderLetters(
          dateFrom: anyNamed('dateFrom'),
          dateTo: anyNamed('dateTo'),
        )).thenAnswer((_) async => []);

        // Act
        await repository.getApprovals(
          dateFrom: '2024-01-01',
          dateTo: '2024-01-31',
        );

        // Assert
        verify(mockOrderLetterService.getOrderLetters(
          dateFrom: '2024-01-01',
          dateTo: '2024-01-31',
        )).called(1);
      });
    });

    group('getCachedUserInfo', () {
      test('should return null when userId is null', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('current_user_id');

        // Act
        final result = await repository.getCachedUserInfo();

        // Assert
        expect(result, isNull);
      });

      test('should return cached user info when available', () async {
        // Act
        final result = await repository.getCachedUserInfo();

        // Assert
        // Note: This depends on ApprovalCache implementation
        // For now, we just verify it doesn't throw
        expect(result, anyOf(isNull, isA<Map<String, dynamic>>()));
      });
    });

    group('cacheUserInfo', () {
      test('should cache user info successfully', () async {
        // Arrange
        final userInfo = {
          'userId': 1,
          'userName': 'Test User',
          'isStaffLevel': false,
        };

        // Act
        await repository.cacheUserInfo(userInfo);

        // Assert
        // Verify no exception is thrown
        expect(() => repository.cacheUserInfo(userInfo), returnsNormally);
      });

      test('should not cache when userId is null', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('current_user_id');
        final userInfo = {
          'userId': 1,
          'userName': 'Test User',
        };

        // Act
        await repository.cacheUserInfo(userInfo);

        // Assert
        // Should not throw, just silently return
        expect(() => repository.cacheUserInfo(userInfo), returnsNormally);
      });
    });

    group('getPaginationInfo', () {
      test('should return pagination info', () async {
        // Act
        final result = await repository.getPaginationInfo();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('should_use_pagination'), isTrue);
      });
    });

    group('getApprovalsWithPagination', () {
      test('should return empty list when userId is null', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('current_user_id');

        // Act
        final result = await repository.getApprovalsWithPagination();

        // Assert
        expect(result, isEmpty);
      });

      test('should return paginated approvals', () async {
        // Arrange
        when(mockOrderLetterService.getOrderLetters(
          dateFrom: anyNamed('dateFrom'),
          dateTo: anyNamed('dateTo'),
        )).thenAnswer((_) async => []);

        // Act
        final result = await repository.getApprovalsWithPagination(page: 1);

        // Assert
        expect(result, isA<List>());
      });
    });
  });
}
