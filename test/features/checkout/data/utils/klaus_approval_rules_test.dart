import 'package:alitapricelist/features/checkout/data/utils/checkout_channel_resolver.dart';
import 'package:alitapricelist/features/checkout/data/utils/klaus_approval_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KlausApprovalRules.isActive', () {
    test('true for Direct S1 + workplace 1937 + SPV Rocky 1019', () {
      expect(
        KlausApprovalRules.isActive(
          workPlaceId: 1937,
          spvId: 1019,
          orderChannel: CheckoutChannelResolver.channelS1,
        ),
        isTrue,
      );
    });

    test('true for Direct S1 + workplace 6015 + SPV Rizal 4147', () {
      expect(
        KlausApprovalRules.isActive(
          workPlaceId: 6015,
          spvId: 4147,
          orderChannel: CheckoutChannelResolver.channelS1,
        ),
        isTrue,
      );
    });

    test('false for Indirect SO even with Klaus workplace + Rocky', () {
      expect(
        KlausApprovalRules.isActive(
          workPlaceId: 1937,
          spvId: 1019,
          orderChannel: CheckoutChannelResolver.channelSo,
        ),
        isFalse,
      );
    });

    test('false for MM even with Klaus workplace + Rocky', () {
      expect(
        KlausApprovalRules.isActive(
          workPlaceId: 1937,
          spvId: 1019,
          orderChannel: CheckoutChannelResolver.channelMm,
        ),
        isFalse,
      );
    });

    test('false when isIndirectSale true', () {
      expect(
        KlausApprovalRules.isActive(
          workPlaceId: 1937,
          spvId: 1019,
          orderChannel: CheckoutChannelResolver.channelS1,
          isIndirectSale: true,
        ),
        isFalse,
      );
    });

    test('false when channel empty/unknown', () {
      expect(
        KlausApprovalRules.isActive(
          workPlaceId: 1937,
          spvId: 1019,
          orderChannel: '',
        ),
        isFalse,
      );
    });

    test('false when SPV is Rocky but workplace is not Klaus location', () {
      expect(
        KlausApprovalRules.isActive(
          workPlaceId: 9999,
          spvId: 1019,
          orderChannel: CheckoutChannelResolver.channelS1,
        ),
        isFalse,
      );
    });

    test('false when workplace is Klaus but SPV is not Rocky/Rizal', () {
      expect(
        KlausApprovalRules.isActive(
          workPlaceId: 1937,
          spvId: 1379,
          orderChannel: CheckoutChannelResolver.channelS1,
        ),
        isFalse,
      );
    });
  });
}
