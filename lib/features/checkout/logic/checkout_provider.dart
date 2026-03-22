import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/utils/app_telemetry.dart';
import '../../../core/utils/log.dart';
import '../../cart/data/cart_item.dart';
import '../../cart/logic/cart_provider.dart';
import '../../profile/logic/profile_provider.dart';
import '../../pricelist/data/models/item_lookup.dart';
import '../../pricelist/logic/item_lookup_provider.dart';
import '../../history/logic/order_history_provider.dart';
import '../../approval/logic/approval_inbox_provider.dart';
import '../data/models/approver_model.dart';
import '../data/services/approval_service.dart';
import '../data/models/checkout_models.dart';
import '../data/services/checkout_order_service.dart';
import '../data/services/local_contact_service.dart';

part 'checkout_provider.freezed.dart';

// ─────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────

@freezed
class CheckoutState with _$CheckoutState {
  const factory CheckoutState({
    // Approvers
    @Default([]) List<Approver> approvers,
    @Default(true) bool isLoadingApprovers,
    String? approversError,
    Approver? selectedSpv,
    Approver? selectedManager,

    // Submission
    @Default(false) bool isSubmitting,
    String? submitError,

    // Retry
    int? retryOrderId,
    @Default('') String retryNoSp,
    @Default([]) List<PendingDetail> retryDetails,

    // Result
    @Default(false) bool submitSuccess,
    String? successNoSp,
  }) = _CheckoutState;
}

// ─────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier(this._ref) : super(const CheckoutState()) {
    _orderService = CheckoutOrderService();
  }

  final Ref _ref;
  late final CheckoutOrderService _orderService;

  // ── Approvers ─────────────────────────────────────────────────

  Future<void> fetchApprovers() async {
    state = state.copyWith(
      isLoadingApprovers: true,
      approversError: null,
    );
    try {
      final profile = await _ref.read(profileProvider.future);
      final companyId = profile?.companyId ?? 0;
      final areaId = profile?.areaId ?? 0;
      final data = await ApprovalService().getApprovers(companyId, areaId);
      data.sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      state = state.copyWith(
        approvers: data,
        isLoadingApprovers: false,
        approversError: data.isEmpty
            ? 'Tidak ada approver ditemukan untuk area ini.'
            : null,
      );
    } catch (e, st) {
      Log.error(e, st, reason: 'CheckoutNotifier.fetchApprovers');
      state = state.copyWith(
        approvers: [],
        isLoadingApprovers: false,
        approversError: e.toString(),
      );
    }
  }

  void selectSpv(Approver? approver) {
    state = state.copyWith(selectedSpv: approver);
  }

  void selectManager(Approver? approver) {
    state = state.copyWith(selectedManager: approver);
  }

  // ── Submit Order ──────────────────────────────────────────────

  /// Orchestrates the full checkout pipeline (5 steps).
  ///
  /// Form data that lives in TextEditingControllers is passed as parameters
  /// because controllers are bound to the widget lifecycle and should not
  /// leak into provider state.
  Future<void> submitOrder({
    required List<CartItem> cartItems,
    required Map<String, dynamic> headerPayload,
    required List<Map<String, dynamic>> contactsPayload,
    required List<Map<String, dynamic>> paymentPayloads,
    required List<File?> receiptImages,
    required bool globalIsTakeAway,
    required bool Function(int itemIndex, CartBonusSnapshot)
        isBonusTakeAwayChecked,
    required int Function(int itemIndex, CartBonusSnapshot) currentTakeAwayQty,
    // Contact saving
    required String? selectedContactId,
    required bool shouldSaveCustomerContact,
    required Map<String, dynamic>? newCustomerContact,
    // Cart cleanup
    required List<CartItem>? selectedCartItems,
  }) async {
    final totalSw = Stopwatch()..start();
    AppTelemetry.event(
      'checkout_submit_started',
      data: {
        'cart_items': cartItems.length,
        'payments': paymentPayloads.length,
        'has_selected_items':
            selectedCartItems != null && selectedCartItems.isNotEmpty,
      },
      tag: 'CheckoutFlow',
    );
    state = state.copyWith(
      isSubmitting: true,
      submitError: null,
      submitSuccess: false,
      successNoSp: null,
    );

    try {
      final prepSw = Stopwatch()..start();
      final int userId = await StorageService.loadUserId();
      final String token = await StorageService.loadAccessToken();

      final int? workPlaceId =
          await _orderService.getLatestWorkPlaceId(userId, token);

      if (workPlaceId == null || workPlaceId <= 0) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: 'Tempat kerja tidak terdeteksi.\n\n'
              'Riwayat absensi Anda belum memiliki lokasi kantor yang valid. '
              'Silakan lakukan Check-In ulang di aplikasi absensi dengan '
              'memilih tempat kerja (bukan WOH/WFH/Work Out Side).\n\n'
              'Setelah Check-In berhasil, coba buat Surat Pesanan kembali.',
        );
        totalSw.stop();
        AppTelemetry.error(
          'checkout_missing_workplace',
          data: {'user_id': userId},
          tag: 'CheckoutFlow',
        );
        return;
      }

      final leaderData = await _orderService.fetchLeaderByUser(userId, token);
      headerPayload['work_place_id'] = workPlaceId;

      final rawLookup = await _ref.read(itemLookupProvider.future);
      final lookupByItemNum = <String, ItemLookup>{};
      for (final list in rawLookup.values) {
        for (final entry in list) {
          if (entry.itemNum.isNotEmpty) lookupByItemNum[entry.itemNum] = entry;
        }
      }

      final profile = _ref.read(profileProvider).valueOrNull;

      final pendingDetails = _orderService.buildPendingDetails(
        cartItems: cartItems,
        userId: userId,
        leaderData: leaderData,
        lookupByItemNum: lookupByItemNum,
        selectedSpv: state.selectedSpv,
        selectedManager: state.selectedManager,
        globalIsTakeAway: globalIsTakeAway,
        isBonusTakeAwayChecked: isBonusTakeAwayChecked,
        currentTakeAwayQty: currentTakeAwayQty,
        profileName: profile?.name ?? 'User',
      );
      prepSw.stop();
      AppTelemetry.event(
        'checkout_prep_completed',
        data: {
          'duration_ms': prepSw.elapsedMilliseconds,
          'pending_details': pendingDetails.length,
        },
        tag: 'CheckoutFlow',
      );

      // ── STEP 1: Create Order Letter Header ──
      final step1 = Stopwatch()..start();
      final orderResult =
          await _orderService.createOrderLetter(headerPayload, token);
      step1.stop();
      AppTelemetry.event(
        'checkout_step1_header_ok',
        data: {'duration_ms': step1.elapsedMilliseconds},
        tag: 'CheckoutFlow',
      );
      final orderLetterId = orderResult.orderLetterId;
      final noSp = orderResult.noSp;

      state = state.copyWith(
        retryOrderId: orderLetterId,
        retryNoSp: noSp,
      );

      // Auto-save customer contact
      final shouldPersist = selectedContactId != null ||
          (selectedContactId == null && shouldSaveCustomerContact);
      if (shouldPersist && newCustomerContact != null) {
        final name = (newCustomerContact['name'] as String?) ?? '';
        final phone = (newCustomerContact['phone'] as String?) ?? '';
        if (name.isNotEmpty && phone.isNotEmpty) {
          try {
            await LocalContactService.saveContact(newCustomerContact);
          } catch (e, st) {
            Log.error(e, st, reason: 'Checkout: save local contact');
          }
        }
      }

      // ── STEP 2: Post Contacts ──
      final step2 = Stopwatch()..start();
      await _orderService.postContacts(contactsPayload, orderLetterId, token);
      step2.stop();
      AppTelemetry.event(
        'checkout_step2_contacts_ok',
        data: {
          'duration_ms': step2.elapsedMilliseconds,
          'contacts': contactsPayload.length,
        },
        tag: 'CheckoutFlow',
      );

      // ── STEP 3: Post Payments ──
      final step3 = Stopwatch()..start();
      for (int i = 0; i < paymentPayloads.length; i++) {
        await _orderService.postPayment(
          paymentPayload: paymentPayloads[i],
          orderLetterId: orderLetterId,
          receiptImage: i < receiptImages.length ? receiptImages[i] : null,
          token: token,
        );
      }
      step3.stop();
      AppTelemetry.event(
        'checkout_step3_payments_ok',
        data: {
          'duration_ms': step3.elapsedMilliseconds,
          'payments': paymentPayloads.length,
        },
        tag: 'CheckoutFlow',
      );

      // ── STEP 4: Post Details ──
      final step4 = Stopwatch()..start();
      final detailResult = await _orderService.postDetails(
        pendingDetails,
        orderLetterId,
        token,
        noSp: noSp,
      );
      step4.stop();
      AppTelemetry.event(
        'checkout_step4_details_done',
        data: {
          'duration_ms': step4.elapsedMilliseconds,
          'succeeded': detailResult.succeeded.length,
          'failed': detailResult.failed.length,
        },
        tag: 'CheckoutFlow',
      );

      // ── STEP 5: Post Discounts ──
      if (detailResult.succeeded.isNotEmpty) {
        final step5 = Stopwatch()..start();
        // If any detail didn't return an ID from POST, fetch as fallback
        final needsFallback =
            detailResult.succeeded.any((s) => s.detailId <= 0);
        final fallbackIds = needsFallback
            ? await _orderService.fetchDetailIds(orderLetterId, token)
            : <int>[];

        await _orderService.postDiscountsForDetails(
          succeededDetails: detailResult.succeeded,
          orderLetterId: orderLetterId,
          token: token,
          fallbackDetailIds: fallbackIds,
        );
        step5.stop();
        AppTelemetry.event(
          'checkout_step5_discounts_done',
          data: {
            'duration_ms': step5.elapsedMilliseconds,
            'needs_fallback': needsFallback,
          },
          tag: 'CheckoutFlow',
        );
      }

      // ── Result ──
      if (detailResult.failed.isEmpty) {
        // All succeeded — clear cart items that were checked out.
        if (selectedCartItems != null && selectedCartItems.isNotEmpty) {
          await _ref.read(cartProvider.notifier).removeItemsByIds(
                selectedCartItems.map(cartItemKey).toSet(),
              );
        } else {
          await _ref.read(cartProvider.notifier).clearCart();
        }
        _ref.invalidate(orderHistoryProvider);
        unawaited(_ref.read(approvalInboxProvider.notifier).fetchInbox());

        state = state.copyWith(
          isSubmitting: false,
          retryDetails: const [],
          retryOrderId: null,
          retryNoSp: '',
          submitSuccess: true,
          successNoSp: noSp,
        );
        totalSw.stop();
        AppTelemetry.event(
          'checkout_submit_success',
          data: {'duration_ms': totalSw.elapsedMilliseconds},
          tag: 'CheckoutFlow',
        );
      } else {
        state = state.copyWith(
          isSubmitting: false,
          retryDetails: detailResult.failed,
          submitError:
              'SP $noSp berhasil dibuat, tetapi ${detailResult.failed.length} '
              'item berikut gagal tersimpan:\n\n'
              '${detailResult.failed.map((e) => '• ${e.label}').join('\n')}\n\n'
              'Tekan tombol "Coba Lagi Kirim Barang Gagal" yang muncul di '
              'halaman ini untuk mengirim ulang tanpa membuat SP baru.',
        );
        totalSw.stop();
        AppTelemetry.error(
          'checkout_submit_partial_failure',
          data: {
            'duration_ms': totalSw.elapsedMilliseconds,
            'failed_details': detailResult.failed.length,
          },
          tag: 'CheckoutFlow',
        );
      }
    } on CheckoutStepException catch (e, st) {
      Log.error(e, st, reason: 'CheckoutNotifier.submitOrder');
      totalSw.stop();
      AppTelemetry.error(
        'checkout_submit_exception',
        data: {
          'duration_ms': totalSw.elapsedMilliseconds,
          'step': e.step,
          'step_name': e.stepName,
          'endpoint': e.endpoint,
          'status_code': e.statusCode,
        },
        tag: 'CheckoutFlow',
      );
      state = state.copyWith(
        isSubmitting: false,
        submitError: 'Gagal di ${e.stepName}.\n'
            'Jika internet tidak stabil, mohon cek riwayat pesanan '
            'sebelum mencoba lagi.\n\n$e',
      );
    } catch (e, st) {
      Log.error(e, st, reason: 'CheckoutNotifier.submitOrder');
      totalSw.stop();
      AppTelemetry.error(
        'checkout_submit_exception',
        data: {
          'duration_ms': totalSw.elapsedMilliseconds,
          'error_type': e.runtimeType.toString(),
        },
        tag: 'CheckoutFlow',
      );
      state = state.copyWith(
        isSubmitting: false,
        submitError: 'Terjadi kesalahan. Jika internet tidak stabil, mohon cek '
            'riwayat pesanan sebelum mencoba lagi.\n\nDetail:\n$e',
      );
    }
  }

  // ── Retry Failed Details ──────────────────────────────────────

  Future<void> retryFailedDetails({
    required List<CartItem>? selectedCartItems,
  }) async {
    final orderId = state.retryOrderId;
    if (orderId == null || state.retryDetails.isEmpty) return;

    state = state.copyWith(
      isSubmitting: true,
      submitError: null,
      submitSuccess: false,
    );

    final sw = Stopwatch()..start();
    try {
      final String token = await StorageService.loadAccessToken();

      final detailResult = await _orderService.postDetails(
        state.retryDetails,
        orderId,
        token,
        noSp: state.retryNoSp,
      );

      if (detailResult.succeeded.isNotEmpty) {
        final needsFallback =
            detailResult.succeeded.any((s) => s.detailId <= 0);
        final fallbackIds = needsFallback
            ? await _orderService.fetchDetailIds(orderId, token)
            : <int>[];

        await _orderService.postDiscountsForDetails(
          succeededDetails: detailResult.succeeded,
          orderLetterId: orderId,
          token: token,
          fallbackDetailIds: fallbackIds,
        );
      }

      if (detailResult.failed.isEmpty) {
        if (selectedCartItems != null && selectedCartItems.isNotEmpty) {
          await _ref.read(cartProvider.notifier).removeItemsByIds(
                selectedCartItems.map(cartItemKey).toSet(),
              );
        } else {
          await _ref.read(cartProvider.notifier).clearCart();
        }

        state = state.copyWith(
          isSubmitting: false,
          retryDetails: const [],
          retryOrderId: null,
          retryNoSp: '',
          submitSuccess: true,
          successNoSp: state.retryNoSp,
        );
        sw.stop();
        AppTelemetry.event(
          'checkout_retry_success',
          data: {'duration_ms': sw.elapsedMilliseconds},
          tag: 'CheckoutFlow',
        );
      } else {
        state = state.copyWith(
          isSubmitting: false,
          retryDetails: detailResult.failed,
          submitError:
              '${detailResult.failed.length} item masih gagal. Coba lagi nanti.',
        );
        sw.stop();
        AppTelemetry.error(
          'checkout_retry_partial_failure',
          data: {
            'duration_ms': sw.elapsedMilliseconds,
            'failed_details': detailResult.failed.length,
          },
          tag: 'CheckoutFlow',
        );
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'CheckoutNotifier.retryFailedDetails');
      sw.stop();
      AppTelemetry.error(
        'checkout_retry_exception',
        data: {
          'duration_ms': sw.elapsedMilliseconds,
          'error_type': e.runtimeType.toString(),
        },
        tag: 'CheckoutFlow',
      );
      state = state.copyWith(
        isSubmitting: false,
        submitError: 'Error: $e',
      );
    }
  }

  /// Resets transient submit/error flags so the UI can react again
  /// on subsequent submissions.
  void clearSubmitResult() {
    state = state.copyWith(
      submitSuccess: false,
      submitError: null,
      successNoSp: null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────

final checkoutProvider =
    StateNotifierProvider.autoDispose<CheckoutNotifier, CheckoutState>(
  (ref) => CheckoutNotifier(ref),
);
