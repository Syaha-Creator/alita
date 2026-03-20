import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alitapricelist/core/widgets/async_state_view.dart';

void main() {
  group('AsyncStateView', () {
    testWidgets('shows loading spinner for AsyncLoading', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AsyncStateView<String>(
            state: const AsyncLoading(),
            dataBuilder: (data) => Text(data),
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows custom loading widget', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AsyncStateView<String>(
            state: const AsyncLoading(),
            dataBuilder: (data) => Text(data),
            loading: const Text('Custom Loading'),
          ),
        ),
      ));

      expect(find.text('Custom Loading'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('hides default loading when showDefaultLoading is false',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AsyncStateView<String>(
            state: const AsyncLoading(),
            dataBuilder: (data) => Text(data),
            showDefaultLoading: false,
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error text for AsyncError', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AsyncStateView<String>(
            state: AsyncError('Oops', StackTrace.current),
            dataBuilder: (data) => Text(data),
          ),
        ),
      ));

      await tester.pumpAndSettle();
      expect(find.textContaining('Oops'), findsOneWidget);
    });

    testWidgets('shows custom error widget via errorBuilder', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AsyncStateView<String>(
            state: AsyncError('Fail', StackTrace.current),
            dataBuilder: (data) => Text(data),
            errorBuilder: (err, st) => Text('Custom: $err'),
          ),
        ),
      ));

      await tester.pumpAndSettle();
      expect(find.text('Custom: Fail'), findsOneWidget);
    });

    testWidgets('hides default error when showDefaultError is false',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AsyncStateView<String>(
            state: AsyncError('err', StackTrace.current),
            dataBuilder: (data) => Text(data),
            showDefaultError: false,
          ),
        ),
      ));

      await tester.pumpAndSettle();
      expect(find.textContaining('err'), findsNothing);
    });

    testWidgets('renders data with dataBuilder', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AsyncStateView<String>(
            state: const AsyncData('Hello World'),
            dataBuilder: (data) => Text(data),
          ),
        ),
      ));

      await tester.pumpAndSettle();
      expect(find.text('Hello World'), findsOneWidget);
    });
  });
}
