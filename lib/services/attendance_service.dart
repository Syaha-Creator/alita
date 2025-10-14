import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

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
        print('AttendanceService: Token or userId not found');
        print('AttendanceService: Token: ${token != null ? "exists" : "null"}');
        print('AttendanceService: UserId: $userId');
        return null;
      }

      final url = ApiConfig.getAttendanceListUrl(
        token: token,
        userId: userId,
      );

      print('AttendanceService: Fetching attendance from URL: $url');

      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'User-Agent': 'AlitaPricelist/1.0',
          },
        ),
      );

      print('AttendanceService: Response status code: ${response.statusCode}');
      print(
          'AttendanceService: Response data type: ${response.data.runtimeType}');
      print('AttendanceService: Full response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle different response formats
        List<dynamic>? attendanceList;

        if (data is List) {
          attendanceList = data;
          print('AttendanceService: Data is a List with ${data.length} items');
        } else if (data is Map && data['result'] is List) {
          attendanceList = data['result'];
          print(
              'AttendanceService: Data is a Map with result list containing ${attendanceList?.length ?? 0} items');
        } else if (data is Map) {
          print(
              'AttendanceService: Data is a Map with keys: ${data.keys.toList()}');
        }

        if (attendanceList != null && attendanceList.isNotEmpty) {
          print(
              'AttendanceService: Found ${attendanceList.length} attendance records');

          // Get first (latest/earliest) record
          final firstAttendance = attendanceList.first;
          print('AttendanceService: First attendance record: $firstAttendance');
          print(
              'AttendanceService: First attendance type: ${firstAttendance.runtimeType}');

          // Handle different Map types
          Map<String, dynamic>? attendanceMap;

          if (firstAttendance is Map<String, dynamic>) {
            attendanceMap = firstAttendance;
          } else if (firstAttendance is Map) {
            // Convert to Map<String, dynamic>
            attendanceMap = Map<String, dynamic>.from(firstAttendance);
          }

          if (attendanceMap != null) {
            print(
                'AttendanceService: Available keys in first attendance: ${attendanceMap.keys.toList()}');

            // Try different possible field names
            final workPlaceId = attendanceMap['work_place_id'] ??
                attendanceMap['workPlaceId'] ??
                attendanceMap['workplace_id'] ??
                attendanceMap['workplaceId'];

            print('AttendanceService: work_place_id value: $workPlaceId');
            print(
                'AttendanceService: work_place_id type: ${workPlaceId?.runtimeType}');

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

              print('AttendanceService: Parsed work_place_id: $parsedId');

              if (parsedId != null && parsedId > 0) {
                return parsedId;
              } else {
                print(
                    'AttendanceService: Invalid work_place_id value: $parsedId');
              }
            } else {
              print('AttendanceService: work_place_id is null in the record');
              print(
                  'AttendanceService: Full record for debugging: $attendanceMap');
            }
          } else {
            print(
                'AttendanceService: Could not convert first attendance to Map');
          }
        } else {
          print(
              'AttendanceService: attendanceList is ${attendanceList == null ? "null" : "empty"}');
        }

        print(
            'AttendanceService: No attendance data found or work_place_id is null');
        return null;
      } else {
        print(
            'AttendanceService: Failed to fetch attendance list: ${response.statusCode}');
        print('AttendanceService: Response body: ${response.data}');
        return null;
      }
    } catch (e, stackTrace) {
      print('AttendanceService: Error fetching attendance list: $e');
      print('AttendanceService: Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get full attendance list
  Future<List<Map<String, dynamic>>> getAttendanceList() async {
    try {
      final token = await AuthService.getToken();
      final userId = await AuthService.getCurrentUserId();

      if (token == null || userId == null) {
        print('AttendanceService: Token or userId not found');
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

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['result'] is List) {
          return List<Map<String, dynamic>>.from(data['result']);
        }

        return [];
      } else {
        print(
            'AttendanceService: Failed to fetch attendance list: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('AttendanceService: Error fetching attendance list: $e');
      return [];
    }
  }
}
