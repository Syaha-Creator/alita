/// Constants for API and network timeouts
class ApiTimeouts {
  ApiTimeouts._();

  /// Standard timeout for API connections (30 seconds)
  /// Used for most API calls that should complete quickly
  static const Duration standardConnectTimeout = Duration(seconds: 30);

  /// Standard timeout for receiving API responses (30 seconds)
  static const Duration standardReceiveTimeout = Duration(seconds: 30);

  /// Extended timeout for API connections (60 seconds)
  /// Used for longer operations like file uploads or complex queries
  static const Duration extendedConnectTimeout = Duration(seconds: 60);

  /// Extended timeout for receiving API responses (60 seconds)
  static const Duration extendedReceiveTimeout = Duration(seconds: 60);

  /// Extended timeout for sending API requests (60 seconds)
  static const Duration extendedSendTimeout = Duration(seconds: 60);

  /// Short timeout for quick operations (5 seconds)
  /// Used for update checks and lightweight operations
  static const Duration shortTimeout = Duration(seconds: 5);

  /// Medium timeout for moderate operations (10 seconds)
  /// Used for token registration and similar operations
  static const Duration mediumTimeout = Duration(seconds: 10);
}

/// Constants for cache durations
class CacheDurations {
  CacheDurations._();

  /// Cache duration for approval data (5 minutes)
  static const Duration approvalCache = Duration(minutes: 5);

  /// Cache duration for discount data (10 minutes)
  static const Duration discountCache = Duration(minutes: 10);

  /// Cache duration for user info (1 hour)
  static const Duration userInfoCache = Duration(hours: 1);
}

/// Constants for retry and delay durations
class RetryDurations {
  RetryDurations._();

  /// Delay between retry attempts (2 seconds)
  static const Duration retryDelay = Duration(seconds: 2);

  /// Background sync interval (3 minutes)
  static const Duration backgroundSyncInterval = Duration(minutes: 3);

  /// UI refresh delay (2 seconds)
  static const Duration uiRefreshDelay = Duration(seconds: 2);

  /// Short delay for UI operations (30 seconds)
  static const Duration shortUiDelay = Duration(seconds: 30);

  /// Cache staleness threshold (2 minutes)
  /// Used to determine if cached data is too old
  static const Duration cacheStalenessThreshold = Duration(minutes: 2);
}

/// Constants for pagination
class PaginationConstants {
  PaginationConstants._();

  /// Number of items per page
  static const int itemsPerPage = 20;

  /// Threshold for lazy loading (load more when this many items remain)
  static const int lazyLoadThreshold = 50;
}
