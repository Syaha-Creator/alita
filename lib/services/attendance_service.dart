import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'location_service.dart';

class AttendanceService {
  final Dio dio;

  AttendanceService(this.dio) {
    // Configure Dio for JSON response
    dio.options.headers['Accept'] = 'application/json';
    dio.options.headers['Content-Type'] = 'application/json';
  }

  /// Get attendance list and return the first (latest) record
  /// Returns work_place_id from the first attendance record
  Future<int?> getWorkPlaceId() async {
    try {
      final token = await AuthService.getToken();
      final userId = await AuthService.getCurrentUserId();

      if (token == null || userId == null) {
        return null;
      }

      final url = ApiConfig.getAttendanceListUrl(
        token: token,
        userId: userId,
      );

      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'User-Agent': 'AlitaPricelist/1.0',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle different response formats
        List<dynamic>? attendanceList;

        if (data is List) {
          attendanceList = data;
        } else if (data is Map && data['result'] is List) {
          attendanceList = data['result'];
        }

        if (attendanceList != null && attendanceList.isNotEmpty) {
          // Get first (latest/earliest) record
          final firstAttendance = attendanceList.first;

          // Handle different Map types
          Map<String, dynamic>? attendanceMap;

          if (firstAttendance is Map<String, dynamic>) {
            attendanceMap = firstAttendance;
          } else if (firstAttendance is Map) {
            // Convert to Map<String, dynamic>
            attendanceMap = Map<String, dynamic>.from(firstAttendance);
          }

          if (attendanceMap != null) {
            // Try different possible field names
            final workPlaceId = attendanceMap['work_place_id'] ??
                attendanceMap['workPlaceId'] ??
                attendanceMap['workplace_id'] ??
                attendanceMap['workplaceId'];

            if (workPlaceId != null) {
              int? parsedId;

              if (workPlaceId is int) {
                parsedId = workPlaceId;
              } else if (workPlaceId is double) {
                parsedId = workPlaceId.toInt();
              } else if (workPlaceId is String) {
                parsedId = int.tryParse(workPlaceId);
              } else {
                parsedId = int.tryParse(workPlaceId.toString());
              }

              if (parsedId != null && parsedId > 0) {
                return parsedId;
              }
            }
          }
        }

        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Get full attendance list
  Future<List<Map<String, dynamic>>> getAttendanceList() async {
    try {
      final token = await AuthService.getToken();
      final userId = await AuthService.getCurrentUserId();

      if (token == null || userId == null) {
        return [];
      }

      final url = ApiConfig.getAttendanceListUrl(
        token: token,
        userId: userId,
      );

      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'User-Agent': 'AlitaPricelist/1.0',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        List<Map<String, dynamic>> attendanceList;

        if (data is List) {
          attendanceList = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['result'] is List) {
          attendanceList = List<Map<String, dynamic>>.from(data['result']);
        } else {
          return [];
        }

        return attendanceList;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Get today's attendance and validate location for checkout
  Future<Map<String, dynamic>> validateCheckoutLocation() async {
    try {
      // Get attendance list from API
      final attendanceList = await getAttendanceList();

      if (attendanceList.isEmpty) {
        return {
          'isValid': false,
          'message': 'Anda belum melakukan attendance hari ini',
          'distance': null,
        };
      }

      // Get today's date
      final now = DateTime.now();
      final todayString =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Find today's attendance
      Map<String, dynamic>? todayAttendance;
      for (var attendance in attendanceList) {
        final attendanceInStr = attendance['attendance_in'] as String?;
        if (attendanceInStr != null && attendanceInStr.contains(todayString)) {
          todayAttendance = attendance;
          break;
        }
      }

      if (todayAttendance == null) {
        return {
          'isValid': false,
          'message': 'Anda belum melakukan attendance hari ini',
          'distance': null,
        };
      }

      // Get work place location (kantor)
      final workPlaceLat = todayAttendance['latitude_work_place'] as String?;
      final workPlaceLon = todayAttendance['longitude_work_place'] as String?;

      if (workPlaceLat == null || workPlaceLon == null) {
        return {
          'isValid': false,
          'message': 'Lokasi kantor tidak tersedia',
          'distance': null,
        };
      }

      final lat = double.tryParse(workPlaceLat);
      final lon = double.tryParse(workPlaceLon);

      if (lat == null || lon == null) {
        return {
          'isValid': false,
          'message': 'Koordinat lokasi kantor tidak valid',
          'distance': null,
        };
      }

      // Validate current location with work place location (50 meter radius)
      final result = await LocationService.validateLocationForCheckout(
        attendanceLat: lat,
        attendanceLon: lon,
      );

      return result;
    } catch (e) {
      return {
        'isValid': false,
        'message': 'Error validasi lokasi: $e',
        'distance': null,
      };
    }
  }
}
