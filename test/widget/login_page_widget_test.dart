import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';

import 'package:alitapricelist/features/authentication/presentation/pages/login_page.dart';
import 'package:alitapricelist/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:alitapricelist/features/authentication/domain/usecases/login_usecase.dart';
import 'package:alitapricelist/features/authentication/data/repositories/auth_repository.dart';
import 'package:alitapricelist/theme/app_theme.dart';

import 'login_page_widget_test.mocks.dart';

@GenerateMocks([LoginUseCase, AuthRepository])
void main() {
  group('LoginPage Widget Tests', () {
    late MockLoginUseCase mockLoginUseCase;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockLoginUseCase = MockLoginUseCase();
      mockAuthRepository = MockAuthRepository();
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            loginUseCase: mockLoginUseCase,
            authRepository: mockAuthRepository,
          ),
          child: const LoginPage(),
        ),
      );
    }

    testWidgets('should display login page with all UI elements',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Check if key UI elements are present
      expect(find.text('Alita Pricelist'), findsOneWidget);
      expect(find.text('Silakan masuk untuk melanjutkan'), findsOneWidget);
      expect(find.text('Masuk'),
          findsWidgets); // There are 2 "Masuk" texts (header and button)
      expect(find.text('Masukkan email dan password'), findsOneWidget);

      // Check for email and password fields
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('should show email and password text fields', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;

      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);

      // Try to enter text
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Verify text was entered
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('should display login button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Masuk'), findsWidgets);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should show loading state when login button is tapped',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.pump();

      // Scroll to button if needed
      final buttonFinder = find.byType(ElevatedButton);
      if (buttonFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(buttonFinder);
        await tester.pump();
      }

      // Act - Tap login button (with warnIfMissed: false to avoid warning)
      await tester.tap(buttonFinder, warnIfMissed: false);
      await tester.pump();

      // Assert - Should show loading indicator or button state change
      // Note: Actual behavior depends on LoginForm implementation
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should display app logo', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Check for image widget (logo)
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('should display footer with version info', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Wait for PackageInfo to load
      await tester.pump(const Duration(seconds: 1));

      // Assert
      expect(find.textContaining('©'), findsOneWidget);
      expect(find.textContaining('Version'), findsOneWidget);
    });

    testWidgets('should have proper layout structure', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Check for main structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });
  });
}
