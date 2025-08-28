import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../core/error/exceptions.dart';
import '../features/product/data/models/channel_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class ChannelService {
  final ApiClient apiClient;

  ChannelService({required this.apiClient});

  /// Fetch channels from the pl_channels API endpoint
  Future<List<ChannelModel>> fetchChannels() async {
    try {
      String? token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception(
            "Sesi Anda telah berakhir. Silakan login ulang untuk melanjutkan.");
      }

      final url = ApiConfig.getPlChannelsUrl(token: token);
      print("ChannelService: Making request to: $url");

      final response = await apiClient.get(url);

      if (response.statusCode != 200) {
        throw Exception(
            "Gagal mengambil data channel. Kode error: ${response.statusCode}");
      }

      // Debug: Log response structure
      print(
          "ChannelService: API Response keys: ${response.data.keys.toList()}");
      print("ChannelService: API Response status: ${response.data['status']}");

      // Check API response status
      if (response.data['status'] != 'success') {
        throw Exception(
            "API mengembalikan status error: ${response.data['status']}");
      }

      // Check for both "result" and "data" keys in response
      final rawData = response.data["data"] ?? response.data["result"];

      if (rawData is! List) {
        print("ChannelService: Raw data type: ${rawData.runtimeType}");
        print("ChannelService: Raw data content: $rawData");
        throw Exception("Data channel tidak ditemukan. Silakan coba lagi.");
      }

      final channels = rawData.map((item) {
        try {
          return ChannelModel.fromJson(item as Map<String, dynamic>);
        } catch (e) {
          print("ChannelService: Error parsing channel item: $e");
          print("ChannelService: Item data: $item");
          rethrow;
        }
      }).toList();

      // Filter only active channels
      final activeChannels =
          channels.where((channel) => channel.isActive ?? true).toList();

      print(
          "ChannelService: Successfully fetched ${activeChannels.length} channels");
      return activeChannels;
    } on DioException catch (e) {
      print("ChannelService: DioException occurred: ${e.type} - ${e.message}");
      print("ChannelService: DioException response: ${e.response?.data}");

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(
            "Timeout saat mengambil data channel. Silakan coba lagi.");
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(
            "Tidak dapat terhubung ke server. Periksa koneksi internet Anda.");
      } else {
        throw ServerException("Error jaringan: ${e.message}");
      }
    } catch (e) {
      print("ChannelService: Unexpected error: $e");
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException("Error tidak terduga: $e");
    }
  }

  /// Get channel by ID
  Future<ChannelModel?> getChannelById(int id) async {
    try {
      final channels = await fetchChannels();
      return channels.firstWhere((channel) => channel.id == id);
    } catch (e) {
      print("ChannelService: Error getting channel by ID $id: $e");
      return null;
    }
  }

  /// Get channel by name
  Future<ChannelModel?> getChannelByName(String name) async {
    try {
      final channels = await fetchChannels();
      return channels.firstWhere(
        (channel) => channel.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      print("ChannelService: Error getting channel by name '$name': $e");
      return null;
    }
  }
}
