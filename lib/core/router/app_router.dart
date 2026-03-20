import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/platform_utils.dart';
import '../utils/telemetry_access.dart';
import '../../features/auth/logic/auth_provider.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/pricelist/data/models/product.dart';
import '../../features/pricelist/presentation/pages/product_list_page.dart';
import '../../features/pricelist/presentation/pages/product_detail_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/cart/data/cart_item.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/checkout/presentation/pages/order_success_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/help_center_page.dart';
import '../../features/profile/presentation/pages/telemetry_debug_page.dart';
import '../../features/history/presentation/pages/order_history_page.dart';
import '../../features/history/presentation/pages/order_detail_page.dart';
import '../../features/history/data/models/order_history.dart';
import '../../features/approval/presentation/pages/approval_inbox_page.dart';
import '../../features/approval/presentation/pages/approval_detail_page.dart';
import '../../features/quotation/data/quotation_model.dart';
import '../../features/quotation/presentation/pages/quotation_history_page.dart';

/// Returns [CupertinoPage] on iOS for native swipe-back,
/// [MaterialPage] on Android for Material transitions.
Page<T> _adaptivePage<T>({required Widget child, required String name}) {
  if (isIOS) return CupertinoPage<T>(child: child, name: name);
  return MaterialPage<T>(child: child, name: name);
}

/// GoRouter provider — router dibuat SEKALI, tidak ikut rebuild saat auth berubah.
/// Redirect dibaca via ref.read di dalam callback agar tidak trigger rebuild router.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      // ref.read — hanya baca state saat redirect dipanggil, tidak subscribe
      final auth = ref.read(authProvider);
      final isLoading = auth.isLoading;
      final isLoggedIn = auth.isLoggedIn;
      final isOnLogin = state.matchedLocation == '/login';
      final isTelemetryRoute = state.matchedLocation == '/telemetry_debug';

      // Selagi auth masih load dari storage, jangan redirect dulu
      if (isLoading) return null;

      // Belum login → paksa ke login
      if (!isLoggedIn && !isOnLogin) return '/login';

      // Sudah login tapi masih di halaman login → ke home
      if (isLoggedIn && isOnLogin) return '/';

      if (isTelemetryRoute && !TelemetryAccess.canAccess(auth)) {
        return '/profile';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            _adaptivePage(child: const LoginPage(), name: 'login'),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) =>
            _adaptivePage(child: const ProductListPage(), name: 'home'),
      ),
      GoRoute(
        path: '/product/:id',
        name: 'product-detail',
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra is Product) {
            return _adaptivePage(
              child: ProductDetailPage(product: extra),
              name: 'product-detail',
            );
          }
          final map = extra as Map<String, dynamic>;
          return _adaptivePage(
            child: ProductDetailPage(
              product: map['product'] as Product,
              editItem: map['editItem'] as CartItem?,
              cartIndex: map['cartIndex'] as int?,
            ),
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
        pageBuilder: (context, state) => _adaptivePage(
            child: const OrderSuccessPage(), name: 'order-success'),
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
          final order = state.extra as OrderHistory;
          return _adaptivePage(
            child: OrderDetailPage(order: order),
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
          final orderData = state.extra as Map<String, dynamic>;
          return _adaptivePage(
            child: ApprovalDetailPage(orderData: orderData),
            name: 'approval-detail',
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
