import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upgrader/upgrader.dart';
import '../utils/app_feedback.dart';
import '../utils/approver_access.dart';
import '../utils/log.dart';
import '../utils/platform_utils.dart';
import '../utils/telemetry_access.dart';
import '../theme/app_colors.dart';
import '../widgets/error_state_view.dart';
import '../../features/auth/logic/auth_provider.dart';
import '../../features/auth/presentation/pages/auth_boot_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/pricelist/data/models/product.dart';
import '../../features/pricelist/presentation/pages/product_list_page.dart';
import '../../features/pricelist/presentation/pages/pricelist_custom_line_page.dart';
import '../../features/pricelist/presentation/pricelist_custom_line_route_args.dart';
import '../../features/pricelist/presentation/pages/product_detail_page.dart';
import '../../features/pricelist/presentation/product_detail_route_args.dart';
import '../../features/pricelist/presentation/pages/product_detail_from_link_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/cart/data/cart_item.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/checkout/presentation/pages/order_success_page.dart';
import '../../features/checkout/presentation/order_success_route_args.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/help_center_page.dart';
import '../../features/profile/presentation/pages/telemetry_debug_page.dart';
import '../../features/history/presentation/pages/order_history_page.dart';
import '../../features/history/presentation/pages/order_detail_page.dart';
import '../../features/history/presentation/order_detail_route_args.dart';
import '../../features/history/data/models/order_history.dart';
import '../../features/approval/presentation/pages/approval_inbox_page.dart';
import '../../features/approval/presentation/pages/approval_detail_page.dart';
import '../../features/approval/presentation/pages/approval_detail_loader_page.dart';
import '../../features/approval/presentation/approval_detail_route_args.dart';
import '../../features/quotation/data/quotation_model.dart';
import '../../features/quotation/presentation/pages/quotation_history_page.dart';
import '../../features/indirect/presentation/pages/sales_hub_page.dart';
import 'android_system_back.dart';

/// Android: gesture / tombol sistem harus memakai [GoRouter.pop], bukan hanya
/// [Navigator.maybePop], supaya tidak menutup activity saat masih ada route di stack
/// GoRouter (umum terjadi dengan [ShellRoute] + [rootNavigatorKey]).
bool get _useAndroidGoRouterBackScope =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Returns [CupertinoPage] on iOS for native swipe-back,
/// [MaterialPage] on Android for Material transitions.
Page<T> _adaptivePage<T>({required Widget child, required String name}) {
  final wrapped = _useAndroidGoRouterBackScope
      ? _AndroidGoRouterBackScope(child: child)
      : child;
  if (isIOS) return CupertinoPage<T>(child: wrapped, name: name);
  return MaterialPage<T>(child: wrapped, name: name);
}

/// Satu [PopScope] per halaman (via [_adaptivePage]): back sistem dialihkan ke GoRouter.
/// Halaman yang punya [GoRouterPopScope] batin (checkout, approval) tetap menang lebih dulu.
///
/// Root (`/` / `/sales_hub`): **double-back** untuk keluar — tidak langsung
/// [SystemNavigator.pop]. Admin di `/` tanpa stack → `/sales_hub`.
class _AndroidGoRouterBackScope extends StatefulWidget {
  const _AndroidGoRouterBackScope({required this.child});

  final Widget child;

  @override
  State<_AndroidGoRouterBackScope> createState() =>
      _AndroidGoRouterBackScopeState();
}

class _AndroidGoRouterBackScopeState extends State<_AndroidGoRouterBackScope> {
  DateTime? _lastExitPromptAt;
  static const _exitConfirmWindow = Duration(seconds: 2);

  bool get _exitPromptActive {
    final last = _lastExitPromptAt;
    if (last == null) return false;
    return DateTime.now().difference(last) <= _exitConfirmWindow;
  }

  void _handleSystemBack() {
    final router = GoRouter.of(context);
    final loc = router.state.matchedLocation;

    var canChooseSalesMode = false;
    try {
      final auth = ProviderScope.containerOf(context).read(authProvider);
      canChooseSalesMode = TelemetryAccess.canChooseSalesMode(auth.userId);
    } catch (e, s) {
      Log.warning(
        'Android back: gagal baca auth untuk sales-mode ($e)',
      );
      Log.error(e, s, reason: 'AndroidGoRouterBackScope.auth');
    }

    final decision = resolveAndroidSystemBack(
      routerCanPop: router.canPop(),
      matchedLocation: loc,
      canChooseSalesMode: canChooseSalesMode,
      exitPromptActive: _exitPromptActive,
    );

    switch (decision) {
      case AndroidSystemBackDecision.popRouter:
        router.pop();
      case AndroidSystemBackDecision.goSalesHub:
        router.go('/sales_hub');
      case AndroidSystemBackDecision.goHome:
        router.go('/');
      case AndroidSystemBackDecision.confirmExit:
        setState(() => _lastExitPromptAt = DateTime.now());
        if (!mounted) return;
        AppFeedback.show(
          context,
          message: 'Tekan sekali lagi untuk keluar',
          type: AppFeedbackType.info,
          floating: true,
          duration: _exitConfirmWindow,
        );
      case AndroidSystemBackDecision.exitApp:
        SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: widget.child,
    );
  }
}

/// [GoRouter] `extra` untuk `/order_detail`: [OrderDetailRouteArgs], [OrderHistory],
/// atau [Map] API — hindari cast keras.
OrderHistory? _orderHistoryFromRouteExtra(Object? extra) {
  if (extra == null) return null;
  if (extra is OrderHistory) return extra;
  if (extra is Map) {
    final map = Map<String, dynamic>.from(extra);
    try {
      return OrderHistory.fromApiJson(map);
    } catch (_) {
      try {
        return OrderHistory.fromJson(map);
      } catch (e, st) {
        Log.error(e, st,
            reason: 'order_detail route extra (Map → OrderHistory)');
        return null;
      }
    }
  }
  return null;
}

OrderDetailRouteArgs? _orderDetailRouteArgsFromExtra(Object? extra) {
  if (extra == null) return null;
  if (extra is OrderDetailRouteArgs) return extra;
  final oh = _orderHistoryFromRouteExtra(extra);
  if (oh == null) return null;
  return OrderDetailRouteArgs(order: oh);
}

/// [GoRouter] `extra` untuk `/approval_detail`: [ApprovalDetailRouteArgs] atau [Map].
ApprovalDetailRouteArgs? _approvalDetailRouteArgsFromExtra(Object? extra) {
  if (extra == null) return null;
  if (extra is ApprovalDetailRouteArgs) return extra;
  if (extra is Map) {
    return ApprovalDetailRouteArgs(
      orderData: Map<String, dynamic>.from(extra),
    );
  }
  return null;
}

/// Allowlist untuk path yang boleh dinavigasi lewat deep link eksternal
/// (App Links/Universal Links, mis. dari `uriLinkStream` di `main.dart`).
///
/// HARUS sinkron dengan `pathPrefix`/`path` yang di-declare sebagai
/// associated domain terverifikasi di `AndroidManifest.xml`
/// (`android:pathPrefix="/product"`) dan `Runner.entitlements`
/// (`applinks:alita-pricelist-12d76.web.app`). Path lain ditolak agar link
/// eksternal (mis. tersisip di pesan/QR pihak ketiga) tidak bisa memaksa
/// navigasi ke route internal sembarang (mis. `/checkout`, `/approval_detail`)
/// yang mengharapkan `extra` typed dan bisa crash tanpanya.
const _deepLinkAllowedPrefixes = ['/product/'];

bool isAllowedDeepLinkPath(String path) {
  return _deepLinkAllowedPrefixes.any(path.startsWith);
}

/// Root navigator key used by GoRouter.
final rootNavigatorKey = GlobalKey<NavigatorState>();

// ── Auto-update (UpgradeAlert) — hanya Android ─────────────────
// Android: Play Store via [UpgraderPlayStore] + [ForceUpdateService].
// iOS: TIDAK menggunakan [UpgradeAlert] di sini. [upgrader] di iOS menyimpan
//      cache versi dan menampilkan dialog sekalipun app sudah diperbarui.
//      Sebagai gantinya, [IosUpdateChecker] di main.dart melakukan pengecekan
//      langsung ke iTunes API dan membandingkan versi secara numerik.
//
// Debug: selalu lewati [UpgradeAlert] agar dev tidak terblokir.
final _upgrader = Upgrader(
  debugLogging: false,
  countryCode: 'id',
  languageCode: 'id',
  durationUntilAlertAgain: Duration.zero,
  messages: _AlitaUpgraderMessages(),
  storeController: UpgraderStoreController(
    onAndroid: () => UpgraderPlayStore(),
  ),
);

/// Override initial location when app opens from deep link.
/// Set via [ProviderScope.overrides] in main() when [AppLinks] returns initial URI.
final initialLocationFromDeepLinkProvider = Provider<String?>((ref) => null);

/// GoRouter provider — router dibuat SEKALI, tidak ikut rebuild saat auth berubah.
/// Redirect dibaca via ref.read di dalam callback agar tidak trigger rebuild router.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);
  ref.onDispose(notifier.dispose);
  final deepLinkPath = ref.watch(initialLocationFromDeepLinkProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    // Default boot, bukan `/`: selama auth [isLoading], home tidak boleh tampil
    // (menghindari kilas product list → login setelah hot restart).
    initialLocation: deepLinkPath ?? '/auth_boot',
    refreshListenable: notifier,
    redirect: (context, state) {
      // ref.read — hanya baca state saat redirect dipanggil, tidak subscribe
      final auth = ref.read(authProvider);
      final isLoading = auth.isLoading;
      final isLoggedIn = auth.isLoggedIn;
      final isOnLogin = state.matchedLocation == '/login';
      final isOnAuthBoot = state.matchedLocation == '/auth_boot';
      final isTelemetryRoute = state.matchedLocation == '/telemetry_debug';

      // Auth belum selesai baca storage: tahan di boot/login, jangan biarkan shell `/`.
      if (isLoading) {
        if (isOnLogin || isOnAuthBoot) return null;
        return '/auth_boot';
      }

      // Session sudah jelas: boot memutuskan sales hub (admin) vs home (non-admin).
      if (isLoggedIn && isOnAuthBoot) return null;
      if (!isLoggedIn && isOnAuthBoot) return '/login';

      // Belum login → paksa ke login
      if (!isLoggedIn && !isOnLogin) return '/login';

      // Sudah login di login: admin ke hub; non-admin tetap di login sampai LoginPage selesai sync mode.
      if (isLoggedIn && isOnLogin) {
        if (TelemetryAccess.canChooseSalesMode(auth.userId)) {
          return '/sales_hub';
        }
        return null;
      }

      if (isTelemetryRoute && !TelemetryAccess.canAccess(auth.userId)) {
        return '/profile';
      }

      // Role-guard: blokir hanya kalau kita SUDAH TAHU (cache work title
      // terisi) user ini bukan approver — fail-open kalau belum tahu supaya
      // approver asli tidak ke-block sebelum profil sempat termuat. Backend
      // (order_letter_approvals + approver_id match) tetap jadi penjaga utama.
      final isApprovalRoute = state.matchedLocation.startsWith('/approval');
      if (isApprovalRoute &&
          ApproverAccess.hasCachedTitle &&
          !ApproverAccess.isApproverCached) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth_boot',
        name: 'auth-boot',
        pageBuilder: (context, state) =>
            _adaptivePage(child: const AuthBootPage(), name: 'auth-boot'),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            _adaptivePage(child: const LoginPage(), name: 'login'),
      ),

      // ShellRoute: UpgradeAlert hanya Android (release/profile).
      // iOS: dikecualikan — update handling ditangani [IosUpdateChecker].
      ShellRoute(
        builder: (context, state, child) {
          if (kDebugMode || isIOS) {
            return child;
          }
          return UpgradeAlert(
            navigatorKey: rootNavigatorKey,
            upgrader: _upgrader,
            dialogStyle: UpgradeDialogStyle.material,
            showIgnore: false,
            showLater: false,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/sales_hub',
            name: 'sales-hub',
            pageBuilder: (context, state) =>
                _adaptivePage(child: const SalesHubPage(), name: 'sales-hub'),
          ),
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) =>
                _adaptivePage(child: const ProductListPage(), name: 'home'),
          ),
          GoRoute(
            path: '/pricelist/custom_line',
            name: 'pricelist-custom-line',
            pageBuilder: (context, state) {
              final extra = state.extra;
              final args = extra is PricelistCustomLineRouteArgs
                  ? extra
                  : const PricelistCustomLineRouteArgs();
              return _adaptivePage(
                child: PricelistCustomLinePage(
                  editItem: args.editItem,
                  cartIndex: args.cartIndex,
                ),
                name: 'pricelist-custom-line',
              );
            },
          ),
          GoRoute(
            path: '/product/:id',
            name: 'product-detail',
            pageBuilder: (context, state) {
              final extra = state.extra;
              final id = state.pathParameters['id'] ?? '';

              if (extra is Product) {
                return _adaptivePage(
                  child: ProductDetailPage(product: extra),
                  name: 'product-detail',
                );
              }
              if (extra is ProductDetailRouteArgs) {
                return _adaptivePage(
                  child: ProductDetailPage(
                    product: extra.product,
                    editItem: extra.editItem,
                    cartIndex: extra.cartIndex,
                  ),
                  name: 'product-detail',
                );
              }
              // Deep link: hanya punya product id
              return _adaptivePage(
                child: ProductDetailFromLinkPage(productId: id),
                name: 'product-detail',
              );
            },
          ),
          GoRoute(
            path: '/favorites',
            name: 'favorites',
            pageBuilder: (context, state) =>
                _adaptivePage(child: const FavoritesPage(), name: 'favorites'),
          ),
          GoRoute(
            path: '/checkout',
            name: 'checkout',
            pageBuilder: (context, state) {
              final extra = state.extra;
              List<CartItem>? selectedItems;
              QuotationModel? restoredQuotation;

              if (extra is QuotationModel) {
                restoredQuotation = extra;
                selectedItems = List.of(extra.items);
              } else if (extra is List<CartItem>) {
                selectedItems = extra;
              }

              return _adaptivePage(
                child: CheckoutPage(
                  selectedCartItems: selectedItems,
                  restoredQuotation: restoredQuotation,
                ),
                name: 'checkout',
              );
            },
          ),
          GoRoute(
            path: '/success',
            name: 'order-success',
            pageBuilder: (context, state) {
              final extra = state.extra;
              final args = extra is OrderSuccessRouteArgs ? extra : null;
              return _adaptivePage(
                child: OrderSuccessPage(args: args),
                name: 'order-success',
              );
            },
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) =>
                _adaptivePage(child: const ProfilePage(), name: 'profile'),
          ),
          GoRoute(
            path: '/help_center',
            name: 'help-center',
            pageBuilder: (context, state) => _adaptivePage(
              child: const HelpCenterPage(),
              name: 'help-center',
            ),
          ),
          GoRoute(
            path: '/telemetry_debug',
            name: 'telemetry-debug',
            pageBuilder: (context, state) => _adaptivePage(
              child: const TelemetryDebugPage(),
              name: 'telemetry-debug',
            ),
          ),
          GoRoute(
            path: '/order_history',
            name: 'order-history',
            pageBuilder: (context, state) => _adaptivePage(
              child: const OrderHistoryPage(),
              name: 'order-history',
            ),
          ),
          GoRoute(
            path: '/order_detail',
            name: 'order-detail',
            pageBuilder: (context, state) {
              final args = _orderDetailRouteArgsFromExtra(state.extra);
              if (args == null) {
                return _adaptivePage(
                  name: 'order-detail',
                  child: Scaffold(
                    backgroundColor: AppColors.background,
                    appBar: AppBar(
                      title: const Text(
                        'Detail Pesanan',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: AppColors.background,
                      elevation: 0,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    body: ErrorStateView(
                      title: 'Tidak bisa membuka detail',
                      message:
                          'Data pesanan tidak valid atau formatnya berbeda. '
                          'Buka lagi dari Riwayat Pesanan.',
                      onRetry: () => GoRouter.of(context).go('/order_history'),
                      retryLabel: 'Ke riwayat pesanan',
                    ),
                  ),
                );
              }
              return _adaptivePage(
                child: OrderDetailPage(
                  order: args.order,
                  allowVoidFromApprovalContext:
                      args.allowVoidFromApprovalContext,
                ),
                name: 'order-detail',
              );
            },
          ),
          GoRoute(
            path: '/approval_inbox',
            name: 'approval-inbox',
            pageBuilder: (context, state) => _adaptivePage(
                child: const ApprovalInboxPage(), name: 'approval-inbox'),
          ),
          GoRoute(
            path: '/approval_detail',
            name: 'approval-detail',
            pageBuilder: (context, state) {
              final args = _approvalDetailRouteArgsFromExtra(state.extra);
              if (args == null) {
                return _adaptivePage(
                  name: 'approval-detail',
                  child: Scaffold(
                    backgroundColor: AppColors.background,
                    appBar: AppBar(
                      title: const Text(
                        'Persetujuan Diskon',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: AppColors.background,
                      elevation: 0,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    body: ErrorStateView(
                      title: 'Tidak bisa membuka persetujuan',
                      message:
                          'Data persetujuan tidak valid atau formatnya berbeda. '
                          'Buka lagi dari Inbox Persetujuan.',
                      onRetry: () => GoRouter.of(context).go('/approval_inbox'),
                      retryLabel: 'Ke inbox persetujuan',
                    ),
                  ),
                );
              }
              return _adaptivePage(
                child: ApprovalDetailPage(orderData: args.orderData),
                name: 'approval-detail',
              );
            },
          ),
          GoRoute(
            path: '/approval_from_order/:orderId',
            name: 'approval-from-order',
            pageBuilder: (context, state) {
              final idStr = state.pathParameters['orderId'] ?? '';
              final orderId = int.tryParse(idStr) ?? 0;
              return _adaptivePage(
                child: ApprovalDetailLoaderPage(orderId: orderId),
                name: 'approval-from-order',
              );
            },
          ),
          GoRoute(
            path: '/quotation_history',
            name: 'quotation-history',
            pageBuilder: (context, state) {
              final autoPdf = state.extra as QuotationModel?;
              return _adaptivePage(
                child: QuotationHistoryPage(autoPdfQuotation: autoPdf),
                name: 'quotation-history',
              );
            },
          ),
        ],
      ),
    ],
  );
});

/// Notifier that listens to Riverpod's auth state and notifies GoRouter.
/// PENTING: hanya notify saat isLoggedIn benar-benar berubah —
/// bukan saat isLoading toggle — agar GoRouter tidak rebuild LoginPage
/// di tengah proses login dan membatalkan SnackBar/Toast yang sedang tampil.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      // Notify saat login/logout (isLoggedIn berubah)
      final loginChanged = previous?.isLoggedIn != next.isLoggedIn;
      // Notify saat auth check selesai (isLoading: true → false),
      // agar router bisa re-evaluasi redirect dan arahkan ke /login jika belum login.
      final loadingFinished = (previous?.isLoading ?? false) && !next.isLoading;

      if (loginChanged || loadingFinished) {
        notifyListeners();
      }
    });
  }

  final Ref _ref;
}

class _AlitaUpgraderMessages extends UpgraderMessages {
  _AlitaUpgraderMessages() : super(code: 'id');

  @override
  String get title => 'Pembaruan Tersedia';

  @override
  String get body => 'Versi baru aplikasi {{appName}} telah tersedia.\n'
      'Anda wajib memperbarui aplikasi untuk melanjutkan dan memastikan '
      'perhitungan harga akurat.\n\n'
      'Versi terpasang: {{currentInstalledVersion}}\n'
      'Versi terbaru: {{currentAppStoreVersion}}';

  @override
  String get prompt => 'Silakan perbarui aplikasi sekarang untuk melanjutkan.';

  @override
  String get buttonTitleUpdate => 'Perbarui Sekarang';
}
