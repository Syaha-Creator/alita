import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:alitapricelist/features/approval/data/repositories/approval_repository.dart';
import 'package:alitapricelist/features/approval/domain/usecases/create_approval_usecase.dart';

import 'create_approval_usecase_test.mocks.dart';

@GenerateMocks([ApprovalRepository])
void main() {
  late CreateApprovalUseCase useCase;
  late MockApprovalRepository mockRepository;

  setUp(() {
    mockRepository = MockApprovalRepository();
    useCase = CreateApprovalUseCase(mockRepository);
  });

  group('CreateApprovalUseCase', () {
    test('should create approval successfully', () async {
      // Arrange
      final expectedResult = {
        'success': true,
        'message': 'Approval created successfully',
        'id': 1,
      };

      when(mockRepository.createApproval(
        orderLetterId: anyNamed('orderLetterId'),
        action: anyNamed('action'),
        approverName: anyNamed('approverName'),
        approverEmail: anyNamed('approverEmail'),
        comment: anyNamed('comment'),
      )).thenAnswer((_) async => expectedResult);

      // Act
      final result = await useCase.call(
        orderLetterId: 100,
        action: 'approve',
        approverName: 'Test Approver',
        approverEmail: 'approver@example.com',
        comment: 'Approved',
      );

      // Assert
      expect(result, equals(expectedResult));
      expect(result['success'], isTrue);
      verify(mockRepository.createApproval(
        orderLetterId: 100,
        action: 'approve',
        approverName: 'Test Approver',
        approverEmail: 'approver@example.com',
        comment: 'Approved',
      )).called(1);
    });

    test('should create rejection successfully', () async {
      // Arrange
      final expectedResult = {
        'success': true,
        'message': 'Rejection created successfully',
        'id': 2,
      };

      when(mockRepository.createApproval(
        orderLetterId: anyNamed('orderLetterId'),
        action: anyNamed('action'),
        approverName: anyNamed('approverName'),
        approverEmail: anyNamed('approverEmail'),
        comment: anyNamed('comment'),
      )).thenAnswer((_) async => expectedResult);

      // Act
      final result = await useCase.call(
        orderLetterId: 100,
        action: 'reject',
        approverName: 'Test Approver',
        approverEmail: 'approver@example.com',
        comment: 'Rejected due to invalid data',
      );

      // Assert
      expect(result, equals(expectedResult));
      expect(result['success'], isTrue);
      verify(mockRepository.createApproval(
        orderLetterId: 100,
        action: 'reject',
        approverName: 'Test Approver',
        approverEmail: 'approver@example.com',
        comment: 'Rejected due to invalid data',
      )).called(1);
    });

    test('should handle approval without comment', () async {
      // Arrange
      final expectedResult = {
        'success': true,
        'message': 'Approval created successfully',
        'id': 3,
      };

      when(mockRepository.createApproval(
        orderLetterId: anyNamed('orderLetterId'),
        action: anyNamed('action'),
        approverName: anyNamed('approverName'),
        approverEmail: anyNamed('approverEmail'),
        comment: anyNamed('comment'),
      )).thenAnswer((_) async => expectedResult);

      // Act
      final result = await useCase.call(
        orderLetterId: 100,
        action: 'approve',
        approverName: 'Test Approver',
        approverEmail: 'approver@example.com',
        comment: null,
      );

      // Assert
      expect(result, equals(expectedResult));
      verify(mockRepository.createApproval(
        orderLetterId: 100,
        action: 'approve',
        approverName: 'Test Approver',
        approverEmail: 'approver@example.com',
        comment: null,
      )).called(1);
    });

    test('should handle empty comment', () async {
      // Arrange
      final expectedResult = {
        'success': true,
        'message': 'Approval created successfully',
        'id': 4,
      };

      when(mockRepository.createApproval(
        orderLetterId: anyNamed('orderLetterId'),
        action: anyNamed('action'),
        approverName: anyNamed('approverName'),
        approverEmail: anyNamed('approverEmail'),
        comment: anyNamed('comment'),
      )).thenAnswer((_) async => expectedResult);

      // Act
      final result = await useCase.call(
        orderLetterId: 100,
        action: 'approve',
        approverName: 'Test Approver',
        approverEmail: 'approver@example.com',
        comment: '',
      );

      // Assert
      expect(result, equals(expectedResult));
      verify(mockRepository.createApproval(
        orderLetterId: 100,
        action: 'approve',
        approverName: 'Test Approver',
        approverEmail: 'approver@example.com',
        comment: '',
      )).called(1);
    });
  });
}
