import '../../../../config/app_constant.dart';
import '../../../../services/channel_service.dart';
import '../models/channel_model.dart';

class ChannelRepository {
  final ChannelService channelService;

  // Cache for channels to avoid repeated API calls
  List<ChannelModel>? _cachedChannels;
  DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  ChannelRepository({required this.channelService});

  /// Fetch channels from API with caching
  Future<List<ChannelModel>> fetchChannels() async {
    // Check if cache is still valid
    if (_cachedChannels != null && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _cacheValidDuration) {
        print(
            "ChannelRepository: Returning cached channels (${_cachedChannels!.length} channels)");
        return _cachedChannels!;
      }
    }

    try {
      print("ChannelRepository: Fetching channels from API...");
      final channels = await channelService.fetchChannels();

      // Update cache
      _cachedChannels = channels;
      _lastFetchTime = DateTime.now();

      print(
          "ChannelRepository: Successfully fetched and cached ${channels.length} channels");
      return channels;
    } catch (e) {
      print("ChannelRepository: Error fetching channels from API: $e");

      // If API fails, return hardcoded channels as fallback
      print("ChannelRepository: Falling back to hardcoded channels");
      return _getHardcodedChannels();
    }
  }

  /// Get channels as ChannelEnum list (for backward compatibility)
  Future<List<ChannelEnum>> fetchChannelsAsEnum() async {
    try {
      final channels = await fetchChannels();
      final channelEnums = <ChannelEnum>[];

      for (final channel in channels) {
        final channelEnum = ChannelEnum.fromApiData(channel.id, channel.name);
        if (channelEnum != null) {
          channelEnums.add(channelEnum);
        }
      }

      // If no channels were converted, fall back to hardcoded values
      if (channelEnums.isEmpty) {
        print(
            "ChannelRepository: No channels converted to enum, using hardcoded values");
        return ChannelEnum.allValues;
      }

      return channelEnums;
    } catch (e) {
      print("ChannelRepository: Error converting channels to enum: $e");
      return ChannelEnum.allValues;
    }
  }

  /// Get channel by ID
  Future<ChannelModel?> getChannelById(int id) async {
    try {
      final channels = await fetchChannels();
      return channels.firstWhere((channel) => channel.id == id);
    } catch (e) {
      print("ChannelRepository: Error getting channel by ID $id: $e");
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
      print("ChannelRepository: Error getting channel by name '$name': $e");
      return null;
    }
  }

  /// Clear cache (useful for testing or when data needs to be refreshed)
  void clearCache() {
    _cachedChannels = null;
    _lastFetchTime = null;
    print("ChannelRepository: Cache cleared");
  }

  /// Get hardcoded channels as fallback
  List<ChannelModel> _getHardcodedChannels() {
    return [
      ChannelModel(id: 1, name: "Call Center"),
      ChannelModel(id: 2, name: "Indirect"),
      ChannelModel(id: 3, name: "Retail"),
      ChannelModel(id: 4, name: "Accessories"),
      ChannelModel(id: 5, name: "Massindo Fair - Direct"),
      ChannelModel(id: 6, name: "Massindo Fair - Indirect"),
      ChannelModel(id: 7, name: "Modern Market"),
    ];
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
      print(
          "ChannelRepository: Returning all ${channelNames.length} channel names from API");
      return channelNames;
    } catch (e) {
      print("ChannelRepository: Error fetching all channel names: $e");
      // Fallback to hardcoded channel names
      return ChannelEnum.values.map((e) => e.value).toList();
    }
  }

  /// Get all channels from API as ChannelModel list (includes all channels, not just enum-convertible ones)
  Future<List<ChannelModel>> fetchAllChannels() async {
    try {
      final channels = await fetchChannels();
      print(
          "ChannelRepository: Returning all ${channels.length} channels from API");
      return channels;
    } catch (e) {
      print("ChannelRepository: Error fetching all channels: $e");
      // Fallback to hardcoded channels
      return _getHardcodedChannels();
    }
  }
}
