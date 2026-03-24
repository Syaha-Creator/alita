import 'package:firebase_analytics/firebase_analytics.dart';

/// Thin wrapper around Firebase Analytics for product/usage insights.
///
/// Use this service to log screen views and custom events (e.g. add_to_cart,
/// begin_checkout). Firebase Console filters debug vs release by default.
class AppAnalyticsService {
  AppAnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Log a screen view. Call when entering a significant screen.
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) =>
      _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );

  /// Log a custom event with optional parameters.
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) =>
      _analytics.logEvent(name: name, parameters: parameters);

  /// Predefined: user viewed a product detail.
  static Future<void> logViewItem(String itemId, String itemName) =>
      logEvent(
        name: 'view_item',
        parameters: {'item_id': itemId, 'item_name': itemName},
      );

  /// Predefined: user added item to cart.
  static Future<void> logAddToCart(String itemId, String itemName) =>
      logEvent(
        name: 'add_to_cart',
        parameters: {'item_id': itemId, 'item_name': itemName},
      );

  /// Predefined: user began checkout.
  static Future<void> logBeginCheckout({double? value}) => logEvent(
        name: 'begin_checkout',
        parameters: value != null ? {'value': value} : null,
      );
}
