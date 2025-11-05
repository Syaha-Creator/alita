import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static const double _radiusMeters = 50.0; // 50 meter radius

  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    // Cek permission yang lebih spesifik dulu
    final statusWhenInUse = await Permission.locationWhenInUse.status;
    if (statusWhenInUse.isGranted) {
      return true;
    }

    // Jika tidak, cek permission umum
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    // Request permission dengan cara yang lebih eksplisit
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      return true;
    }

    // Jika tidak granted, coba request permission yang lebih spesifik
    if (status.isDenied) {
      final status2 = await Permission.location.request();
      return status2.isGranted;
    }

    return false;
  }

  /// Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      if (kDebugMode) {
        print('LocationService: Starting location request...');
      }

      // Check if location permission is granted
      final permissionStatus = await Permission.locationWhenInUse.status;
      if (kDebugMode) {
        print('LocationService: Permission status: $permissionStatus');
      }

      if (!permissionStatus.isGranted) {
        if (kDebugMode) {
          print('LocationService: Requesting location permission...');
        }
        final granted = await requestLocationPermission();
        if (kDebugMode) {
          print('LocationService: Permission granted: $granted');
        }
        if (!granted) {
          // Cek apakah permission ditolak secara permanen
          final finalStatus = await Permission.locationWhenInUse.status;
          if (finalStatus.isPermanentlyDenied) {
            throw Exception(
                'Location permission permanently denied. Please enable location permission in app settings.');
          } else {
            throw Exception(
                'Location permission denied. Please enable location permission in settings.');
          }
        }
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
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

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
    await openAppSettings();
  }
}
