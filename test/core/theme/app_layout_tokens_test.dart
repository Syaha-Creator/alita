import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/core/theme/app_layout_tokens.dart';

void main() {
  group('AppLayoutTokens.gridColumnCountForWidth', () {
    test('returns 2 columns for phone widths below tablet breakpoint', () {
      expect(AppLayoutTokens.gridColumnCountForWidth(320), 2);
      expect(AppLayoutTokens.gridColumnCountForWidth(599), 2);
    });

    test('returns 3 columns for tablet widths', () {
      expect(AppLayoutTokens.gridColumnCountForWidth(600), 3);
      expect(AppLayoutTokens.gridColumnCountForWidth(899), 3);
    });

    test('returns 4 columns for desktop/large-tablet widths', () {
      expect(AppLayoutTokens.gridColumnCountForWidth(900), 4);
      expect(AppLayoutTokens.gridColumnCountForWidth(1400), 4);
    });
  });
}
