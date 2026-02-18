import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../config/app_constant.dart';
import '../features/authentication/presentation/pages/login_page.dart';
import '../features/cart/domain/entities/cart_entity.dart';
import '../features/cart/presentation/pages/cart_page.dart';
import '../features/cart/presentation/pages/checkout_pages.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/product/domain/entities/product_entity.dart';
import '../features/product/presentation/bloc/product_bloc.dart';
import '../features/product/presentation/bloc/product_event.dart';
import '../features/product/presentation/pages/product_page.dart';
import '../features/product/presentation/pages/product_detail_page.dart';
import '../features/product_indirect/presentation/pages/product_indirect_page.dart';
import '../features/approval/presentation/pages/approval_monitoring_page.dart';
import '../features/order_letter_document/presentation/pages/order_letter_document_page.dart';

import '../services/auth_service.dart';
import 'navigation_service.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: NavigationService.navigatorKey,
    refreshListenable: AuthService.authChangeNotifier,
    initialLocation: AuthService.authChangeNotifier.value
        ? RoutePaths.home
        : RoutePaths.login,
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: RoutePaths.product,
        builder: (context, state) => const ProductPage(),
        routes: [
          GoRoute(
            // Path relatifnya adalah 'detail', jadi URL lengkapnya /product/detail
            path: 'detail',
            name: RoutePaths.productDetail,
            builder: (context, state) {
              // AMBIL DATA DARI 'extra' DAN LAKUKAN TYPE CHECK
              final product = state.extra;
              if (product is ProductEntity) {
                // Kirim event ke BLoC setelah memastikan tipenya benar
                context.read<ProductBloc>().add(SelectProduct(product));
              }
              return const ProductDetailPage();
            },
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.productIndirect,
        builder: (context, state) => const ProductIndirectPage(),
        routes: [
          GoRoute(
            // Path relatifnya adalah 'detail', jadi URL lengkapnya /product-indirect/detail
            path: 'detail',
            name: RoutePaths.productIndirectDetail,
            builder: (context, state) {
              // AMBIL DATA DARI 'extra' - bisa Map atau ProductEntity
              final extra = state.extra;
              
              ProductEntity? product;
              List<double>? storeDiscounts;
              String? storeDiscountDisplay;
              IndirectStoreInfo? storeInfo;
              
              if (extra is Map<String, dynamic>) {
                product = extra['product'] as ProductEntity?;
                storeDiscounts = (extra['storeDiscounts'] as List?)?.cast<double>();
                storeDiscountDisplay = extra['storeDiscountDisplay'] as String?;
                // Parse storeInfo if available
                final storeInfoMap = extra['storeInfo'] as Map<String, dynamic>?;
                if (storeInfoMap != null) {
                  storeInfo = IndirectStoreInfo.fromJson(storeInfoMap);
                }
              } else if (extra is ProductEntity) {
                product = extra;
              }
              
              if (product != null) {
                context.read<ProductBloc>().add(SelectProduct(product));
              }
              
              return ProductDetailPage(
                isIndirect: true,
                storeDiscounts: storeDiscounts,
                storeDiscountDisplay: storeDiscountDisplay,
                storeInfo: storeInfo,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.cart,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CartPage(),
          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: RoutePaths.checkout,
        builder: (context, state) => const CheckoutPages(),
      ),
      GoRoute(
        path: RoutePaths.approvalMonitoring,
        builder: (context, state) => const ApprovalMonitoringPage(),
      ),
      GoRoute(
        path: RoutePaths.orderLetterDocument,
        builder: (context, state) {
          final orderLetterId = state.extra as int?;
          if (orderLetterId == null) {
            // Handle error case - redirect to approval monitoring
            return const ApprovalMonitoringPage();
          }
          return OrderLetterDocumentPage(orderLetterId: orderLetterId);
        },
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = AuthService.authChangeNotifier.value;
      final isLoggingIn = state.matchedLocation == RoutePaths.login;

      if (!isLoggedIn && !isLoggingIn) {
        return RoutePaths.login;
      }

      if (isLoggedIn && isLoggingIn) {
        return RoutePaths.home;
      }

      return null;
    },
  );
}
