import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/utils/app_telemetry.dart';
import '../../../core/utils/log.dart';
import '../../../core/utils/network_error.dart';
import '../../cart/data/cart_item.dart';
import '../../cart/logic/cart_provider.dart';
import '../../profile/logic/profile_provider.dart';
import '../../pricelist/data/models/item_lookup.dart';
import '../../pricelist/logic/item_lookup_provider.dart';
import '../../history/logic/order_history_provider.dart';
import '../../approval/logic/approval_decision_service.dart';
import '../../approval/logic/approval_inbox_provider.dart';
import '../../history/data/models/order_history.dart';
import '../../history/data/services/edit_details_service.dart';
import '../../history/logic/order_detail_provider.dart';
import '../data/models/approver_model.dart';
import '../data/models/store_model.dart';
import '../data/services/approval_service.dart';
import '../data/models/checkout_models.dart';
import '../data/services/checkout_order_service.dart';
import '../data/services/customer_repository.dart';
import '../data/services/local_contact_service.dart';
import 'customer_repository_provider.dart';

part 'checkout_provider.freezed.dart';

// ─────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────

@freezed
class CheckoutState with _$CheckoutState {
  const factory CheckoutState({
    // Workplace / Store
    @Default(true) bool isLoadingWorkPlace,
    int? attendanceWorkPlaceId,
    @Default('') String attendanceWorkPlaceName,
    @Default(true) bool useAttendanceStore,
    StoreModel? selectedStore,

    // Approvers
    @Default([]) List<Approver> approvers,
    @Default(true) bool isLoadingApprovers,
    String? approversError,
    /// Judul kartu error (bukan lagi satu pesan generik untuk semua kasus).
    String? approversErrorTitle,
    Approver? selectedSpv,
    Approver? selectedManager,

    // Submission
    @Default(false) bool isSubmitting,
    String? submitError,

    // Retry
    int? retryOrderId,
    @Default('') String retryNoSp,
    @Default([]) List<PendingDetail> retryDetails,
    @Default([]) List<int> retryCompletedSteps,
    @Default(0) int retryContactStartIndex,
    @Default(0) int retryPaymentStartIndex,
    @Default([]) List<SucceededDetail> retryDiscountDetails,

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

  bool _fetchWorkPlaceInFlight = false;
  bool _fetchApproversInFlight = false;

  // ── Workplace / Store ───────────────────────────────────────────

  Future<void> fetchAttendanceWorkPlace() async {
    if (_fetchWorkPlaceInFlight) return;
    _fetchWorkPlaceInFlight = true;
    state = state.copyWith(isLoadingWorkPlace: true);
    try {
      final userId = await StorageService.loadUserId();
      final token = await StorageService.loadAccessToken();
      final wp = await _orderService.getLatestWorkPlace(userId, token);
      if (wp != null) {
        state = state.copyWith(
          isLoadingWorkPlace: false,
          attendanceWorkPlaceId: wp.$1,
          attendanceWorkPlaceName: wp.$2,
        );
      } else {
        state = state.copyWith(
          isLoadingWorkPlace: false,
          useAttendanceStore: false,
        );
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'CheckoutNotifier.fetchAttendanceWorkPlace');
      state = state.copyWith(
        isLoadingWorkPlace: false,
        useAttendanceStore: false,
      );
    } finally {
      _fetchWorkPlaceInFlight = false;
    }
  }

  void toggleUseAttendanceStore(bool value) {
    state = state.copyWith(
      useAttendanceStore: value,
      selectedStore: value ? null : state.selectedStore,
    );
  }

  void updateStore(StoreModel store) {
    state = state.copyWith(
      selectedStore: store,
      useAttendanceStore: false,
    );
  }

  /// Returns the effective `work_place_id` to be sent in the header payload.
  int? get effectiveWorkPlaceId {
    if (state.useAttendanceStore) return state.attendanceWorkPlaceId;
    return state.selectedStore?.id;
  }

  /// Label lokasi toko untuk penawaran/PDF — sama sumbernya dengan UI checkout
  /// (absensi terbaru vs toko yang dipilih manual).
  String get effectiveWorkPlaceName {
    if (state.useAttendanceStore) {
      return state.attendanceWorkPlaceName.trim();
    }
    final store = state.selectedStore;
    if (store != null) return store.displayLabelOrFallback;
    return '';
  }

  // ── Approvers ─────────────────────────────────────────────────

  Future<void> fetchApprovers() async {
    if (_fetchApproversInFlight) return;
    _fetchApproversInFlight = true;
    state = state.copyWith(
      isLoadingApprovers: true,
      approversError: null,
      approversErrorTitle: null,
    );
    try {
      // Timeout jaga-jaga: mencegah kartu "Persetujuan Surat Pesanan" macet
      // loading selamanya jika profileProvider tergantung tanpa batas waktu
      // (mis. platform channel storage yang hang, di luar timeout HTTP-nya).
      final profile = await _ref
          .read(profileProvider.future)
          .timeout(const Duration(seconds: 20));
      if (profile == null) {
        state = state.copyWith(
          approvers: [],
          isLoadingApprovers: false,
          approversErrorTitle: 'Profil kerja tidak tersedia',
          approversError:
              'Data tempat kerja (CWE) tidak bisa dimuat. Periksa koneksi internet, lalu ketuk Coba Lagi. Jika berulang, hubungi administrator.',
        );
        return;
      }

      final companyId = profile.companyId;
      final areaId = profile.areaId;
      if (companyId <= 0 && areaId <= 0) {
        state = state.copyWith(
          approvers: [],
          isLoadingApprovers: false,
          approversErrorTitle: 'Perusahaan dan area belum lengkap',
          approversError:
              'Profil Anda tidak memiliki perusahaan dan area yang valid untuk persetujuan pesanan. Minta administrator melengkapi data CWE (company & area).',
        );
        return;
      }
      if (companyId <= 0) {
        state = state.copyWith(
          approvers: [],
          isLoadingApprovers: false,
          approversErrorTitle: 'Perusahaan belum terpasang',
          approversError:
              'Profil Anda tidak memiliki perusahaan (company) yang valid. Hubungi administrator untuk melengkapi data CWE.',
        );
        return;
      }
      if (areaId <= 0) {
        state = state.copyWith(
          approvers: [],
          isLoadingApprovers: false,
          approversErrorTitle: 'Area kerja belum terpasang',
          approversError:
              'Profil Anda tidak memiliki area yang valid. Hubungi administrator untuk melengkapi data CWE (area).',
        );
        return;
      }

      final data = await ApprovalService().getApprovers(companyId, areaId);
      data.sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      state = state.copyWith(
        approvers: data,
        isLoadingApprovers: false,
        approversError: data.isEmpty
            ? 'Belum ada Supervisor (SPV), Area Sales Manager (ASM), atau Manager yang terdaftar untuk perusahaan dan area Anda di sistem persetujuan. Hubungi administrator untuk mengatur daftar approver.'
            : null,
        approversErrorTitle: data.isEmpty
            ? 'Tidak ada atasan yang cocok'
            : null,
      );
    } catch (e, st) {
      Log.error(e, st, reason: 'CheckoutNotifier.fetchApprovers');
      final (title, detail) = _approverFetchFailureMessage(e);
      state = state.copyWith(
        approvers: [],
        isLoadingApprovers: false,
        approversErrorTitle: title,
        approversError: detail,
      );
    } finally {
      _fetchApproversInFlight = false;
    }
  }

  /// Pesan user-facing untuk gagal fetch API (bukan stack / HTTP mentah).
  (String title, String detail) _approverFetchFailureMessage(Object e) {
    if (isNetworkError(e)) {
      return (
        'Koneksi bermasalah',
        'Tidak dapat menghubungi server. Periksa internet lalu ketuk Coba Lagi.',
      );
    }
    final raw = e.toString();
    final stripped =
        raw.startsWith('Exception: ') ? raw.substring('Exception: '.length) : raw;
    if (stripped.startsWith('HTTP ')) {
      return (
        'Gagal mengambil daftar approver',
        'Server mengembalikan error. Coba lagi nanti atau hubungi administrator.',
      );
    }
    return ('Gagal memuat daftar approver', stripped);
  }

  // ── Aturan Klaus (auto-assign RSM) ────────────────────────────
  // Jika work_place_id 1937/6015 DAN SPV yang dipilih 4147/1019,
  // Pak Klaus (5247) otomatis menjadi RSM (Manager) di approval chain.
  static const int _klausUserId = 5247;
  static const Set<int> _klausWorkPlaceIds = {1937, 6015};
  static const Set<int> _klausSpvIds = {4147, 1019};

  /// True saat aturan Klaus aktif: workplace 1937/6015 + SPV 4147/1019.
  bool get isKlausRuleActive {
    final wpId = effectiveWorkPlaceId ?? 0;
    final spvId = state.selectedSpv?.id ?? 0;
    return _klausWorkPlaceIds.contains(wpId) && _klausSpvIds.contains(spvId);
  }

  /// Bangun Approver untuk Pak Klaus — cari dari list approvers yang sudah
  /// di-fetch; jika tidak ada (beda area/company), gunakan data minimal
  /// karena server mengenali Klaus berdasarkan ID.
  Approver get _klausApprover {
    return state.approvers.where((a) => a.id == _klausUserId).firstOrNull ??
        const Approver(
          id: _klausUserId,
          userName: 'pak_klaus',
          fullName: 'Klaus',
          jobLevelName: 'RSM',
        );
  }

  void selectSpv(Approver? approver) {
    final wpId = effectiveWorkPlaceId ?? 0;
    final klausTriggered = approver != null &&
        _klausSpvIds.contains(approver.id) &&
        _klausWorkPlaceIds.contains(wpId);

    Approver? newManager = state.selectedManager;
    if (klausTriggered) {
      // Auto-assign Klaus sebagai RSM.
      newManager = _klausApprover;
    } else if (state.selectedManager?.id == _klausUserId) {
      // SPV berganti ke non-trigger → hapus Klaus yang sebelumnya auto-set.
      newManager = null;
    }

    state = state.copyWith(selectedSpv: approver, selectedManager: newManager);
  }

  /// Defense-in-depth: page-level `_validateForm()`/`_validateApprovalOnly()`
  /// sudah memblokir submit kalau approver wajib belum dipilih — tapi validasi
  /// itu hidup di UI dan bisa saja diubah/lupa dipanggil di masa depan
  /// (persis seperti bug "Customer Baru hilang saat edit item", Jul 2026).
  /// Guard ini membuat kelas bug itu MUSTAHIL lolos diam-diam: kalau caller
  /// bilang approval wajib tapi approver-nya `null`, gagal keras di sini
  /// alih-alih membuat/mengedit order dengan baris approval yang hilang.
  void _assertApprovalNotSilentlyDropped({
    required bool requiresSpvApproval,
    required bool requiresManagerApproval,
  }) {
    if (requiresSpvApproval && state.selectedSpv == null) {
      throw StateError(
        'Approval SPV/ASM wajib untuk pesanan ini tapi belum dipilih — '
        'submit dibatalkan untuk mencegah order tanpa baris approval.',
      );
    }
    if (requiresManagerApproval && state.selectedManager == null) {
      throw StateError(
        'Approval Manager/RSM wajib untuk pesanan ini tapi belum dipilih — '
        'submit dibatalkan untuk mencegah order tanpa baris approval.',
      );
    }
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
    required bool Function(int itemIndex) lineIsTakeAway,
    required bool Function(int itemIndex, CartBonusSnapshot)
        isBonusTakeAwayChecked,
    required int Function(int itemIndex, CartBonusSnapshot) currentTakeAwayQty,
    // Contact saving
    required String? selectedContactId,
    required bool shouldSaveCustomerContact,
    required Map<String, dynamic>? newCustomerContact,
    // Cart cleanup
    required List<CartItem>? selectedCartItems,
    // Jika false (indirect tanpa diskon tambahan → autoApprove), selectedSpv
    // dan selectedManager tidak dipakai agar tidak membuat baris approval
    // dengan approved=null sementara order_letters sudah berstatus Approved.
    bool requiresApproval = true,
    // Flag granular untuk guard [_assertApprovalNotSilentlyDropped] —
    // default false (tidak menambah assertion) agar caller lama/test yang
    // belum mengirim flag ini tidak berubah perilakunya.
    bool requiresSpvApproval = false,
    bool requiresManagerApproval = false,
  }) async {
    if (state.isSubmitting) return; // Reentrancy guard

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

    // Deklarasikan di luar try agar catch block bisa akses untuk reconciliation.
    var token = '';
    var orderLetterId = 0;
    var completedSteps = Set<int>.from(state.retryCompletedSteps);

    try {
      _assertApprovalNotSilentlyDropped(
        requiresSpvApproval: requiresSpvApproval,
        requiresManagerApproval: requiresManagerApproval,
      );

      final prepSw = Stopwatch()..start();
      final int userId = await StorageService.loadUserId();
      token = await StorageService.loadAccessToken();

      final int? workPlaceId = effectiveWorkPlaceId;

      if (workPlaceId == null || workPlaceId <= 0) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: 'Lokasi toko belum dipilih.\n\n'
              'Pilih lokasi toko dari absensi atau pilih toko lain '
              'di bagian Informasi Pengiriman.',
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
        selectedSpv: requiresApproval ? state.selectedSpv : null,
        selectedManager: requiresApproval ? state.selectedManager : null,
        lineIsTakeAway: lineIsTakeAway,
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

      // ── Resume Check: Jika run sebelumnya sudah membuat order_letters, pakai yang sama ──
      // Mencegah duplikasi order_letters saat user mengirim ulang setelah kegagalan step 2–5.
      final existingOrderId = state.retryOrderId;
      final isResumingOrder = existingOrderId != null;
      // completedSteps sudah diinisialisasi di luar try block (untuk akses di catch).
      completedSteps = Set<int>.from(state.retryCompletedSteps);

      String noSp;

      if (isResumingOrder) {
        orderLetterId = existingOrderId;
        noSp = state.retryNoSp;
        Log.info(
          'Melanjutkan SP $noSp (order_letters #$existingOrderId) — '
          'pembuatan SP baru dilewati',
          tag: 'CheckoutFlow',
        );
      } else {
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
        orderLetterId = orderResult.orderLetterId;
        noSp = orderResult.noSp;
        completedSteps.add(1);
        state = state.copyWith(
          retryOrderId: orderLetterId,
          retryNoSp: noSp,
          retryCompletedSteps: completedSteps.toList(),
        );

        // Auto-save customer contact (hanya untuk order baru, bukan saat retry)
        final shouldPersist = selectedContactId != null ||
            (selectedContactId == null && shouldSaveCustomerContact);
        if (shouldPersist && newCustomerContact != null) {
          final name = (newCustomerContact['name'] as String?) ?? '';
          final phone = (newCustomerContact['phone'] as String?) ?? '';
          final email = (newCustomerContact['email'] as String?) ?? '';
          if (name.isNotEmpty || phone.isNotEmpty || email.isNotEmpty) {
            try {
              await LocalContactService.saveContact(newCustomerContact);
            } catch (e, st) {
              Log.error(e, st, reason: 'Checkout: save local contact');
            }
          }
        }
      }

      // ── STEP 2: Post Contacts ──
      // Dilewati jika sudah berhasil di run sebelumnya (mencegah duplikasi kontak).
      if (!completedSteps.contains(2)) {
        await _reconcileContactIndex(
          orderLetterId: orderLetterId,
          token: token,
          completedSteps: completedSteps,
          totalContacts: contactsPayload.length,
        );
        completedSteps = Set<int>.from(state.retryCompletedSteps);
      }
      if (!completedSteps.contains(2)) {
        final step2 = Stopwatch()..start();
        final contactStartIdx = state.retryContactStartIndex;
        await _orderService.postContacts(
          contactsPayload,
          orderLetterId,
          token,
          startIndex: contactStartIdx,
          onContactPosted: (idx) {
            state = state.copyWith(retryContactStartIndex: idx + 1);
          },
        );
        step2.stop();
        completedSteps.add(2);
        state = state.copyWith(
          retryCompletedSteps: completedSteps.toList(),
          retryContactStartIndex: 0, // Reset untuk use berikutnya
        );
        AppTelemetry.event(
          'checkout_step2_contacts_ok',
          data: {
            'duration_ms': step2.elapsedMilliseconds,
            'contacts': contactsPayload.length,
            'contacts_skipped': contactStartIdx,
          },
          tag: 'CheckoutFlow',
        );
      }

      // ── STEP 3: Post Payments ──
      // Dilewati jika sudah berhasil di run sebelumnya (mencegah duplikasi pembayaran).
      if (!completedSteps.contains(3) && paymentPayloads.isNotEmpty) {
        final payStartIdx = await _postPaymentPayloadsSafely(
          orderLetterId: orderLetterId,
          token: token,
          paymentPayloads: paymentPayloads,
          receiptImages: receiptImages,
          completedSteps: completedSteps,
        );
        completedSteps = Set<int>.from(state.retryCompletedSteps);
        if (!completedSteps.contains(3)) {
          completedSteps.add(3);
        }
        state = state.copyWith(
          retryCompletedSteps: completedSteps.toList(),
          retryPaymentStartIndex: 0,
        );
        AppTelemetry.event(
          'checkout_step3_payments_ok',
          data: {
            'payments': paymentPayloads.length,
            'payments_skipped': payStartIdx,
          },
          tag: 'CheckoutFlow',
        );
      } else if (paymentPayloads.isEmpty && !completedSteps.contains(3)) {
        // Tidak ada pembayaran di checkout (mis. indirect) — tandai step selesai.
        completedSteps.add(3);
        state = state.copyWith(retryCompletedSteps: completedSteps.toList());
      }

      // ── STEP 4: Post Details ──
      // Kasus khusus: jika step 4 sudah selesai (semua detail ada di DB) tetapi
      // step 5 (diskon) sebelumnya gagal, lewati re-POST detail dan gunakan
      // retryDiscountDetails yang tersimpan untuk retry diskon saja.
      List<SucceededDetail> succeededForDiscounts;
      List<PendingDetail> failedDetails;

      if (completedSteps.contains(4) && state.retryDiscountDetails.isNotEmpty) {
        Log.info(
          'SP $noSp: step 4 sudah selesai — retry diskon untuk '
          '${state.retryDiscountDetails.length} detail',
          tag: 'CheckoutFlow',
        );
        succeededForDiscounts = state.retryDiscountDetails;
        failedDetails = const [];
        state = state.copyWith(retryDiscountDetails: const []);
      } else {
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
        succeededForDiscounts = detailResult.succeeded;
        failedDetails = detailResult.failed;
        if (failedDetails.isEmpty) {
          completedSteps.add(4);
          state = state.copyWith(retryCompletedSteps: completedSteps.toList());
        }
      }

      // ── STEP 5: Post Discounts ──
      List<SucceededDetail> failedDiscountDetails = const [];
      if (succeededForDiscounts.isNotEmpty) {
        // Simpan ke state sebelum post diskon agar retry bisa melanjutkan jika gagal.
        state = state.copyWith(
          retryDiscountDetails: succeededForDiscounts,
          retryDetails: failedDetails,
        );

        final step5 = Stopwatch()..start();
        final needsFallback =
            succeededForDiscounts.any((s) => s.detailId <= 0);
        final fallbackIds = needsFallback
            ? await _orderService.fetchDetailIds(orderLetterId, token)
            : <int>[];

        failedDiscountDetails = await _orderService.postDiscountsForDetails(
          succeededDetails: succeededForDiscounts,
          orderLetterId: orderLetterId,
          token: token,
          fallbackDetailIds: fallbackIds,
        );
        step5.stop();

        if (failedDiscountDetails.isEmpty) {
          completedSteps.add(5);
          state = state.copyWith(
            retryCompletedSteps: completedSteps.toList(),
            retryDiscountDetails: const [],
          );
        } else {
          state = state.copyWith(retryDiscountDetails: failedDiscountDetails);
        }
        AppTelemetry.event(
          'checkout_step5_discounts_done',
          data: {
            'duration_ms': step5.elapsedMilliseconds,
            'needs_fallback': needsFallback,
            'failed_details': failedDiscountDetails.length,
          },
          tag: 'CheckoutFlow',
        );
      }

      // ── Result ──
      if (failedDetails.isEmpty && failedDiscountDetails.isEmpty) {
        if (selectedCartItems != null && selectedCartItems.isNotEmpty) {
          await _ref.read(cartProvider.notifier).removeItemsByIds(
                selectedCartItems.map(cartItemKey).toSet(),
              );
        } else {
          await _ref.read(cartProvider.notifier).clearCart();
        }
        _ref.invalidate(orderHistoryProvider);
        unawaited(_ref.read(approvalInboxProvider.notifier).fetchInbox(force: true));

        state = state.copyWith(
          isSubmitting: false,
          retryDetails: const [],
          retryDiscountDetails: const [],
          retryOrderId: null,
          retryNoSp: '',
          retryCompletedSteps: const [],
          retryContactStartIndex: 0,
          retryPaymentStartIndex: 0,
          submitSuccess: true,
          successNoSp: noSp,
        );
        unawaited(
          CustomerRepository.upsertFromCheckoutContactMapQuiet(
            _ref.read(customerRepositoryProvider),
            newCustomerContact,
          ),
        );

        unawaited(_notifyFirstApprover(
          orderLetterId: orderLetterId,
          noSp: noSp,
          token: token,
          userId: userId,
          senderName: profile?.name ?? 'User',
        ));

        totalSw.stop();
        AppTelemetry.event(
          'checkout_submit_success',
          data: {'duration_ms': totalSw.elapsedMilliseconds},
          tag: 'CheckoutFlow',
        );
      } else if (failedDetails.isEmpty && failedDiscountDetails.isNotEmpty) {
        // Detail semuanya berhasil, tetapi sebagian diskon gagal dicatat
        totalSw.stop();
        AppTelemetry.error(
          'checkout_submit_discount_partial_failure',
          data: {
            'duration_ms': totalSw.elapsedMilliseconds,
            'failed_discount_details': failedDiscountDetails.length,
          },
          tag: 'CheckoutFlow',
        );
        state = state.copyWith(
          isSubmitting: false,
          // retryDiscountDetails sudah diset ke failedDiscountDetails di atas
          submitError:
              'SP $noSp berhasil dibuat, tetapi diskon untuk '
              '${failedDiscountDetails.length} item gagal dicatat.\n\n'
              'Tekan tombol "Coba Lagi Kirim Diskon" yang muncul di bawah '
              'untuk mengirim ulang tanpa membuat SP baru.',
        );
      } else {
        state = state.copyWith(
          isSubmitting: false,
          retryDetails: failedDetails,
          submitError:
              'SP $noSp berhasil dibuat, tetapi ${failedDetails.length} '
              'item berikut gagal tersimpan:\n\n'
              '${failedDetails.map((e) => '• ${e.label}').join('\n')}\n\n'
              'Tekan tombol "Coba Lagi Kirim Barang Gagal" yang muncul di '
              'halaman ini untuk mengirim ulang tanpa membuat SP baru.',
        );
        totalSw.stop();
        AppTelemetry.error(
          'checkout_submit_partial_failure',
          data: {
            'duration_ms': totalSw.elapsedMilliseconds,
            'failed_details': failedDetails.length,
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
      // Rekonsiliasi kontak & payment: cegah double-post jika server memproses
      // tapi client timeout sebelum menerima respons.
      await _reconcileContactIndex(
        orderLetterId: orderLetterId,
        token: token,
        completedSteps: completedSteps,
        totalContacts: contactsPayload.length,
      );
      await _reconcilePaymentIndex(
        orderLetterId: orderLetterId,
        token: token,
        completedSteps: completedSteps,
        totalPayments: paymentPayloads.length,
      );
      state = state.copyWith(
        isSubmitting: false,
        submitError: 'Gagal di ${e.stepName}.\n'
            'Jika internet tidak stabil, mohon cek riwayat pesanan '
            'sebelum mencoba lagi.\n\n$e',
      );
    } catch (e, st) {
      if (isNetworkError(e)) {
        Log.warning('CheckoutNotifier.submitOrder (network): $e',
            tag: 'Checkout');
      } else {
        Log.error(e, st, reason: 'CheckoutNotifier.submitOrder');
      }
      totalSw.stop();
      AppTelemetry.error(
        'checkout_submit_exception',
        data: {
          'duration_ms': totalSw.elapsedMilliseconds,
          'error_type': e.runtimeType.toString(),
        },
        tag: 'CheckoutFlow',
      );
      await _reconcileContactIndex(
        orderLetterId: orderLetterId,
        token: token,
        completedSteps: completedSteps,
        totalContacts: contactsPayload.length,
      );
      await _reconcilePaymentIndex(
        orderLetterId: orderLetterId,
        token: token,
        completedSteps: completedSteps,
        totalPayments: paymentPayloads.length,
      );
      state = state.copyWith(
        isSubmitting: false,
        submitError: 'Terjadi kesalahan. Jika internet tidak stabil, mohon cek '
            'riwayat pesanan sebelum mencoba lagi.\n\nDetail:\n$e',
      );
    }
  }

  /// Post payment payloads dengan rekonsiliasi server sebelum & per-index.
  ///
  /// Mencegah double `order_letter_payments` saat:
  /// - server sempat menyimpan sebelum client timeout,
  /// - user retry submit setelah error step berikutnya,
  /// - GET order belum sinkron saat rekonsiliasi pertama.
  ///
  /// Mengembalikan index awal yang dilewati (untuk telemetry).
  Future<int> _postPaymentPayloadsSafely({
    required int orderLetterId,
    required String token,
    required List<Map<String, dynamic>> paymentPayloads,
    required List<File?> receiptImages,
    required Set<int> completedSteps,
  }) async {
    await _reconcilePaymentIndex(
      orderLetterId: orderLetterId,
      token: token,
      completedSteps: completedSteps,
      totalPayments: paymentPayloads.length,
    );
    if (state.retryCompletedSteps.contains(3)) {
      return state.retryPaymentStartIndex;
    }

    final payStartIdx = state.retryPaymentStartIndex;
    final step3 = Stopwatch()..start();

    for (var i = payStartIdx; i < paymentPayloads.length; i++) {
      final existingCount = await _orderService.fetchExistingPaymentCount(
        orderLetterId,
        token,
      );
      if (existingCount >= paymentPayloads.length) {
        Log.info(
          'Payment skip: server sudah punya $existingCount/${paymentPayloads.length}',
          tag: 'CheckoutFlow',
        );
        break;
      }
      if (existingCount > i) {
        Log.info(
          'Payment skip index $i: sudah tercatat di server (count=$existingCount)',
          tag: 'CheckoutFlow',
        );
        state = state.copyWith(retryPaymentStartIndex: i + 1);
        continue;
      }

      await _orderService.postPayment(
        paymentPayload: paymentPayloads[i],
        orderLetterId: orderLetterId,
        receiptImage: i < receiptImages.length ? receiptImages[i] : null,
        token: token,
      );
      state = state.copyWith(retryPaymentStartIndex: i + 1);
    }

    step3.stop();
    AppTelemetry.event(
      'checkout_step3_payments_posted',
      data: {
        'duration_ms': step3.elapsedMilliseconds,
        'payments': paymentPayloads.length,
        'payments_skipped': payStartIdx,
      },
      tag: 'CheckoutFlow',
    );
    return payStartIdx;
  }

  /// Rekonsiliasi retryContactStartIndex setelah error di step 2.
  /// Fetch kontak yang sudah ada di server agar retry tidak re-POST yang sama.
  Future<void> _reconcileContactIndex({
    required int orderLetterId,
    required String token,
    required Set<int> completedSteps,
    required int totalContacts,
  }) async {
    if (completedSteps.contains(2) || orderLetterId <= 0 || totalContacts <= 0) {
      return;
    }
    try {
      final existingCount = await _orderService.fetchExistingContactCount(
        orderLetterId,
        token,
      );
      if (existingCount <= 0) return;

      Log.info(
        'Contact reconciliation: $existingCount/$totalContacts sudah ada di server',
        tag: 'CheckoutFlow',
      );

      if (existingCount >= totalContacts) {
        final updated = {...completedSteps, 2};
        state = state.copyWith(
          retryCompletedSteps: updated.toList(),
          retryContactStartIndex: 0,
        );
      } else {
        state = state.copyWith(retryContactStartIndex: existingCount);
      }
    } catch (e, st) {
      Log.warning(
        'Contact reconciliation gagal (non-critical): $e',
        tag: 'CheckoutFlow',
      );
      Log.error(e, st, reason: '_reconcileContactIndex');
    }
  }

  /// Rekonsiliasi retryPaymentStartIndex setelah error di step 3.
  ///
  /// Jika server sempat menyimpan payment sebelum timeout (network), client
  /// tidak tahu. Method ini fetch jumlah payment yang sudah ada di DB dan
  /// update [state.retryPaymentStartIndex] agar retry tidak re-POST yang sama.
  Future<void> _reconcilePaymentIndex({
    required int orderLetterId,
    required String token,
    required Set<int> completedSteps,
    required int totalPayments,
  }) async {
    // Hanya perlu rekonsiliasi jika step 3 belum selesai dan ada payment.
    if (completedSteps.contains(3) || orderLetterId <= 0 || totalPayments <= 0) {
      return;
    }
    try {
      final existingCount = await _orderService.fetchExistingPaymentCount(
        orderLetterId,
        token,
      );
      if (existingCount <= 0) return;

      Log.info(
        'Payment reconciliation: $existingCount/$totalPayments sudah ada di server',
        tag: 'CheckoutFlow',
      );

      if (existingCount >= totalPayments) {
        // Semua payment sudah ada → tandai step 3 selesai agar tidak di-skip.
        final updated = {...completedSteps, 3};
        state = state.copyWith(
          retryCompletedSteps: updated.toList(),
          retryPaymentStartIndex: 0,
        );
      } else {
        // Sebagian payment sudah ada → lanjutkan dari index berikutnya.
        state = state.copyWith(retryPaymentStartIndex: existingCount);
      }
    } catch (e, st) {
      Log.warning(
        'Payment reconciliation gagal (non-critical): $e',
        tag: 'CheckoutFlow',
      );
      Log.error(e, st, reason: '_reconcilePaymentIndex');
    }
  }

  // ── Retry Failed Details ──────────────────────────────────────

  Future<void> retryFailedDetails({
    required List<CartItem>? selectedCartItems,
  }) async {
    if (state.isSubmitting) return; // Reentrancy guard

    final orderId = state.retryOrderId;
    if (orderId == null) return;

    final hasDetailRetry = state.retryDetails.isNotEmpty;
    final hasDiscountRetry = state.retryDiscountDetails.isNotEmpty;
    if (!hasDetailRetry && !hasDiscountRetry) return;

    state = state.copyWith(
      isSubmitting: true,
      submitError: null,
      submitSuccess: false,
    );

    final sw = Stopwatch()..start();
    try {
      final String token = await StorageService.loadAccessToken();

      List<SucceededDetail> succeededForDiscounts;
      List<PendingDetail> stillFailed;

      if (hasDetailRetry) {
        // Re-post detail yang sebelumnya gagal
        final detailResult = await _orderService.postDetails(
          state.retryDetails,
          orderId,
          token,
          noSp: state.retryNoSp,
        );
        // Gabungkan dengan detail yang butuh retry diskon dari run sebelumnya
        succeededForDiscounts = [
          ...detailResult.succeeded,
          ...state.retryDiscountDetails,
        ];
        stillFailed = detailResult.failed;

        // PENTING: Update retryDetails ke stillFailed SEBELUM mencoba post diskon.
        // Jika discount POST gagal (exception), retry berikutnya TIDAK akan
        // me-POST ulang item yang baru saja berhasil ditambahkan ke DB.
        // Tanpa ini, item-item tersebut akan diposting ganda pada retry berikutnya.
        state = state.copyWith(retryDetails: stillFailed);
      } else {
        // Retry diskon saja — detail sudah tercatat di server
        succeededForDiscounts = state.retryDiscountDetails;
        stillFailed = const [];
      }

      List<SucceededDetail> failedDiscountDetails = const [];
      if (succeededForDiscounts.isNotEmpty) {
        state = state.copyWith(retryDiscountDetails: succeededForDiscounts);

        final needsFallback =
            succeededForDiscounts.any((s) => s.detailId <= 0);
        final fallbackIds = needsFallback
            ? await _orderService.fetchDetailIds(orderId, token)
            : <int>[];

        failedDiscountDetails = await _orderService.postDiscountsForDetails(
          succeededDetails: succeededForDiscounts,
          orderLetterId: orderId,
          token: token,
          fallbackDetailIds: fallbackIds,
        );

        if (failedDiscountDetails.isEmpty) {
          state = state.copyWith(retryDiscountDetails: const []);
        } else {
          state = state.copyWith(retryDiscountDetails: failedDiscountDetails);
        }
      }

      if (stillFailed.isEmpty && failedDiscountDetails.isEmpty) {
        if (selectedCartItems != null && selectedCartItems.isNotEmpty) {
          await _ref.read(cartProvider.notifier).removeItemsByIds(
                selectedCartItems.map(cartItemKey).toSet(),
              );
        } else {
          await _ref.read(cartProvider.notifier).clearCart();
        }

        _ref.invalidate(orderHistoryProvider);
        unawaited(_ref.read(approvalInboxProvider.notifier).fetchInbox(force: true));

        state = state.copyWith(
          isSubmitting: false,
          retryDetails: const [],
          retryDiscountDetails: const [],
          retryOrderId: null,
          retryNoSp: '',
          retryCompletedSteps: const [],
          retryContactStartIndex: 0,
          retryPaymentStartIndex: 0,
          submitSuccess: true,
          successNoSp: state.retryNoSp,
        );
        sw.stop();
        AppTelemetry.event(
          'checkout_retry_success',
          data: {'duration_ms': sw.elapsedMilliseconds},
          tag: 'CheckoutFlow',
        );
      } else if (stillFailed.isEmpty && failedDiscountDetails.isNotEmpty) {
        // Detail berhasil, tetapi diskon sebagian masih gagal
        sw.stop();
        AppTelemetry.error(
          'checkout_retry_discount_partial_failure',
          data: {
            'duration_ms': sw.elapsedMilliseconds,
            'failed_discount_details': failedDiscountDetails.length,
          },
          tag: 'CheckoutFlow',
        );
        state = state.copyWith(
          isSubmitting: false,
          // retryDiscountDetails sudah diset ke failedDiscountDetails di atas
          submitError:
              '${failedDiscountDetails.length} item masih gagal dicatat diskonnya. '
              'Coba lagi nanti.',
        );
      } else {
        state = state.copyWith(
          isSubmitting: false,
          retryDetails: stillFailed,
          submitError:
              '${stillFailed.length} item masih gagal. Coba lagi nanti.',
        );
        sw.stop();
        AppTelemetry.error(
          'checkout_retry_partial_failure',
          data: {
            'duration_ms': sw.elapsedMilliseconds,
            'failed_details': stillFailed.length,
          },
          tag: 'CheckoutFlow',
        );
      }
    } on CheckoutStepException catch (e, st) {
      Log.error(e, st, reason: 'CheckoutNotifier.retryFailedDetails');
      sw.stop();
      AppTelemetry.error(
        'checkout_retry_exception',
        data: {
          'duration_ms': sw.elapsedMilliseconds,
          'step': e.step,
          'error_type': e.runtimeType.toString(),
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

  /// Fetches the full order from the server and sends a push notification
  /// to the first pending approver. Fire-and-forget; errors are logged only.
  Future<void> _notifyFirstApprover({
    required int orderLetterId,
    required String noSp,
    required String token,
    required int userId,
    required String senderName,
  }) async {
    try {
      final orderData =
          await _orderService.fetchFullOrder(orderLetterId, token);
      if (orderData == null) return;

      await ApprovalDecisionService.triggerNextApprovalNotification(
        orderData: orderData,
        spNumber: noSp,
        token: token,
        senderName: senderName,
        currentUserId: userId,
      );
    } catch (e, st) {
      Log.error(e, st, reason: 'Checkout: notify first approver');
    }
  }

  // ── Edit Order Items ──────────────────────────────────────────

  /// Submit "Edit Items": hapus detail lama → post detail baru → patch totals.
  ///
  /// Berbeda dengan [submitOrder]:
  ///   - Skip create order_letter (gunakan [editOrder.id] yang sudah ada)
  ///   - Skip post contacts & payments (sudah ada, tidak berubah)
  ///   - Sebelum post detail baru, hapus semua detail + discount lama
  ///   - Setelah selesai, patch extended_amount + harga_awal di order_letters
  Future<void> submitEditOrder({
    required OrderHistory editOrder,
    required List<CartItem> cartItems,
    required bool Function(int itemIndex) lineIsTakeAway,
    required bool Function(int itemIndex, CartBonusSnapshot)
        isBonusTakeAwayChecked,
    required int Function(int itemIndex, CartBonusSnapshot) currentTakeAwayQty,

    /// Opsional — bukti pembayaran tambahan untuk menutup selisih (shortage).
    /// Index [i] di [shortagePaymentPayloads] berpasangan dengan [shortageReceiptImages[i]].
    List<Map<String, dynamic>> shortagePaymentPayloads = const [],
    List<File?> shortageReceiptImages = const [],

    /// Indirect auto-approve: false → null-kan selectedSpv/selectedManager
    /// agar tidak membuat baris approval pending (mirror [submitOrder]).
    bool requiresApproval = true,
    // Flag granular untuk guard [_assertApprovalNotSilentlyDropped] — lihat
    // dokumentasi di [submitOrder]. Default false = tidak ada assertion baru
    // untuk caller/test yang belum mengirim flag ini.
    bool requiresSpvApproval = false,
    bool requiresManagerApproval = false,
  }) async {
    if (state.isSubmitting) return;
    state = state.copyWith(
      isSubmitting: true,
      submitError: null,
      submitSuccess: false,
      successNoSp: null,
    );

    final sw = Stopwatch()..start();
    try {
      _assertApprovalNotSilentlyDropped(
        requiresSpvApproval: requiresSpvApproval,
        requiresManagerApproval: requiresManagerApproval,
      );

      final token = await StorageService.loadAccessToken();
      final int userId = await StorageService.loadUserId();

      final rawLookup = await _ref.read(itemLookupProvider.future);
      final lookupByItemNum = <String, ItemLookup>{};
      for (final list in rawLookup.values) {
        for (final entry in list) {
          if (entry.itemNum.isNotEmpty) lookupByItemNum[entry.itemNum] = entry;
        }
      }

      final leaderData = await _orderService.fetchLeaderByUser(userId, token);
      final profile = _ref.read(profileProvider).valueOrNull;

      final pendingDetails = _orderService.buildPendingDetails(
        cartItems: cartItems,
        userId: userId,
        leaderData: leaderData,
        lookupByItemNum: lookupByItemNum,
        selectedSpv: requiresApproval ? state.selectedSpv : null,
        selectedManager: requiresApproval ? state.selectedManager : null,
        lineIsTakeAway: lineIsTakeAway,
        isBonusTakeAwayChecked: isBonusTakeAwayChecked,
        currentTakeAwayQty: currentTakeAwayQty,
        profileName: profile?.name ?? 'User',
      );

      final orderLetterId = editOrder.id;
      final noSp = editOrder.noSp;

      state = state.copyWith(retryOrderId: orderLetterId, retryNoSp: noSp);

      // Snapshot jumlah payment sebelum edit — untuk skip shortage yang sudah
      // ter-POST jika user retry setelah error di step berikutnya.
      final paymentCountBeforeEdit = shortagePaymentPayloads.isNotEmpty
          ? await _orderService.fetchExistingPaymentCount(orderLetterId, token)
          : 0;

      // ── Step 0: Hapus detail + discount lama ──
      final editService = EditDetailsService();
      await editService.deleteAll(editOrder, token);

      // ── Step 1: Post detail baru ──
      final detailResult = await _orderService.postDetails(
        pendingDetails,
        orderLetterId,
        token,
        noSp: noSp,
      );

      // ── Step 2: Post discount baru ──
      if (detailResult.succeeded.isNotEmpty) {
        final needsFallback =
            detailResult.succeeded.any((s) => s.detailId <= 0);
        final fallbackIds = needsFallback
            ? await _orderService.fetchDetailIds(orderLetterId, token)
            : <int>[];

        final failedDiscounts = await _orderService.postDiscountsForDetails(
          succeededDetails: detailResult.succeeded,
          orderLetterId: orderLetterId,
          token: token,
          fallbackDetailIds: fallbackIds,
        );
        if (failedDiscounts.isNotEmpty) {
          Log.warning(
            'EditItems: ${failedDiscounts.length} detail gagal catat diskon',
            tag: 'CheckoutNotifier',
          );
        }
      }

      // ── Step 3: Patch totals (extended_amount, harga_awal) ──
      double grandTotal = 0;
      double hargaAwal = 0;
      for (final s in detailResult.succeeded) {
        final netPrice =
            (s.pending.payload['net_price'] as num?)?.toDouble() ?? 0;
        final custPrice =
            (s.pending.payload['customer_price'] as num?)?.toDouble() ?? 0;
        final qty = (s.pending.payload['qty'] as num?)?.toInt() ?? 1;
        grandTotal += netPrice * qty;
        hargaAwal += custPrice * qty;
      }
      final extendedAmount = grandTotal + editOrder.postage;

      // Jika semua discount rows sudah auto-approved (tidak ada yang null),
      // tidak ada chain approval yang perlu ditunggu — set status langsung Approved.
      final hasAnyPendingApproval = pendingDetails.any(
        (pd) => pd.discounts.any((d) => d['approved'] == null),
      );
      final orderStatus = hasAnyPendingApproval ? 'Pending' : 'Approved';

      await editService.patchOrderTotals(
        orderId: orderLetterId,
        extendedAmount: extendedAmount,
        hargaAwal: hargaAwal,
        token: token,
        status: orderStatus,
      );

      // ── Step 4: Post payment baru (untuk menutup selisih kekurangan) ──
      if (shortagePaymentPayloads.isNotEmpty) {
        final currentCount = await _orderService.fetchExistingPaymentCount(
          orderLetterId,
          token,
        );
        final alreadyPosted = (currentCount - paymentCountBeforeEdit)
            .clamp(0, shortagePaymentPayloads.length);
        if (alreadyPosted > 0) {
          Log.info(
            'EditItems: skip $alreadyPosted shortage payment(s) — sudah di server',
            tag: 'CheckoutNotifier',
          );
        }
        for (var i = alreadyPosted; i < shortagePaymentPayloads.length; i++) {
          await _orderService.postPayment(
            paymentPayload: shortagePaymentPayloads[i],
            orderLetterId: orderLetterId,
            receiptImage: i < shortageReceiptImages.length
                ? shortageReceiptImages[i]
                : null,
            token: token,
          );
        }
        Log.info(
          'EditItems: ${shortagePaymentPayloads.length - alreadyPosted} '
          'shortage payment(s) posted',
          tag: 'CheckoutNotifier',
        );
      }

      // editOrderContextProvider dibersihkan oleh CheckoutPage listener
      // setelah membaca editCtx untuk menentukan feedback & navigasi.

      // ── Clear cart & invalidate providers ──
      await _ref.read(cartProvider.notifier).clearCart();
      _ref.invalidate(orderHistoryProvider);
      _ref.invalidate(orderDetailProvider(orderLetterId));
      unawaited(_ref.read(approvalInboxProvider.notifier).fetchInbox(force: true));

      sw.stop();
      AppTelemetry.event(
        'edit_items_success',
        data: {
          'duration_ms': sw.elapsedMilliseconds,
          'order_id': orderLetterId,
          'details': detailResult.succeeded.length,
        },
        tag: 'EditItems',
      );

      if (detailResult.failed.isEmpty) {
        state = state.copyWith(
          isSubmitting: false,
          retryDetails: const [],
          retryOrderId: null,
          retryNoSp: '',
          retryContactStartIndex: 0,
          retryPaymentStartIndex: 0,
          submitSuccess: true,
          successNoSp: noSp,
        );
      } else {
        state = state.copyWith(
          isSubmitting: false,
          retryDetails: detailResult.failed,
          submitError:
              'SP $noSp berhasil diperbarui, tetapi ${detailResult.failed.length} '
              'item berikut gagal tersimpan:\n\n'
              '${detailResult.failed.map((e) => '• ${e.label}').join('\n')}',
        );
      }
    } on CheckoutStepException catch (e, st) {
      sw.stop();
      Log.error(e, st, reason: 'CheckoutNotifier.submitEditOrder');
      AppTelemetry.error(
        'edit_items_exception',
        data: {'step': e.step, 'step_name': e.stepName},
        tag: 'EditItems',
      );
      state = state.copyWith(
        isSubmitting: false,
        submitError: 'Gagal di ${e.stepName}.\n\n$e',
      );
    } catch (e, st) {
      sw.stop();
      if (isNetworkError(e)) {
        Log.warning('submitEditOrder (network): $e', tag: 'EditItems');
      } else {
        Log.error(e, st, reason: 'CheckoutNotifier.submitEditOrder');
      }
      AppTelemetry.error(
        'edit_items_exception',
        data: {'error_type': e.runtimeType.toString()},
        tag: 'EditItems',
      );
      state = state.copyWith(
        isSubmitting: false,
        submitError: 'Terjadi kesalahan saat menyimpan perubahan.\n\nDetail:\n$e',
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
    StateNotifierProvider<CheckoutNotifier, CheckoutState>(
  (ref) => CheckoutNotifier(ref),
);
