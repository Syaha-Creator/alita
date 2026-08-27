import 'package:alitapricelist/features/checkout/data/models/approver_model.dart';
import 'package:alitapricelist/features/checkout/data/models/store_model.dart';
import 'package:alitapricelist/features/checkout/data/utils/klaus_approval_rules.dart';
import 'package:alitapricelist/features/checkout/logic/checkout_provider.dart';
import 'package:alitapricelist/features/profile/data/models/user_profile.dart';
import 'package:alitapricelist/features/profile/logic/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Division 25 → channel S1 (Direct). Tanpa address_number → bukan SO.
    container = ProviderContainer(
      overrides: [
        profileProvider.overrideWith(
          (ref) async => UserProfile(
            id: 1,
            name: 'Sales Direct',
            email: 'direct@test.com',
            workTitle: 'Sales',
            workPlaceName: 'Store',
            areaName: 'Jakarta',
            divisions: const [
              {'id': 25},
            ],
          ),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  const rocky = Approver(
    id: 1019,
    userName: 'RockySuwandi',
    fullName: 'Rocky Suwandi',
    jobLevelName: 'supervisor',
  );
  const otherSpv = Approver(
    id: 1379,
    userName: 'AnaFitriana',
    fullName: 'Ana Fitriana',
    jobLevelName: 'supervisor',
  );
  const otherRsm = Approver(
    id: 22,
    userName: 'other_rsm',
    fullName: 'Other RSM',
    jobLevelName: 'RSM',
  );

  StoreModel klausStore({int id = 1937}) => StoreModel(
        id: id,
        name: 'Klaus Store $id',
        category: '',
        address: '',
        state: '',
        city: '',
        area: '',
        phone: '',
        image: '',
      );

  group('Klaus auto-assign RSM (Direct S1 only)', () {
    test('Rocky + workplace 1937 auto-sets Klaus as manager', () async {
      await container.read(profileProvider.future);
      final n = container.read(checkoutProvider.notifier);
      n.updateStore(klausStore());
      n.selectSpv(rocky);

      final s = container.read(checkoutProvider);
      expect(n.isKlausRuleActive, isTrue);
      expect(s.selectedManager?.id, KlausApprovalRules.klausUserId);
    });

    test('SPV Rocky first then workplace later still assigns Klaus', () async {
      await container.read(profileProvider.future);
      final n = container.read(checkoutProvider.notifier);
      n.selectSpv(rocky);
      expect(container.read(checkoutProvider).selectedManager, isNull);

      n.updateStore(klausStore(id: 6015));
      expect(n.isKlausRuleActive, isTrue);
      expect(
        container.read(checkoutProvider).selectedManager?.id,
        KlausApprovalRules.klausUserId,
      );
    });

    test('cannot replace Klaus with another RSM while rule active', () async {
      await container.read(profileProvider.future);
      final n = container.read(checkoutProvider.notifier);
      n.updateStore(klausStore());
      n.selectSpv(rocky);
      n.selectManager(otherRsm);

      expect(
        container.read(checkoutProvider).selectedManager?.id,
        KlausApprovalRules.klausUserId,
      );
    });

    test('clearSelectedManager is no-op while Klaus rule active', () async {
      await container.read(profileProvider.future);
      final n = container.read(checkoutProvider.notifier);
      n.updateStore(klausStore());
      n.selectSpv(rocky);
      n.clearSelectedManager();

      expect(
        container.read(checkoutProvider).selectedManager?.id,
        KlausApprovalRules.klausUserId,
      );
    });

    test('switching to non-Klaus SPV clears auto Klaus', () async {
      await container.read(profileProvider.future);
      final n = container.read(checkoutProvider.notifier);
      n.updateStore(klausStore());
      n.selectSpv(rocky);
      expect(
        container.read(checkoutProvider).selectedManager?.id,
        KlausApprovalRules.klausUserId,
      );

      n.selectSpv(otherSpv);
      expect(n.isKlausRuleActive, isFalse);
      expect(container.read(checkoutProvider).selectedManager, isNull);
    });

    test('MM profile does not auto-assign Klaus', () async {
      SharedPreferences.setMockInitialValues({});
      final mmContainer = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            (ref) async => UserProfile(
              id: 2,
              name: 'Sales MM',
              email: 'mm@test.com',
              workTitle: 'Sales',
              workPlaceName: 'Store',
              areaName: 'Jakarta',
              divisions: const [
                {'id': 26},
              ],
            ),
          ),
        ],
      );
      addTearDown(mmContainer.dispose);
      await mmContainer.read(profileProvider.future);

      final n = mmContainer.read(checkoutProvider.notifier);
      n.updateStore(klausStore());
      n.selectSpv(rocky);

      expect(n.isKlausRuleActive, isFalse);
      expect(mmContainer.read(checkoutProvider).selectedManager, isNull);
    });
  });
}
