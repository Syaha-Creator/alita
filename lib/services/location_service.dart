import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:geocoding/geocoding.dart';

class LocationService {
  static const double _radiusMeters = 50.0; // 50 meter radius

  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      if (kDebugMode) {
        print('LocationService: Starting location request...');
      }

      // Check if location permission is granted
      var permission = await Geolocator.checkPermission();
      if (kDebugMode) {
        print('LocationService: Permission status: $permission');
      }

      if (permission == LocationPermission.denied) {
        if (kDebugMode) {
          print('LocationService: Requesting location permission...');
        }
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permission permanently denied. Please enable location permission in app settings.');
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw Exception(
            'Location permission denied. Please enable location permission in settings.');
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (kDebugMode) {
        print('LocationService: Location services enabled: $serviceEnabled');
      }
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      if (kDebugMode) {
        print('LocationService: Getting current position...');
      }
      late final Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } on TimeoutException catch (timeoutError) {
        if (kDebugMode) {
          print(
              'LocationService: Timeout getting current position: $timeoutError');
        }
        final fallback = await Geolocator.getLastKnownPosition();
        if (fallback == null) {
          rethrow;
        }
        position = fallback;
      }

      if (kDebugMode) {
        print(
            'LocationService: Position obtained: ${position.latitude}, ${position.longitude}');
      }
      return position;
    } catch (e) {
      if (kDebugMode) {
        print('LocationService: Error getting current location: $e');
      }
      return null;
    }
  }

  /// Calculate distance between two coordinates in meters
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if current location is within radius of attendance location
  static Future<bool> isWithinAttendanceRadius({
    required double attendanceLat,
    required double attendanceLon,
  }) async {
    try {
      final currentPosition = await getCurrentLocation();
      if (currentPosition == null) {
        return false;
      }

      final distance = calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        attendanceLat,
        attendanceLon,
      );

      return distance <= _radiusMeters;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking attendance radius: $e');
      }
      return false;
    }
  }

  /// Get location address from coordinates
  static Future<String?> getLocationAddress(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location address: $e');
      }
      return null;
    }
  }

  /// Get formatted location info
  static Future<Map<String, dynamic>?> getLocationInfo() async {
    try {
      final position = await getCurrentLocation();
      if (position == null) return null;

      final address = await getLocationAddress(
        position.latitude,
        position.longitude,
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'address': address,
        'timestamp': position.timestamp,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location info: $e');
      }
      return null;
    }
  }

  /// Validate location for checkout
  static Future<Map<String, dynamic>> validateLocationForCheckout({
    required double attendanceLat,
    required double attendanceLon,
  }) async {
    try {
      if (kDebugMode) {
        print('LocationService: Validating location for checkout...');
      }
      if (kDebugMode) {
        print(
            'LocationService: Attendance location: $attendanceLat, $attendanceLon');
      }

      final currentPosition = await getCurrentLocation();
      if (currentPosition == null) {
        if (kDebugMode) {
          print('LocationService: Failed to get current position');
        }
        return {
          'isValid': false,
          'message':
              'Tidak dapat mendapatkan lokasi saat ini. Pastikan GPS aktif dan izin lokasi diberikan.',
          'distance': null,
        };
      }

      if (kDebugMode) {
        print(
            'LocationService: Current position: ${currentPosition.latitude}, ${currentPosition.longitude}');
      }

      final distance = calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        attendanceLat,
        attendanceLon,
      );

      if (kDebugMode) {
        print(
            'LocationService: Distance calculated: ${distance.toStringAsFixed(2)} meters');
      }

      final isWithinRadius = distance <= _radiusMeters;
      if (kDebugMode) {
        print(
            'LocationService: Within radius: $isWithinRadius (max: $_radiusMeters meters)');
      }

      return {
        'isValid': isWithinRadius,
        'message': isWithinRadius
            ? 'Lokasi valid. Anda berada dalam radius 50 meter dari lokasi attendance.'
            : 'Lokasi tidak valid. Anda berada ${distance.toStringAsFixed(0)} meter dari lokasi attendance. Maksimal 50 meter.',
        'distance': distance,
        'currentLat': currentPosition.latitude,
        'currentLon': currentPosition.longitude,
        'attendanceLat': attendanceLat,
        'attendanceLon': attendanceLon,
      };
    } catch (e) {
      if (kDebugMode) {
        print('LocationService: Error in validateLocationForCheckout: $e');
      }
      return {
        'isValid': false,
        'message': 'Error validasi lokasi: $e',
        'distance': null,
      };
    }
  }

  /// Open app settings if permission is permanently denied
  static Future<void> openAppSettings() async {
    await permission_handler.openAppSettings();
  }
}
