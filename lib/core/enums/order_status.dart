import 'package:flutter/material.dart';

/// Canonical order status enum to avoid repeated raw-string checks.
enum OrderStatus { approved, pending, rejected, unknown }

extension OrderStatusX on OrderStatus {
  /// Parses a raw string from the API into a type-safe [OrderStatus].
  /// Handles Indonesian 'ditolak', boolean-like 'true'/'false'/'1'/'0',
  /// and the standard English statuses.
  static OrderStatus fromRaw(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'approved':
      case 'true':
      case '1':
        return OrderStatus.approved;
      case 'pending':
      case '':
        return OrderStatus.pending;
      case 'rejected':
      case 'ditolak':
      case 'false':
      case '0':
        return OrderStatus.rejected;
      default:
        return OrderStatus.unknown;
    }
  }

  /// Parses any dynamic value (null, bool, String, num) into [OrderStatus].
  /// Null and empty → pending, bool → approved/rejected, otherwise delegates
  /// to [fromRaw].
  static OrderStatus fromDynamic(dynamic value) {
    if (value == null) return OrderStatus.pending;
    if (value is bool) return value ? OrderStatus.approved : OrderStatus.rejected;
    return fromRaw(value.toString());
  }

  /// Returns the canonical string expected by the backend API for POST/PUT
  /// payloads (e.g. 'Approved', 'Pending', 'Rejected').
  String get apiValue => switch (this) {
    OrderStatus.approved => 'Approved',
    OrderStatus.pending => 'Pending',
    OrderStatus.rejected => 'Rejected',
    OrderStatus.unknown => 'Unknown',
  };

  IconData get icon => switch (this) {
    OrderStatus.approved => Icons.check_circle_rounded,
    OrderStatus.pending => Icons.access_time_rounded,
    OrderStatus.rejected => Icons.cancel_rounded,
    OrderStatus.unknown => Icons.help_outline_rounded,
  };

  Color get detailForegroundColor => switch (this) {
    OrderStatus.approved => const Color(0xFF1B8B4B),
    OrderStatus.pending => const Color(0xFFD97706),
    OrderStatus.rejected => const Color(0xFFDC2626),
    OrderStatus.unknown => const Color(0xFF6B7280),
  };

  Color get detailBackgroundColor => switch (this) {
    OrderStatus.approved => const Color(0xFFECFDF5),
    OrderStatus.pending => const Color(0xFFFFFBEB),
    OrderStatus.rejected => const Color(0xFFFEF2F2),
    OrderStatus.unknown => const Color(0xFFF3F4F6),
  };

  Color get listForegroundColor => switch (this) {
    OrderStatus.approved => const Color(0xFF2E7D32),
    OrderStatus.pending => const Color(0xFFE65100),
    OrderStatus.rejected => const Color(0xFFC62828),
    OrderStatus.unknown => Colors.grey,
  };
}
