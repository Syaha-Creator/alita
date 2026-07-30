import 'package:alitapricelist/features/cart/data/cart_item.dart';
import 'package:alitapricelist/features/checkout/data/utils/indirect_approval_rules.dart';
import 'package:alitapricelist/features/history/data/models/order_history.dart';
import 'package:alitapricelist/features/pricelist/data/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

OrderHistory _order({required String customerName, required String shipToName}) =>
    OrderHistory(
      id: 1,
      noSp: 'SP-T',
      orderDate: '-',
      requestDate: '-',
      note: '',
      customerName: customerName,
      phone: '-',
      address: '-',
      email: '',
      shipToName: shipToName,
      isTakeAway: false,
      workPlaceName: '-',
      companyName: '-',
      totalAmount: 0,
      status: 'Approved',
    );

Product _product({double price = 1_000_000}) => Product(
      id: 'P1',
      name: 'Kasur Test',
      price: price,
      imageUrl: '',
      category: 'Kasur',
      kasur: 'Foam X',
      ukuran: '160',
      divan: 'Tanpa Divan',
      headboard: 'Tanpa Headboard',
      sorong: 'Tanpa Sorong',
      isSet: false,
      pricelist: 0,
      eupKasur: price,
      eupDivan: 0,
      eupHeadboard: 0,
      eupSorong: 0,
      plKasur: price,
      plDivan: 0,
      plHeadboard: 0,
      plSorong: 0,
    );

CartItem _indirectItem({
  double discount1 = 0,
  double discount2 = 0,
  double discount3 = 0,
  double discount4 = 0,
  bool isBonusCustomized = false,
  bool isNewCustomerStore = false,
  bool isCustomSize = false,
  bool isFocVoucher = false,
  String pricelistArea = 'Jakarta',
}) =>
    CartItem(
      product: _product(),
      indirectStoreAddressNumber: 1001,
      discount1: discount1,
      discount2: discount2,
      discount3: discount3,
      discount4: discount4,
      isBonusCustomized: isBonusCustomized,
      isNewCustomerStore: isNewCustomerStore,
      isCustomSize: isCustomSize,
      isFocVoucher: isFocVoucher,
      pricelistArea: pricelistArea,
    );

void main() {
  group('IndirectApprovalRules', () {
    group('requiresAsm', () {
      test('false when only diskon tambahan (d1/d2/d3)', () {
        final cart = [_indirectItem(discount1: 5, discount2: 3, discount3: 2)];
        expect(
          IndirectApprovalRules.requiresAsm(
            isCustomerBaruShipping: false,
            hasNewCustomerStoreItem:
                IndirectApprovalRules.cartHasNewCustomerStore(cart),
            hasFocVoucherItem: IndirectApprovalRules.cartHasFocVoucher(cart),
            hasMedanPricelistItem: IndirectApprovalRules.cartHasMedanArea(cart),
            hasCustomSizeItem: IndirectApprovalRules.cartHasCustomSize(cart),
          ),
          isFalse,
        );
      });

      test('true for customer baru shipping', () {
        expect(
          IndirectApprovalRules.requiresAsm(
            isCustomerBaruShipping: true,
            hasNewCustomerStoreItem: false,
            hasFocVoucherItem: false,
            hasMedanPricelistItem: false,
            hasCustomSizeItem: false,
          ),
          isTrue,
        );
      });

      test('true for custom size', () {
        final cart = [_indirectItem(isCustomSize: true)];
        expect(
          IndirectApprovalRules.requiresAsm(
            isCustomerBaruShipping: false,
            hasNewCustomerStoreItem:
                IndirectApprovalRules.cartHasNewCustomerStore(cart),
            hasFocVoucherItem: IndirectApprovalRules.cartHasFocVoucher(cart),
            hasMedanPricelistItem: IndirectApprovalRules.cartHasMedanArea(cart),
            hasCustomSizeItem: IndirectApprovalRules.cartHasCustomSize(cart),
          ),
          isTrue,
        );
      });
    });

    group('requiresRsm', () {
      test('true when diskon tambahan only', () {
        final cart = [_indirectItem(discount1: 5)];
        expect(
          IndirectApprovalRules.requiresRsm(
            cartItems: cart,
            isKlausRuleActive: false,
          ),
          isTrue,
        );
      });

      test('true when bonus customized', () {
        final cart = [_indirectItem(isBonusCustomized: true)];
        expect(
          IndirectApprovalRules.requiresRsm(
            cartItems: cart,
            isKlausRuleActive: false,
          ),
          isTrue,
        );
      });

      test('false for plain indirect without triggers', () {
        final cart = [_indirectItem()];
        expect(
          IndirectApprovalRules.requiresRsm(
            cartItems: cart,
            isKlausRuleActive: false,
          ),
          isFalse,
        );
      });

      test('false when only discount4 (Analyst, not RSM)', () {
        final cart = [_indirectItem(discount4: 5)];
        expect(
          IndirectApprovalRules.requiresRsm(
            cartItems: cart,
            isKlausRuleActive: false,
          ),
          isFalse,
        );
      });

      test('false when only new-customer store (ASM, not RSM)', () {
        final cart = [_indirectItem(isNewCustomerStore: true)];
        expect(
          IndirectApprovalRules.requiresRsm(
            cartItems: cart,
            isKlausRuleActive: false,
          ),
          isFalse,
        );
        expect(
          IndirectApprovalRules.requiresAsm(
            isCustomerBaruShipping: false,
            hasNewCustomerStoreItem: true,
            hasFocVoucherItem: false,
            hasMedanPricelistItem: false,
            hasCustomSizeItem: false,
          ),
          isTrue,
        );
      });
    });

    group('isCustomerBaruShipping', () {
      test('create mode (no editOrder): mirrors UI toggle', () {
        expect(
          IndirectApprovalRules.isCustomerBaruShipping(
            editOrder: null,
            isShippingSameAsCustomer: false,
            isReceiverBranchMode: false,
          ),
          isTrue,
        );
        expect(
          IndirectApprovalRules.isCustomerBaruShipping(
            editOrder: null,
            isShippingSameAsCustomer: true,
            isReceiverBranchMode: false,
          ),
          isFalse,
        );
      });

      test(
        'edit mode: derives from ship_to_name vs customer_name, ignoring '
        'stale UI toggle defaults',
        () {
          // Regression: order awal butuh ASM (Customer Baru — ship_to_name
          // beda dari customer_name). Saat edit item, checkout page tidak
          // pernah restore isShippingSameAsCustomer/isReceiverBranchMode dari
          // order lama (tetap default true) — sebelum fix ini membuat syarat
          // ASM diam-diam hilang.
          final editOrder = _order(
            customerName: 'Toko Sejahtera',
            shipToName: 'Gudang Cabang Baru',
          );
          expect(
            IndirectApprovalRules.isCustomerBaruShipping(
              editOrder: editOrder,
              isShippingSameAsCustomer: true, // stale UI default
              isReceiverBranchMode: true, // stale UI default
            ),
            isTrue,
          );
        },
      );

      test('edit mode: ship_to_name sama dengan customer_name → bukan customer baru', () {
        final editOrder = _order(
          customerName: 'Toko Sejahtera',
          shipToName: 'Toko Sejahtera',
        );
        expect(
          IndirectApprovalRules.isCustomerBaruShipping(
            editOrder: editOrder,
            isShippingSameAsCustomer: true,
            isReceiverBranchMode: true,
          ),
          isFalse,
        );
      });
    });

    group('autoApprove', () {
      test('true for plain indirect cart', () {
        final cart = [_indirectItem()];
        expect(
          IndirectApprovalRules.autoApprove(
            cartItems: cart,
            isCustomerBaruShipping: false,
            hasNewCustomerStoreItem:
                IndirectApprovalRules.cartHasNewCustomerStore(cart),
            hasFocVoucherItem: IndirectApprovalRules.cartHasFocVoucher(cart),
            hasMedanPricelistItem: IndirectApprovalRules.cartHasMedanArea(cart),
            hasCustomSizeItem: IndirectApprovalRules.cartHasCustomSize(cart),
            isKlausRuleActive: false,
          ),
          isTrue,
        );
      });

      test('false when diskon tambahan (RSM only, not ASM)', () {
        final cart = [_indirectItem(discount2: 10)];
        expect(
          IndirectApprovalRules.autoApprove(
            cartItems: cart,
            isCustomerBaruShipping: false,
            hasNewCustomerStoreItem:
                IndirectApprovalRules.cartHasNewCustomerStore(cart),
            hasFocVoucherItem: IndirectApprovalRules.cartHasFocVoucher(cart),
            hasMedanPricelistItem: IndirectApprovalRules.cartHasMedanArea(cart),
            hasCustomSizeItem: IndirectApprovalRules.cartHasCustomSize(cart),
            isKlausRuleActive: false,
          ),
          isFalse,
        );
        expect(
          IndirectApprovalRules.requiresAsm(
            isCustomerBaruShipping: false,
            hasNewCustomerStoreItem:
                IndirectApprovalRules.cartHasNewCustomerStore(cart),
            hasFocVoucherItem: IndirectApprovalRules.cartHasFocVoucher(cart),
            hasMedanPricelistItem: IndirectApprovalRules.cartHasMedanArea(cart),
            hasCustomSizeItem: IndirectApprovalRules.cartHasCustomSize(cart),
          ),
          isFalse,
        );
      });
    });
  });
}
