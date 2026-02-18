import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:alitapricelist/features/product/data/models/product_model.dart';
import 'package:alitapricelist/features/product/data/repositories/product_repository.dart';
import 'package:alitapricelist/features/product/domain/entities/product_entity.dart';
import 'package:alitapricelist/features/product/domain/usecases/get_product_usecase.dart';

import 'get_product_usecase_test.mocks.dart';

@GenerateMocks([ProductRepository])
void main() {
  late GetProductUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = GetProductUseCase(mockRepository);
  });

  group('GetProductUseCase', () {
    test('should return list of ProductEntity from repository', () async {
      // Arrange
      final productModels = [
        ProductModel(
          id: 1,
          area: 'Jabodetabek',
          channel: 'Retail',
          brand: 'Spring Air',
          kasur: 'Flex Spine',
          divan: '',
          headboard: '',
          sorong: '',
          ukuran: '90x200',
          pricelist: 1000000,
          program: 'Regular',
          eupKasur: 1000000,
          eupDivan: 0,
          eupHeadboard: 0,
          endUserPrice: 1000000,
          set: false,
          bonus1: null,
          bonus2: null,
          bonus3: null,
          bonus4: null,
          bonus5: null,
          qtyBonus1: null,
          qtyBonus2: null,
          qtyBonus3: null,
          qtyBonus4: null,
          qtyBonus5: null,
          disc1: 0.1,
          disc2: 0.05,
          disc3: 0.03,
          disc4: 0.02,
          disc5: 0.01,
          plKasur: 1000000,
          plDivan: 0,
          plHeadboard: 0,
          plSorong: 0,
          eupSorong: 0,
          plBonus1: 0,
          plBonus2: 0,
          plBonus3: 0,
          plBonus4: 0,
          plBonus5: 0,
          plBonus6: 0,
          plBonus7: 0,
          plBonus8: 0,
          bottomPriceAnalyst: 800000,
          itemNumber: null,
          itemNumberKasur: null,
          itemNumberDivan: null,
          itemNumberHeadboard: null,
          itemNumberSorong: null,
          itemNumberAccessories: null,
          itemNumberBonus1: null,
          itemNumberBonus2: null,
          itemNumberBonus3: null,
          itemNumberBonus4: null,
          itemNumberBonus5: null,
        ),
      ];

      when(mockRepository.fetchProductsWithFilter(
        area: anyNamed('area'),
        channel: anyNamed('channel'),
        brand: anyNamed('brand'),
      )).thenAnswer((_) async => productModels);

      // Act
      final result = await useCase.callWithFilter(
        area: 'Jabodetabek',
        channel: 'Retail',
        brand: 'Spring Air',
      );

      // Assert
      expect(result, isA<List<ProductEntity>>());
      expect(result.length, equals(1));
      expect(result.first.id, equals(1));
      expect(result.first.area, equals('Jabodetabek'));
      expect(result.first.channel, equals('Retail'));
      expect(result.first.brand, equals('Spring Air'));
      expect(result.first.kasur, equals('Flex Spine'));
      verify(mockRepository.fetchProductsWithFilter(
        area: 'Jabodetabek',
        channel: 'Retail',
        brand: 'Spring Air',
      )).called(1);
    });

    test('should return empty list when repository returns empty list',
        () async {
      // Arrange
      when(mockRepository.fetchProductsWithFilter(
        area: anyNamed('area'),
        channel: anyNamed('channel'),
        brand: anyNamed('brand'),
      )).thenAnswer((_) async => <ProductModel>[]);

      // Act
      final result = await useCase.callWithFilter(
        area: 'Jabodetabek',
        channel: 'Retail',
        brand: 'Spring Air',
      );

      // Assert
      expect(result, isEmpty);
      verify(mockRepository.fetchProductsWithFilter(
        area: 'Jabodetabek',
        channel: 'Retail',
        brand: 'Spring Air',
      )).called(1);
    });

    test('should convert ProductModel to ProductEntity correctly', () async {
      // Arrange
      final productModel = ProductModel(
        id: 1,
        area: 'Jabodetabek',
        channel: 'Retail',
        brand: 'Spring Air',
        kasur: 'Flex Spine',
        divan: 'Tanpa Divan',
        headboard: 'Tanpa Headboard',
        sorong: 'Tanpa Sorong',
        ukuran: '90x200',
        pricelist: 1000000,
        program: 'Regular',
        eupKasur: 1000000,
        eupDivan: 0,
        eupHeadboard: 0,
        endUserPrice: 1000000,
        set: false,
        bonus1: 'Bonus 1',
        bonus2: 'Bonus 2',
        bonus3: null,
        bonus4: null,
        bonus5: null,
        qtyBonus1: 1,
        qtyBonus2: 2,
        qtyBonus3: null,
        qtyBonus4: null,
        qtyBonus5: null,
        disc1: 0.1,
        disc2: 0.05,
        disc3: 0.03,
        disc4: 0.02,
        disc5: 0.01,
        plKasur: 1000000,
        plDivan: 500000,
        plHeadboard: 300000,
        plSorong: 200000,
        eupSorong: 200000,
        plBonus1: 0,
        plBonus2: 0,
        plBonus3: 0,
        plBonus4: 0,
        plBonus5: 0,
        plBonus6: 0,
        plBonus7: 0,
        plBonus8: 0,
        bottomPriceAnalyst: 800000,
        itemNumber: 'ITEM001',
        itemNumberKasur: 'KASUR001',
        itemNumberDivan: 'DIVAN001',
        itemNumberHeadboard: 'HEAD001',
        itemNumberSorong: 'SORONG001',
        itemNumberAccessories: 'ACC001',
        itemNumberBonus1: 'BONUS001',
        itemNumberBonus2: 'BONUS002',
        itemNumberBonus3: null,
        itemNumberBonus4: null,
        itemNumberBonus5: null,
      );

      when(mockRepository.fetchProductsWithFilter(
        area: anyNamed('area'),
        channel: anyNamed('channel'),
        brand: anyNamed('brand'),
      )).thenAnswer((_) async => [productModel]);

      // Act
      final result = await useCase.callWithFilter(
        area: 'Jabodetabek',
        channel: 'Retail',
        brand: 'Spring Air',
      );

      // Assert
      expect(result.length, equals(1));
      final entity = result.first;
      expect(entity.id, equals(1));
      expect(entity.area, equals('Jabodetabek'));
      expect(entity.channel, equals('Retail'));
      expect(entity.brand, equals('Spring Air'));
      expect(entity.kasur, equals('Flex Spine'));
      expect(entity.divan, equals('Tanpa Divan'));
      expect(entity.headboard, equals('Tanpa Headboard'));
      expect(entity.sorong, equals('Tanpa Sorong'));
      expect(entity.ukuran, equals('90x200'));
      expect(entity.pricelist, equals(1000000));
      expect(entity.program, equals('Regular'));
      expect(entity.endUserPrice, equals(1000000));
      expect(entity.isSet, equals(false));
      expect(entity.bonus.length, equals(2));
      expect(entity.bonus[0].name, equals('Bonus 1'));
      expect(entity.bonus[0].quantity, equals(1));
      expect(entity.bonus[1].name, equals('Bonus 2'));
      expect(entity.bonus[1].quantity, equals(2));
      expect(entity.discounts, equals([0.1, 0.05, 0.03, 0.02, 0.01]));
      expect(entity.itemNumber, equals('ITEM001'));
      expect(entity.itemNumberKasur, equals('KASUR001'));
      expect(entity.itemNumberDivan, equals('DIVAN001'));
      expect(entity.itemNumberHeadboard, equals('HEAD001'));
      expect(entity.itemNumberSorong, equals('SORONG001'));
      expect(entity.itemNumberAccessories, equals('ACC001'));
      expect(entity.itemNumberBonus1, equals('BONUS001'));
      expect(entity.itemNumberBonus2, equals('BONUS002'));
    });

    test('should handle products with all bonus items', () async {
      // Arrange
      final productModel = ProductModel(
        id: 1,
        area: 'Jabodetabek',
        channel: 'Retail',
        brand: 'Spring Air',
        kasur: 'Flex Spine',
        divan: '',
        headboard: '',
        sorong: '',
        ukuran: '90x200',
        pricelist: 1000000,
        program: 'Regular',
        eupKasur: 1000000,
        eupDivan: 0,
        eupHeadboard: 0,
        endUserPrice: 1000000,
        set: false,
        bonus1: 'Bonus 1',
        bonus2: 'Bonus 2',
        bonus3: 'Bonus 3',
        bonus4: 'Bonus 4',
        bonus5: 'Bonus 5',
        qtyBonus1: 1,
        qtyBonus2: 2,
        qtyBonus3: 3,
        qtyBonus4: 4,
        qtyBonus5: 5,
        disc1: 0.1,
        disc2: 0.05,
        disc3: 0.03,
        disc4: 0.02,
        disc5: 0.01,
        plKasur: 1000000,
        plDivan: 0,
        plHeadboard: 0,
        plSorong: 0,
        eupSorong: 0,
        plBonus1: 0,
        plBonus2: 0,
        plBonus3: 0,
        plBonus4: 0,
        plBonus5: 0,
        plBonus6: 0,
        plBonus7: 0,
        plBonus8: 0,
        bottomPriceAnalyst: 800000,
        itemNumber: null,
        itemNumberKasur: null,
        itemNumberDivan: null,
        itemNumberHeadboard: null,
        itemNumberSorong: null,
        itemNumberAccessories: null,
        itemNumberBonus1: null,
        itemNumberBonus2: null,
        itemNumberBonus3: null,
        itemNumberBonus4: null,
        itemNumberBonus5: null,
      );

      when(mockRepository.fetchProductsWithFilter(
        area: anyNamed('area'),
        channel: anyNamed('channel'),
        brand: anyNamed('brand'),
      )).thenAnswer((_) async => [productModel]);

      // Act
      final result = await useCase.callWithFilter(
        area: 'Jabodetabek',
        channel: 'Retail',
        brand: 'Spring Air',
      );

      // Assert
      expect(result.length, equals(1));
      expect(result.first.bonus.length, equals(5));
      expect(result.first.bonus[0].name, equals('Bonus 1'));
      expect(result.first.bonus[4].name, equals('Bonus 5'));
    });

    test('should handle products with no bonus items', () async {
      // Arrange
      final productModel = ProductModel(
        id: 1,
        area: 'Jabodetabek',
        channel: 'Retail',
        brand: 'Spring Air',
        kasur: 'Flex Spine',
        divan: '',
        headboard: '',
        sorong: '',
        ukuran: '90x200',
        pricelist: 1000000,
        program: 'Regular',
        eupKasur: 1000000,
        eupDivan: 0,
        eupHeadboard: 0,
        endUserPrice: 1000000,
        set: false,
        bonus1: null,
        bonus2: null,
        bonus3: null,
        bonus4: null,
        bonus5: null,
        qtyBonus1: null,
        qtyBonus2: null,
        qtyBonus3: null,
        qtyBonus4: null,
        qtyBonus5: null,
        disc1: 0.1,
        disc2: 0.05,
        disc3: 0.03,
        disc4: 0.02,
        disc5: 0.01,
        plKasur: 1000000,
        plDivan: 0,
        plHeadboard: 0,
        plSorong: 0,
        eupSorong: 0,
        plBonus1: 0,
        plBonus2: 0,
        plBonus3: 0,
        plBonus4: 0,
        plBonus5: 0,
        plBonus6: 0,
        plBonus7: 0,
        plBonus8: 0,
        bottomPriceAnalyst: 800000,
        itemNumber: null,
        itemNumberKasur: null,
        itemNumberDivan: null,
        itemNumberHeadboard: null,
        itemNumberSorong: null,
        itemNumberAccessories: null,
        itemNumberBonus1: null,
        itemNumberBonus2: null,
        itemNumberBonus3: null,
        itemNumberBonus4: null,
        itemNumberBonus5: null,
      );

      when(mockRepository.fetchProductsWithFilter(
        area: anyNamed('area'),
        channel: anyNamed('channel'),
        brand: anyNamed('brand'),
      )).thenAnswer((_) async => [productModel]);

      // Act
      final result = await useCase.callWithFilter(
        area: 'Jabodetabek',
        channel: 'Retail',
        brand: 'Spring Air',
      );

      // Assert
      expect(result.length, equals(1));
      expect(result.first.bonus, isEmpty);
    });
  });
}
