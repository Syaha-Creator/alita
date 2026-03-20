import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/widgets/error_state_view.dart';

void main() {
  group('ErrorStateView', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ErrorStateView(
            title: 'Error Title',
            message: 'Something went wrong',
          ),
        ),
      ));

      expect(find.text('Error Title'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('renders default error icon', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ErrorStateView(
            title: 'Error',
            message: 'Msg',
          ),
        ),
      ));

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ErrorStateView(
            title: 'Error',
            message: 'Msg',
          ),
        ),
      ));

      expect(find.text('Coba Lagi'), findsNothing);
    });

    testWidgets('shows retry button when onRetry is provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorStateView(
            title: 'Error',
            message: 'Msg',
            onRetry: () {},
          ),
        ),
      ));

      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('retry button fires callback', (tester) async {
      var called = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorStateView(
            title: 'Error',
            message: 'Msg',
            onRetry: () => called = true,
          ),
        ),
      ));

      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('uses custom retry label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorStateView(
            title: 'Error',
            message: 'Msg',
            onRetry: () {},
            retryLabel: 'Try Again',
          ),
        ),
      ));

      expect(find.text('Try Again'), findsOneWidget);
    });
  });
}
