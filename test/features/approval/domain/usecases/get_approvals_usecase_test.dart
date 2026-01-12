import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:alitapricelist/features/approval/data/repositories/approval_repository.dart';
import 'package:alitapricelist/features/approval/domain/entities/approval_entity.dart';
import 'package:alitapricelist/features/approval/domain/usecases/get_approvals_usecase.dart';

import 'get_approvals_usecase_test.mocks.dart';

@GenerateMocks([ApprovalRepository])
void main() {
  late GetApprovalsUseCase useCase;
  late MockApprovalRepository mockRepository;

  setUp(() {
    mockRepository = MockApprovalRepository();
    useCase = GetApprovalsUseCase(mockRepository);
  });

  group('GetApprovalsUseCase', () {
    test('should return list of ApprovalEntity from repository', () async {
      // Arrange
      final approvals = [
        ApprovalEntity(
          id: 1,
          noSp: 'SP001',
          orderDate: '2024-01-01',
          requestDate: '2024-01-01',
          creator: 'Test User',
          customerName: 'Customer 1',
          phone: '081234567890',
          email: 'customer1@example.com',
          address: 'Address 1',
          extendedAmount: 1000000,
          hargaAwal: 1000000,
          note: 'Note 1',
          status: 'pending',
          details: const [],
          discounts: const [],
          approvalHistory: const [],
        ),
        ApprovalEntity(
          id: 2,
          noSp: 'SP002',
          orderDate: '2024-01-02',
          requestDate: '2024-01-02',
          creator: 'Test User 2',
          customerName: 'Customer 2',
          phone: '081234567891',
          email: 'customer2@example.com',
          address: 'Address 2',
          extendedAmount: 2000000,
          hargaAwal: 2000000,
          note: 'Note 2',
          status: 'approved',
          details: const [],
          discounts: const [],
          approvalHistory: const [],
        ),
      ];

      when(mockRepository.getApprovals(
        creator: anyNamed('creator'),
        forceRefresh: anyNamed('forceRefresh'),
        dateFrom: anyNamed('dateFrom'),
        dateTo: anyNamed('dateTo'),
      )).thenAnswer((_) async => approvals);

      // Act
      final result = await useCase.call();

      // Assert
      expect(result, isA<List<ApprovalEntity>>());
      expect(result.length, equals(2));
      expect(result[0].id, equals(1));
      expect(result[1].id, equals(2));
      verify(mockRepository.getApprovals(
        creator: null,
        forceRefresh: false,
        dateFrom: null,
        dateTo: null,
      )).called(1);
    });

    test('should pass filters to repository', () async {
      // Arrange
      when(mockRepository.getApprovals(
        creator: anyNamed('creator'),
        forceRefresh: anyNamed('forceRefresh'),
        dateFrom: anyNamed('dateFrom'),
        dateTo: anyNamed('dateTo'),
      )).thenAnswer((_) async => []);

      // Act
      await useCase.call(
        creator: 'Test User',
        forceRefresh: true,
        dateFrom: '2024-01-01',
        dateTo: '2024-12-31',
      );

      // Assert
      verify(mockRepository.getApprovals(
        creator: 'Test User',
        forceRefresh: true,
        dateFrom: '2024-01-01',
        dateTo: '2024-12-31',
      )).called(1);
    });

    test('should return empty list when repository returns empty list',
        () async {
      // Arrange
      when(mockRepository.getApprovals(
        creator: anyNamed('creator'),
        forceRefresh: anyNamed('forceRefresh'),
        dateFrom: anyNamed('dateFrom'),
        dateTo: anyNamed('dateTo'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await useCase.call();

      // Assert
      expect(result, isEmpty);
    });
  });

  group('GetApprovalByIdUseCase', () {
    late GetApprovalByIdUseCase getByIdUseCase;

    setUp(() {
      getByIdUseCase = GetApprovalByIdUseCase(mockRepository);
    });

    test('should return ApprovalEntity when found', () async {
      // Arrange
      final approval = ApprovalEntity(
        id: 1,
        noSp: 'SP001',
        orderDate: '2024-01-01',
        requestDate: '2024-01-01',
        creator: 'Test User',
        customerName: 'Customer 1',
        phone: '081234567890',
        email: 'customer1@example.com',
        address: 'Address 1',
        extendedAmount: 1000000,
        hargaAwal: 1000000,
        note: 'Note 1',
        status: 'pending',
        details: const [],
        discounts: const [],
        approvalHistory: const [],
      );

      when(mockRepository.getApprovalById(any))
          .thenAnswer((_) async => approval);

      // Act
      final result = await getByIdUseCase.call(100);

      // Assert
      expect(result, isNotNull);
      expect(result?.id, equals(1));
      expect(result?.noSp, equals('SP001'));
      verify(mockRepository.getApprovalById(100)).called(1);
    });

    test('should return null when not found', () async {
      // Arrange
      when(mockRepository.getApprovalById(any)).thenAnswer((_) async => null);

      // Act
      final result = await getByIdUseCase.call(999);

      // Assert
      expect(result, isNull);
      verify(mockRepository.getApprovalById(999)).called(1);
    });
  });

  group('GetPendingApprovalsUseCase', () {
    late GetPendingApprovalsUseCase getPendingUseCase;

    setUp(() {
      getPendingUseCase = GetPendingApprovalsUseCase(mockRepository);
    });

    test('should return pending approvals from repository', () async {
      // Arrange
      final approvals = [
        ApprovalEntity(
          id: 1,
          noSp: 'SP001',
          orderDate: '2024-01-01',
          requestDate: '2024-01-01',
          creator: 'Test User',
          customerName: 'Customer 1',
          phone: '081234567890',
          email: 'customer1@example.com',
          address: 'Address 1',
          extendedAmount: 1000000,
          hargaAwal: 1000000,
          note: 'Note 1',
          status: 'pending',
          details: const [],
          discounts: const [],
          approvalHistory: const [],
        ),
      ];

      when(mockRepository.getPendingApprovals())
          .thenAnswer((_) async => approvals);

      // Act
      final result = await getPendingUseCase.call();

      // Assert
      expect(result.length, equals(1));
      expect(result[0].status, equals('pending'));
      verify(mockRepository.getPendingApprovals()).called(1);
    });
  });

  group('GetApprovedApprovalsUseCase', () {
    late GetApprovedApprovalsUseCase getApprovedUseCase;

    setUp(() {
      getApprovedUseCase = GetApprovedApprovalsUseCase(mockRepository);
    });

    test('should return approved approvals from repository', () async {
      // Arrange
      final approvals = [
        ApprovalEntity(
          id: 1,
          noSp: 'SP001',
          orderDate: '2024-01-01',
          requestDate: '2024-01-01',
          creator: 'Test User',
          customerName: 'Customer 1',
          phone: '081234567890',
          email: 'customer1@example.com',
          address: 'Address 1',
          extendedAmount: 1000000,
          hargaAwal: 1000000,
          note: 'Note 1',
          status: 'approved',
          details: const [],
          discounts: const [],
          approvalHistory: const [],
        ),
      ];

      when(mockRepository.getApprovedApprovals())
          .thenAnswer((_) async => approvals);

      // Act
      final result = await getApprovedUseCase.call();

      // Assert
      expect(result.length, equals(1));
      expect(result[0].status, equals('approved'));
      verify(mockRepository.getApprovedApprovals()).called(1);
    });
  });

  group('GetRejectedApprovalsUseCase', () {
    late GetRejectedApprovalsUseCase getRejectedUseCase;

    setUp(() {
      getRejectedUseCase = GetRejectedApprovalsUseCase(mockRepository);
    });

    test('should return rejected approvals from repository', () async {
      // Arrange
      final approvals = [
        ApprovalEntity(
          id: 1,
          noSp: 'SP001',
          orderDate: '2024-01-01',
          requestDate: '2024-01-01',
          creator: 'Test User',
          customerName: 'Customer 1',
          phone: '081234567890',
          email: 'customer1@example.com',
          address: 'Address 1',
          extendedAmount: 1000000,
          hargaAwal: 1000000,
          note: 'Note 1',
          status: 'rejected',
          details: const [],
          discounts: const [],
          approvalHistory: const [],
        ),
      ];

      when(mockRepository.getRejectedApprovals())
          .thenAnswer((_) async => approvals);

      // Act
      final result = await getRejectedUseCase.call();

      // Assert
      expect(result.length, equals(1));
      expect(result[0].status, equals('rejected'));
      verify(mockRepository.getRejectedApprovals()).called(1);
    });
  });
}
