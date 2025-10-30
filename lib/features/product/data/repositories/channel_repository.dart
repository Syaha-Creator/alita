import '../../../../services/channel_service.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../models/channel_model.dart';

class ChannelRepository {
  final ChannelService channelService;

  ChannelRepository({required this.channelService});

  /// Fetch channels from API (always fresh data)
  Future<List<ChannelModel>> fetchChannels() async {
    try {
      final channels = await channelService.fetchChannels();
      return channels;
    } catch (e) {
      // Show error toast to user
      CustomToast.showToast(
        "Gagal memuat data channel. Periksa koneksi internet Anda.",
        ToastType.error,
        duration: 3,
      );
      // Return empty list if API fails - no hardcoded fallback
      return [];
    }
  }

  /// Get channel by ID
  Future<ChannelModel?> getChannelById(int id) async {
    try {
      final channels = await fetchChannels();
      return channels.firstWhere((channel) => channel.id == id);
    } catch (e) {
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
      return null;
    }
  }

  /// Check if channels are available from API
  Future<bool> isApiAvailable() async {
    try {
      await channelService.fetchChannels();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all channels from API as strings (includes all channels, not just enum-convertible ones)
  Future<List<String>> fetchAllChannelNames() async {
    try {
      final channels = await fetchChannels();
      final channelNames = channels.map((channel) => channel.name).toList();
      return channelNames;
    } catch (e) {
      // Show error toast to user
      CustomToast.showToast(
        "Gagal memuat daftar channel. Periksa koneksi internet Anda.",
        ToastType.error,
        duration: 3,
      );
      // Return empty list if API fails - no hardcoded fallback
      return [];
    }
  }

  /// Get all channels from API as ChannelModel list (includes all channels, not just enum-convertible ones)
  Future<List<ChannelModel>> fetchAllChannels() async {
    try {
      final channels = await fetchChannels();
      return channels;
    } catch (e) {
      // Show error toast to user
      CustomToast.showToast(
        "Gagal memuat data channel. Periksa koneksi internet Anda.",
        ToastType.error,
        duration: 3,
      );
      // Return empty list if API fails - no hardcoded fallback
      return [];
    }
  }
}
