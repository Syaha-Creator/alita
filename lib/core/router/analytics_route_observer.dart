import 'package:flutter/material.dart';
import '../services/app_analytics_service.dart';

/// NavigatorObserver that logs screen views to Firebase Analytics on route push.
class AnalyticsRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logRoute(route);
  }

  void _logRoute(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      AppAnalyticsService.logScreenView(
        screenName: name,
        screenClass: name,
      );
    }
  }
}
