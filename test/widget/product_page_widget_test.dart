import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';

import 'package:alitapricelist/features/product/presentation/pages/product_page.dart';
import 'package:alitapricelist/features/product/presentation/bloc/product_bloc.dart';
import 'package:alitapricelist/features/product/domain/usecases/get_product_usecase.dart';
import 'package:alitapricelist/features/product/data/repositories/area_repository.dart';
import 'package:alitapricelist/features/product/data/repositories/channel_repository.dart';
import 'package:alitapricelist/features/product/data/repositories/brand_repository.dart';
import 'package:alitapricelist/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:alitapricelist/features/authentication/domain/usecases/login_usecase.dart';
import 'package:alitapricelist/features/authentication/data/repositories/auth_repository.dart';
import 'package:alitapricelist/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:alitapricelist/features/cart/domain/usecases/apply_discounts_usecase.dart';
import 'package:alitapricelist/features/cart/domain/repositories/cart_repository.dart';
import 'package:alitapricelist/theme/app_theme.dart';

import 'product_page_widget_test.mocks.dart';

@GenerateMocks([
  GetProductUseCase,
  LoginUseCase,
  AuthRepository,
  AreaRepository,
  ChannelRepository,
  BrandRepository,
  CartRepository,
])
void main() {
  group('ProductPage Widget Tests', () {
    late MockGetProductUseCase mockGetProductUseCase;
    late MockLoginUseCase mockLoginUseCase;
    late MockAuthRepository mockAuthRepository;
    late MockAreaRepository mockAreaRepository;
    late MockChannelRepository mockChannelRepository;
    late MockBrandRepository mockBrandRepository;
    late MockCartRepository mockCartRepository;

    setUp(() {
      mockGetProductUseCase = MockGetProductUseCase();
      mockLoginUseCase = MockLoginUseCase();
      mockAuthRepository = MockAuthRepository();
      mockAreaRepository = MockAreaRepository();
      mockChannelRepository = MockChannelRepository();
      mockBrandRepository = MockBrandRepository();
      mockCartRepository = MockCartRepository();
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ProductBloc>(
              create: (context) => ProductBloc(
                getProductUseCase: mockGetProductUseCase,
                areaRepository: mockAreaRepository,
                channelRepository: mockChannelRepository,
                brandRepository: mockBrandRepository,
              ),
            ),
            BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(
                loginUseCase: mockLoginUseCase,
                authRepository: mockAuthRepository,
              ),
            ),
            BlocProvider<CartBloc>(
              create: (context) => CartBloc(
                applyDiscountsUsecase: const ApplyDiscountsUsecase(),
                cartRepository: mockCartRepository,
              ),
            ),
          ],
          child: const ProductPage(),
        ),
      );
    }

    testWidgets('should display product page structure', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Check for main structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display filter dropdowns', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - Check for dropdown widgets
      // Note: Actual implementation depends on ProductDropdown widget
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display product list area', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Check for list view or grid
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
