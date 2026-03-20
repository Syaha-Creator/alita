import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/widgets/empty_state_view.dart';

void main() {
  Widget buildTestWidget({Widget? action}) {
    return MaterialApp(
      home: Scaffold(
        body: EmptyStateView(
          icon: Icons.inbox_outlined,
          title: 'No Data',
          subtitle: 'Nothing to show here',
          action: action,
        ),
      ),
    );
  }

  group('EmptyStateView', () {
    testWidgets('renders icon, title, and subtitle', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('No Data'), findsOneWidget);
      expect(find.text('Nothing to show here'), findsOneWidget);
    });

    testWidgets('does not show action when null', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('shows action widget when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        action: ElevatedButton(onPressed: () {}, child: const Text('Retry')),
      ));

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: EmptyStateView(
            icon: Icons.inbox_outlined,
            title: 'Empty',
            subtitle: 'Sub',
            padding: EdgeInsets.all(48),
          ),
        ),
      ));

      final padding = tester.widget<Padding>(
        find
            .ancestor(
              of: find.byType(Column),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(padding.padding, const EdgeInsets.all(48));
    });

    testWidgets('uses custom icon size', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: EmptyStateView(
            icon: Icons.inbox_outlined,
            title: 'Empty',
            subtitle: 'Sub',
            iconSize: 120,
          ),
        ),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.inbox_outlined));
      expect(icon.size, 120);
    });
  });
}
