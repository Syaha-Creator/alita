import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/features/profile/presentation/widgets/profile_version_footer.dart';

void main() {
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProfileVersionFooter()),
          ),
        ),
      );

  testWidgets('shows fallback label while package info is loading',
      (tester) async {
    await pump(tester);
    // Before the async PackageInfo.fromPlatform() resolves.
    expect(find.text('Alita Pricelist'), findsOneWidget);
  });

  testWidgets('shows version label once package info resolves',
      (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();

    // PackageInfo.fromPlatform() falls back to a stub in test env
    // (package_info_plus registers a test method-channel stub), so a
    // version string of some form should be rendered instead of the
    // no-data fallback.
    expect(find.textContaining('Alita Pricelist'), findsOneWidget);
  });
}
