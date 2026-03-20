import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/widgets/status_chip.dart';

void main() {
  group('StatusChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusChip(
            label: 'Approved',
            backgroundColor: Colors.green.shade50,
            foregroundColor: Colors.green,
          ),
        ),
      ));

      expect(find.text('Approved'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusChip(
            label: 'Pending',
            icon: Icons.access_time,
            backgroundColor: Colors.orange.shade50,
            foregroundColor: Colors.orange,
          ),
        ),
      ));

      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('does not render icon when null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusChip(
            label: 'Rejected',
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red,
          ),
        ),
      ));

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('has correct Semantics label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusChip(
            label: 'Approved',
            backgroundColor: Colors.green.shade50,
            foregroundColor: Colors.green,
          ),
        ),
      ));

      final node = tester.getSemantics(find.text('Approved'));
      expect(node.label, contains('Status'));
      handle.dispose();
    });

    testWidgets('applies custom background and foreground colors',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StatusChip(
            label: 'Custom',
            backgroundColor: Color(0xFFAABBCC),
            foregroundColor: Color(0xFF112233),
          ),
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).last);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFAABBCC));
    });
  });
}
