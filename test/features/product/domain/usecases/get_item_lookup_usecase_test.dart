import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:alitapricelist/features/product/domain/entities/item_lookup_entity.dart';
import 'package:alitapricelist/features/product/domain/repositories/item_lookup_repository.dart';
import 'package:alitapricelist/features/product/domain/usecases/get_item_lookup_usecase.dart';

import 'get_item_lookup_usecase_test.mocks.dart';

@GenerateMocks([ItemLookupRepository])
void main() {
  late GetItemLookupUsecase useCase;
  late MockItemLookupRepository mockRepository;

  setUp(() {
    mockRepository = MockItemLookupRepository();
    useCase = GetItemLookupUsecase(repository: mockRepository);
  });

  group('GetItemLookupUsecase', () {
    test('should return list of ItemLookupEntity from repository', () async {
      // Arrange
      final itemLookups = [
        ItemLookupEntity(
          id: 1,
          itemNum: 'ITEM001',
          itemDesc: 'Item Description 1',
          brand: 'Brand A',
          tipe: 'Type A',
          tebal: '10',
          ukuran: '90x200',
          jenisKain: 'Cotton',
          berat: '5kg',
          kubikasi: '1.5',
          createdAt: '2024-01-01',
          updatedAt: '2024-01-01',
        ),
        ItemLookupEntity(
          id: 2,
          itemNum: 'ITEM002',
          itemDesc: 'Item Description 2',
          brand: 'Brand B',
          tipe: 'Type B',
          tebal: '15',
          ukuran: '120x200',
          jenisKain: 'Polyester',
          berat: '6kg',
          kubikasi: '2.0',
          createdAt: '2024-01-02',
          updatedAt: '2024-01-02',
        ),
      ];

      when(mockRepository.fetchItemLookups())
          .thenAnswer((_) async => itemLookups);

      // Act
      final result = await useCase.call();

      // Assert
      expect(result, isA<List<ItemLookupEntity>>());
      expect(result.length, equals(2));
      expect(result[0].id, equals(1));
      expect(result[0].itemNum, equals('ITEM001'));
      expect(result[1].id, equals(2));
      expect(result[1].itemNum, equals('ITEM002'));
      verify(mockRepository.fetchItemLookups()).called(1);
    });

    test('should return empty list when repository returns empty list',
        () async {
      // Arrange
      when(mockRepository.fetchItemLookups())
          .thenAnswer((_) async => <ItemLookupEntity>[]);

      // Act
      final result = await useCase.call();

      // Assert
      expect(result, isEmpty);
      verify(mockRepository.fetchItemLookups()).called(1);
    });

    test('should rethrow exception when repository throws error', () async {
      // Arrange
      when(mockRepository.fetchItemLookups())
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => useCase.call(),
        throwsA(isA<Exception>()),
      );
      verify(mockRepository.fetchItemLookups()).called(1);
    });

    test('should handle single item lookup', () async {
      // Arrange
      final itemLookups = [
        ItemLookupEntity(
          id: 1,
          itemNum: 'ITEM001',
          itemDesc: 'Item Description 1',
          brand: 'Brand A',
          tipe: 'Type A',
          tebal: '10',
          ukuran: '90x200',
          jenisKain: 'Cotton',
          berat: '5kg',
          kubikasi: '1.5',
          createdAt: '2024-01-01',
          updatedAt: '2024-01-01',
        ),
      ];

      when(mockRepository.fetchItemLookups())
          .thenAnswer((_) async => itemLookups);

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.length, equals(1));
      expect(result.first.id, equals(1));
      expect(result.first.itemNum, equals('ITEM001'));
    });
  });
}
