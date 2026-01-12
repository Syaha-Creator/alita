import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';

import 'package:alitapricelist/features/product/presentation/pages/product_detail_page.dart';
import 'package:alitapricelist/features/product/presentation/bloc/product_bloc.dart';
import 'package:alitapricelist/features/product/presentation/bloc/product_event.dart';
import 'package:alitapricelist/features/product/domain/usecases/get_product_usecase.dart';
import 'package:alitapricelist/features/product/data/repositories/area_repository.dart';
import 'package:alitapricelist/features/product/data/repositories/channel_repository.dart';
import 'package:alitapricelist/features/product/data/repositories/brand_repository.dart';
import 'package:alitapricelist/features/product/domain/entities/product_entity.dart';
import 'package:alitapricelist/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:alitapricelist/features/cart/domain/usecases/apply_discounts_usecase.dart';
import 'package:alitapricelist/features/cart/domain/repositories/cart_repository.dart';
import 'package:alitapricelist/theme/app_theme.dart';

import 'product_detail_page_widget_test.mocks.dart';

@GenerateMocks([
  GetProductUseCase,
  AreaRepository,
  ChannelRepository,
  BrandRepository,
  CartRepository,
])
void main() {
  group('ProductDetailPage Widget Tests', () {
    late MockGetProductUseCase mockGetProductUseCase;
    late MockAreaRepository mockAreaRepository;
    late MockChannelRepository mockChannelRepository;
    late MockBrandRepository mockBrandRepository;
    late MockCartRepository mockCartRepository;
    late ProductBloc productBloc;
    late CartBloc cartBloc;

    setUp(() {
      mockGetProductUseCase = MockGetProductUseCase();
      mockAreaRepository = MockAreaRepository();
      mockChannelRepository = MockChannelRepository();
      mockBrandRepository = MockBrandRepository();
      mockCartRepository = MockCartRepository();

      productBloc = ProductBloc(
        getProductUseCase: mockGetProductUseCase,
        areaRepository: mockAreaRepository,
        channelRepository: mockChannelRepository,
        brandRepository: mockBrandRepository,
      );

      cartBloc = CartBloc(
        applyDiscountsUsecase: const ApplyDiscountsUsecase(),
        cartRepository: mockCartRepository,
      );
    });

    tearDown(() {
      productBloc.close();
      cartBloc.close();
    });

    ProductEntity createTestProduct() {
      return const ProductEntity(
        id: 1,
        area: 'Jabodetabek',
        channel: 'Retail',
        brand: 'Spring Air',
        kasur: 'Spring Air Comfort',
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

    Widget createTestWidget({ProductEntity? product}) {
      // Set product in bloc state if provided
      if (product != null) {
        productBloc.add(SelectProduct(product));
      }

      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ProductBloc>.value(value: productBloc),
            BlocProvider<CartBloc>.value(value: cartBloc),
          ],
          child: const ProductDetailPage(),
        ),
      );
    }

    testWidgets('should display error message when product is null',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Produk tidak ditemukan atau belum dipilih.'),
          findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('should display product detail page structure', (tester) async {
      // Arrange
      final product = createTestProduct();

      // Act
      await tester.pumpWidget(createTestWidget(product: product));
      await tester.pumpAndSettle();

      // Assert - Check for main structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('should display product name and size', (tester) async {
      // Arrange
      final product = createTestProduct();

      // Act
      await tester.pumpWidget(createTestWidget(product: product));
      await tester.pumpAndSettle();

      // Assert - Product name should be displayed (may appear in multiple places)
      expect(find.text('Spring Air Comfort'), findsWidgets);
      expect(find.text('(90x200)'), findsWidgets);
    });

    testWidgets('should display back button', (tester) async {
      // Arrange
      final product = createTestProduct();

      // Act
      await tester.pumpWidget(createTestWidget(product: product));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.arrow_back_ios_rounded), findsOneWidget);
    });

    testWidgets('should display cart and share buttons', (tester) async {
      // Arrange
      final product = createTestProduct();

      // Act
      await tester.pumpWidget(createTestWidget(product: product));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('should display action buttons (Credit, Edit, Info)',
        (tester) async {
      // Arrange
      final product = createTestProduct();

      // Act
      await tester.pumpWidget(createTestWidget(product: product));
      await tester.pumpAndSettle();

      // Scroll to bottom to see action buttons
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Assert - Action buttons should be visible (may appear multiple times)
      expect(find.byIcon(Icons.credit_card_rounded), findsWidgets);
      expect(find.byIcon(Icons.edit_rounded), findsWidgets);
      expect(find.byIcon(Icons.info_outline_rounded), findsWidgets);
    });

    testWidgets('should display Add to Cart button with price', (tester) async {
      // Arrange
      final product = createTestProduct();

      // Act
      await tester.pumpWidget(createTestWidget(product: product));
      await tester.pumpAndSettle();

      // Scroll to bottom
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.byIcon(Icons.add_shopping_cart_rounded), findsOneWidget);
    });

    testWidgets('should display product brand and channel info',
        (tester) async {
      // Arrange
      final product = createTestProduct();

      // Act
      await tester.pumpWidget(createTestWidget(product: product));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('SPRING AIR'), findsOneWidget);
      expect(find.text('Retail'), findsOneWidget);
      expect(find.text('Jabodetabek'), findsOneWidget);
    });
  });
}
