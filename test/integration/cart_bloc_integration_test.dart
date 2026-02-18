import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/config/app_constant.dart';
import 'package:alitapricelist/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:alitapricelist/features/cart/presentation/bloc/cart_event.dart';
import 'package:alitapricelist/features/cart/presentation/bloc/cart_state.dart';
import 'package:alitapricelist/features/cart/domain/usecases/apply_discounts_usecase.dart';
import 'package:alitapricelist/features/cart/domain/repositories/cart_repository.dart';
import 'package:alitapricelist/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:alitapricelist/features/cart/data/datasources/cart_local_data_source.dart';
import 'package:alitapricelist/features/product/domain/entities/product_entity.dart';

/// Integration test untuk CartBloc
///
/// Test ini menggunakan SharedPreferences untuk testing storage operations.
/// Note: CartStorageService menggunakan static methods, jadi kita test dengan
/// actual SharedPreferences instance untuk integration testing.

void main() {
  group('CartBloc Integration Tests', () {
    late CartBloc bloc;
    late SharedPreferences prefs;
    late CartRepository cartRepository;

    setUp(() async {
      // Use in-memory SharedPreferences for testing
      SharedPreferences.setMockInitialValues({
        StorageKeys.isLoggedIn: true,
        StorageKeys.currentUserId: 1,
      });
      prefs = await SharedPreferences.getInstance();

      // Ensure user is logged in for cart operations
      await prefs.setBool(StorageKeys.isLoggedIn, true);
      await prefs.setInt(StorageKeys.currentUserId, 1);

      // Create real CartRepository for integration test
      final localDataSource = CartLocalDataSourceImpl(sharedPreferences: prefs);
      cartRepository = CartRepositoryImpl(localDataSource: localDataSource);

      bloc = CartBloc(
        applyDiscountsUsecase: const ApplyDiscountsUsecase(),
        cartRepository: cartRepository,
      );
    });

    tearDown(() async {
      bloc.close();
      await prefs.clear();
    });

    test('initial state should be CartLoaded with empty list', () {
      expect(bloc.state, isA<CartLoaded>());
      expect((bloc.state as CartLoaded).cartItems, isEmpty);
    });

    blocTest<CartBloc, CartState>(
      'should load empty cart when no items saved',
      build: () => bloc,
      act: (bloc) => bloc.add(LoadCart()),
      expect: () => [
        const CartLoaded([]),
      ],
    );

    test('should add item to cart', () async {
      final product = _createTestProduct();
      bloc.add(AddToCart(
        product: product,
        quantity: 1,
        netPrice: 1000000.0,
        discountPercentages: [10.0],
      ));

      await Future.delayed(const Duration(milliseconds: 200));

      final state = bloc.state as CartLoaded;
      expect(state.cartItems.length, 1);
      expect(state.cartItems[0].product.id, 1);
      expect(state.cartItems[0].quantity, 1);
      expect(state.cartItems[0].netPrice, 1000000.0);
      expect(state.cartItems[0].discountPercentages, [10.0]);
    });

    test('should load empty cart when no items saved', () async {
      bloc.add(LoadCart());
      await Future.delayed(const Duration(milliseconds: 100));

      final state = bloc.state as CartLoaded;
      expect(state.cartItems, isEmpty);
    });
  });
}

// Helper function to create test product
ProductEntity _createTestProduct() {
  return const ProductEntity(
    id: 1,
    area: 'Jabodetabek',
    channel: 'Retail',
    brand: 'Test Brand',
    kasur: 'Spring Air',
    divan: 'Tanpa Divan',
    headboard: 'Tanpa Headboard',
    sorong: 'Tanpa Sorong',
    ukuran: '90x200',
    pricelist: 1000000.0,
    program: 'Regular',
    eupKasur: 1000000.0,
    eupDivan: 0.0,
    eupHeadboard: 0.0,
    endUserPrice: 1000000.0,
    bonus: [],
    discounts: [],
    isSet: false,
    plKasur: 1000000.0,
    plDivan: 0.0,
    plHeadboard: 0.0,
    plSorong: 0.0,
    eupSorong: 0.0,
    bottomPriceAnalyst: 900000.0,
    disc1: 0.0,
    disc2: 0.0,
    disc3: 0.0,
    disc4: 0.0,
    disc5: 0.0,
  );
}
