import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/widgets/floating_badge.dart';

void main() {
  group('FloatingBadge', () {
    testWidgets('displays count text', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: FloatingBadge(count: 5)),
      ));

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows maxCount+ for overflow', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: FloatingBadge(count: 150)),
      ));

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('respects custom maxCount', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: FloatingBadge(count: 15, maxCount: 10)),
      ));

      expect(find.text('10+'), findsOneWidget);
    });

    testWidgets('shows exact count at maxCount boundary', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: FloatingBadge(count: 99)),
      ));

      expect(find.text('99'), findsOneWidget);
    });

    testWidgets('has Semantics label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: FloatingBadge(count: 3)),
      ));

      final node = tester.getSemantics(find.text('3'));
      expect(node.label, contains('3 item'));
      handle.dispose();
    });

    testWidgets('Semantics uses actual count even for overflow',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: FloatingBadge(count: 150)),
      ));

      final node = tester.getSemantics(find.text('99+'));
      expect(node.label, contains('150 item'));
      handle.dispose();
    });
  });
}
