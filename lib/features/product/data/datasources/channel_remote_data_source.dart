import 'package:dio/dio.dart';

import '../../../../config/api_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../services/api_client.dart';
import '../../../../services/auth_service.dart';
import '../models/channel_model.dart';

/// Remote data source untuk channel API calls
abstract class ChannelRemoteDataSource {
  Future<List<ChannelModel>> fetchChannels();
}

class ChannelRemoteDataSourceImpl implements ChannelRemoteDataSource {
  final ApiClient apiClient;

  ChannelRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ChannelModel>> fetchChannels() async {
    try {
      String? token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw ServerException(
          "Sesi Anda telah berakhir. Silakan login ulang untuk melanjutkan.",
        );
      }

      final url = ApiConfig.getPlChannelsUrl(token: token);

      final response = await apiClient.get(url);

      if (response.statusCode != 200) {
        throw ServerException(
          "Gagal mengambil data channel. Kode error: ${response.statusCode}",
        );
      }

      // Check API response status
      if (response.data['status'] != 'success') {
        throw ServerException(
          "API mengembalikan status error: ${response.data['status']}",
        );
      }

      // Check for both "result" and "data" keys in response
      final rawData = response.data["data"] ?? response.data["result"];

      if (rawData is! List) {
        throw ServerException(
          "Data channel tidak ditemukan. Silakan coba lagi.",
        );
      }

      final channels = rawData.map((item) {
        try {
          return ChannelModel.fromJson(item as Map<String, dynamic>);
        } catch (e) {
          rethrow;
        }
      }).toList();

      // Filter only active channels
      final activeChannels =
          channels.where((channel) => channel.isActive ?? true).toList();

      return activeChannels;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(
          "Timeout saat mengambil data channel. Silakan coba lagi.",
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(
          "Tidak dapat terhubung ke server. Periksa koneksi internet Anda.",
        );
      } else {
        throw ServerException("Error jaringan: ${e.message}");
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException("Error tidak terduga: $e");
    }
  }
}

