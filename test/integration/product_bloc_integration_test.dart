import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:alitapricelist/features/product/presentation/bloc/product_bloc.dart';
import 'package:alitapricelist/features/product/presentation/bloc/product_state.dart';
import 'package:alitapricelist/features/product/domain/usecases/get_product_usecase.dart';
import 'package:alitapricelist/features/product/data/repositories/area_repository.dart';
import 'package:alitapricelist/features/product/data/repositories/channel_repository.dart';
import 'package:alitapricelist/features/product/data/repositories/brand_repository.dart';

import 'product_bloc_integration_test.mocks.dart';

/// Integration test untuk ProductBloc
///
/// ✅ ProductBloc telah direfactor untuk menggunakan constructor injection.
/// Sekarang kita bisa membuat ProductBloc dengan mock dependencies tanpa setup GetIt.

@GenerateMocks([
  GetProductUseCase,
  AreaRepository,
  ChannelRepository,
  BrandRepository,
])
void main() {
  group('ProductBloc Integration Tests', () {
    late MockGetProductUseCase mockGetProductUseCase;
    late MockAreaRepository mockAreaRepository;
    late MockChannelRepository mockChannelRepository;
    late MockBrandRepository mockBrandRepository;

    setUp(() {
      // Create mocks
      mockGetProductUseCase = MockGetProductUseCase();
      mockAreaRepository = MockAreaRepository();
      mockChannelRepository = MockChannelRepository();
      mockBrandRepository = MockBrandRepository();

      // Mock repository responses
      when(mockAreaRepository.fetchAllAreaNames())
          .thenAnswer((_) async => ['Jabodetabek', 'Bandung', 'Surabaya']);
      when(mockChannelRepository.fetchAllChannelNames())
          .thenAnswer((_) async => ['Retail', 'Online']);
      when(mockBrandRepository.fetchAllBrandNames())
          .thenAnswer((_) async => ['Spring Air', 'Therapedic']);
    });

    test('ProductBloc can now be tested with constructor injection', () {
      // ✅ ProductBloc has been refactored to use constructor injection
      // Now we can create ProductBloc with mock dependencies easily
      final bloc = ProductBloc(
        getProductUseCase: mockGetProductUseCase,
        areaRepository: mockAreaRepository,
        channelRepository: mockChannelRepository,
        brandRepository: mockBrandRepository,
      );

      expect(bloc, isNotNull);
      expect(bloc.state, isA<ProductInitial>());
    });

    // Example of what integration test would look like after refactoring:
    /*
    blocTest<ProductBloc, ProductState>(
      'should initialize dropdowns on AppStarted',
      build: () {
        when(mockAreaRepository.fetchAllAreaNames())
            .thenAnswer((_) async => ['Jabodetabek', 'Bandung']);
        when(mockChannelRepository.fetchAllChannelNames())
            .thenAnswer((_) async => ['Retail', 'Online']);
        when(mockBrandRepository.fetchAllBrandNames())
            .thenAnswer((_) async => ['Spring Air', 'Therapedic']);
        
        return ProductBloc(
          mockGetProductUseCase,
          mockAreaRepository,
          mockChannelRepository,
          mockBrandRepository,
        );
      },
      act: (bloc) => bloc.add(AppStarted()),
      expect: () => [
        // Expected states after initialization
      ],
    );
    */
  });
}
