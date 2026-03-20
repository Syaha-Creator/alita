import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/widgets/action_button_bar.dart';

void main() {
  group('ActionButtonBar', () {
    testWidgets('renders primary button with label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ActionButtonBar(
            primaryLabel: 'Submit',
            onPrimaryPressed: () {},
          ),
        ),
      ));

      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('fires primary callback on tap', (tester) async {
      var pressed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ActionButtonBar(
            primaryLabel: 'Submit',
            onPrimaryPressed: () => pressed = true,
          ),
        ),
      ));

      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('hides secondary button when label is null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ActionButtonBar(
            primaryLabel: 'Submit',
            onPrimaryPressed: () {},
          ),
        ),
      ));

      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('shows secondary button when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ActionButtonBar(
            primaryLabel: 'Submit',
            onPrimaryPressed: () {},
            secondaryLabel: 'Cancel',
            onSecondaryPressed: () {},
          ),
        ),
      ));

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('disabled when onPrimaryPressed is null', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ActionButtonBar(
            primaryLabel: 'Submit',
            onPrimaryPressed: null,
          ),
        ),
      ));

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('renders primary leading icon', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ActionButtonBar(
            primaryLabel: 'Send',
            onPrimaryPressed: () {},
            primaryLeading: const Icon(Icons.send),
          ),
        ),
      ));

      expect(find.byIcon(Icons.send), findsOneWidget);
    });
  });
}
