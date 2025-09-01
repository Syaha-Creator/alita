import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/app_constant.dart';
import '../features/product/domain/entities/product_entity.dart';

// New entity class for accessories from the new API
class AccessoryEntity {
  final int id;
  final String brand;
  final String series;
  final String tipe;
  final String? itemNum;
  final String item;
  final String ukuran;
  final String createdAt;
  final String updatedAt;

  AccessoryEntity({
    required this.id,
    required this.brand,
    required this.series,
    required this.tipe,
    this.itemNum,
    required this.item,
    required this.ukuran,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccessoryEntity.fromJson(Map<String, dynamic> json) {
    return AccessoryEntity(
      id: json['id'] ?? 0,
      brand: json['brand'] ?? '',
      series: json['series'] ?? '',
      tipe: json['tipe'] ?? '',
      itemNum: json['item_num'],
      item: json['item'] ?? '',
      ukuran: json['ukuran'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  // Convert to ProductEntity for compatibility with existing cart system
  ProductEntity toProductEntity() {
    return ProductEntity(
      id: id,
      area: 'Jabodetabek', // Default area for accessories
      channel: 'Accessories',
      brand: brand,
      kasur: item,
      divan: '',
      headboard: '',
      sorong: '',
      ukuran: ukuran,
      pricelist: 0.0, // Accessories are free as bonus
      program: '',
      eupKasur: 0.0,
      eupDivan: 0.0,
      eupHeadboard: 0.0,
      endUserPrice: 0.0,
      bonus: [],
      discounts: [],
      isSet: false,
      plKasur: 0.0,
      plDivan: 0.0,
      plHeadboard: 0.0,
      plSorong: 0.0,
      eupSorong: 0.0,
      bottomPriceAnalyst: 0.0,
      disc1: 0.0,
      disc2: 0.0,
      disc3: 0.0,
      disc4: 0.0,
      disc5: 0.0,
      itemNumber: itemNum,
      itemNumberKasur: itemNum,
      itemNumberDivan: null,
      itemNumberHeadboard: null,
      itemNumberSorong: null,
      itemNumberAccessories: itemNum,
      itemNumberBonus1: itemNum,
      itemNumberBonus2: null,
      itemNumberBonus3: null,
      itemNumberBonus4: null,
      itemNumberBonus5: null,
    );
  }
}

class AccessoriesService {
  // New method to get accessories from the new API endpoint
  static Future<List<AccessoryEntity>> getAccessoriesFromNewAPI() async {
    try {
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(StorageKeys.authToken);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final dio = Dio();
      final url = ApiConfig.getAccessoriesUrl(token: token);

      print('Fetching accessories from new API: $url');
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        print('Accessories API response: $responseData');

        if (responseData['status'] == 'success' &&
            responseData['result'] != null) {
          final List<dynamic> accessoriesList = responseData['result'];

          final accessories = accessoriesList
              .map((accessory) => AccessoryEntity.fromJson(accessory))
              .toList();

          print('Found ${accessories.length} accessories from new API');
          return accessories;
        } else {
          throw Exception('Invalid response format from accessories API');
        }
      } else {
        throw Exception('Failed to load accessories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load accessories from new API: $e');
    }
  }

  // Legacy method for backward compatibility (kept for now)
  static Future<List<ProductEntity>> getAccessories() async {
    try {
      // Get accessories from new API and convert to ProductEntity
      final accessories = await getAccessoriesFromNewAPI();
      return accessories.map((acc) => acc.toProductEntity()).toList();
    } catch (e) {
      throw Exception('Failed to load accessories: $e');
    }
  }
}
