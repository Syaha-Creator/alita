import 'package:alitapricelist/features/checkout/data/models/approver_model.dart';
import 'package:alitapricelist/features/checkout/logic/checkout_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  const asm = Approver(
    id: 11,
    userName: 'asm_a',
    fullName: 'ASM A',
    jobLevelName: 'ASM',
  );
  const rsm = Approver(
    id: 22,
    userName: 'rsm_b',
    fullName: 'RSM B',
    jobLevelName: 'RSM',
  );

  group('manual ASM/RSM UI flags + clear selection', () {
    test('manualAsmRequestedProvider defaults false and can be set', () {
      expect(container.read(manualAsmRequestedProvider), isFalse);
      container.read(manualAsmRequestedProvider.notifier).state = true;
      expect(container.read(manualAsmRequestedProvider), isTrue);
    });

    test('manualRsmRequestedProvider defaults false and can be set', () {
      expect(container.read(manualRsmRequestedProvider), isFalse);
      container.read(manualRsmRequestedProvider.notifier).state = true;
      expect(container.read(manualRsmRequestedProvider), isTrue);
    });

    test('clearSelectedSpv clears ASM selection after manual add', () {
      final n = container.read(checkoutProvider.notifier);
      container.read(manualAsmRequestedProvider.notifier).state = true;
      n.selectSpv(asm);
      expect(container.read(checkoutProvider).selectedSpv, asm);

      container.read(manualAsmRequestedProvider.notifier).state = false;
      n.clearSelectedSpv();

      expect(container.read(manualAsmRequestedProvider), isFalse);
      expect(container.read(checkoutProvider).selectedSpv, isNull);
    });

    test('clearSelectedManager clears RSM selection after manual add', () {
      final n = container.read(checkoutProvider.notifier);
      container.read(manualRsmRequestedProvider.notifier).state = true;
      n.selectManager(rsm);

      container.read(manualRsmRequestedProvider.notifier).state = false;
      n.clearSelectedManager();

      expect(container.read(manualRsmRequestedProvider), isFalse);
      expect(container.read(checkoutProvider).selectedManager, isNull);
    });
  });
}
