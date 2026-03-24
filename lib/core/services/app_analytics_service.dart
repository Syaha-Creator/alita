import 'package:firebase_analytics/firebase_analytics.dart';

/// Thin wrapper around Firebase Analytics for product/usage insights.
///
/// All methods silently no-op when Firebase has not been initialized,
/// so callers never need to check readiness themselves.
class AppAnalyticsService {
  AppAnalyticsService._();

  static bool _ready = false;

  /// Call once after Firebase.initializeApp() succeeds.
  static void enable() => _ready = true;

  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_ready) return;
    await FirebaseAnalytics.instance.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_ready) return;
    await FirebaseAnalytics.instance
        .logEvent(name: name, parameters: parameters);
  }

  static Future<void> logViewItem(String itemId, String itemName) =>
      logEvent(
        name: 'view_item',
        parameters: {'item_id': itemId, 'item_name': itemName},
      );

  static Future<void> logAddToCart(String itemId, String itemName) =>
      logEvent(
        name: 'add_to_cart',
        parameters: {'item_id': itemId, 'item_name': itemName},
      );

  static Future<void> logBeginCheckout({double? value}) => logEvent(
        name: 'begin_checkout',
        parameters: value != null ? {'value': value} : null,
      );
}
