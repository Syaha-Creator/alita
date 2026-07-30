import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/features/pricelist/presentation/widgets/product_image_carousel.dart';

/// Regression test: on tablet/desktop widths the carousel must cap its
/// content width at [AppLayoutTokens.maxContentWidth] instead of stretching
/// full-bleed, which used to force the underlying network image to upscale
/// past its decoded resolution and look blurry.
void main() {
  Future<void> pumpCarousel(WidgetTester tester, double screenWidth) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              ProductImageCarousel(
                screenWidth: screenWidth,
                imageUrls: const ['https://example.com/a.png'],
                productId: 'p1',
                controller: PageController(),
                currentIndex: 0,
                onPageChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  double renderedContentWidth(WidgetTester tester) {
    final box = tester.widget<SizedBox>(
      find.byKey(const Key('productImageCarouselContent')),
    );
    return box.width!;
  }

  testWidgets('uses full screen width as content width on phones',
      (tester) async {
    await pumpCarousel(tester, 360);

    expect(renderedContentWidth(tester), 360);
  });

  testWidgets('caps content width at maxContentWidth on tablet/desktop',
      (tester) async {
    await pumpCarousel(tester, 1200);

    expect(renderedContentWidth(tester), 480);
  });
}
