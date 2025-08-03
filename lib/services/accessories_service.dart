import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/app_constant.dart';
import '../features/product/domain/entities/product_entity.dart';

class AccessoriesService {
  static Future<List<ProductEntity>> getAccessories() async {
    try {
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(StorageKeys.authToken);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final dio = Dio();

      // Accessories only available for Comforta brand and Jabodetabek area
      final String area = 'Jabodetabek';
      final String brand = 'Comforta';

      final String tokenToUse = token;

      final url = ApiConfig.getFilteredProductsUrl(
        token: tokenToUse,
        area: area,
        channel: 'Accessories',
        brand: brand,
      );

      print('Using token: $tokenToUse');
      print('Trying URL: $url');
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        print('Response for $area-$brand: $responseData');

        // Check if response has 'result' field
        final dynamic result = responseData['result'];
        print('Result for $area-$brand: $result');

        // Handle both List and Map responses
        List<dynamic> productsList;
        if (result is List) {
          productsList = result;
        } else if (result is Map) {
          productsList =
              result['products'] ?? result['items'] ?? result['data'] ?? [];
        } else {
          // Fallback to old structure
          final dynamic data = responseData['data'] ?? responseData;
          if (data is List) {
            productsList = data;
          } else if (data is Map) {
            productsList =
                data['products'] ?? data['items'] ?? data['data'] ?? [];
          } else {
            throw Exception('Unexpected response format: ${data.runtimeType}');
          }
        }

        // Map the response data to ProductEntity based on actual API response
        final accessories = productsList
            .map((product) => ProductEntity(
                  id: product['id'],
                  area: product['area'] ?? '',
                  channel: product['channel'] ?? '',
                  brand: product['brand'] ?? '',
                  kasur: product['kasur'] ?? '',
                  divan: product['divan'] ?? '',
                  headboard: product['headboard'] ?? '',
                  sorong: product['sorong'] ?? '',
                  ukuran: product['ukuran'] ?? '',
                  pricelist: (product['pricelist'] ?? 0).toDouble(),
                  program: product['program'] ?? '',
                  eupKasur: (product['eup_kasur'] ?? 0).toDouble(),
                  eupDivan: (product['eup_divan'] ?? 0).toDouble(),
                  eupHeadboard: (product['eup_headboard'] ?? 0).toDouble(),
                  endUserPrice: (product['end_user_price'] ?? 0).toDouble(),
                  bonus: (product['bonus'] as List<dynamic>? ?? [])
                      .map((bonus) => BonusItem(
                            name: bonus['name'] ?? '',
                            quantity: bonus['quantity'] ?? 0,
                          ))
                      .toList(),
                  discounts: List<double>.from(
                      (product['discounts'] as List<dynamic>? ?? <dynamic>[])
                          .map((d) => (d ?? 0).toDouble())),
                  isSet: product['set'] ?? false,
                  plKasur: (product['pl_kasur'] ?? 0).toDouble(),
                  plDivan: (product['pl_divan'] ?? 0).toDouble(),
                  plHeadboard: (product['pl_headboard'] ?? 0).toDouble(),
                  plSorong: (product['pl_sorong'] ?? 0).toDouble(),
                  eupSorong: (product['eup_sorong'] ?? 0).toDouble(),
                  bottomPriceAnalyst:
                      (product['bottom_price_analyst'] ?? 0).toDouble(),
                  disc1: (product['disc1'] ?? 0).toDouble(),
                  disc2: (product['disc2'] ?? 0).toDouble(),
                  disc3: (product['disc3'] ?? 0).toDouble(),
                  disc4: (product['disc4'] ?? 0).toDouble(),
                  disc5: (product['disc5'] ?? 0).toDouble(),
                  itemNumber: product['item_number'],
                  itemNumberKasur: product['item_number_kasur'],
                  itemNumberDivan: product['item_number_divan'],
                  itemNumberHeadboard: product['item_number_headboard'],
                  itemNumberSorong: product['item_number_sorong'],
                  itemNumberAccessories: product['item_number_accessories'],
                  itemNumberBonus1: product['item_number_bonus1'],
                  itemNumberBonus2: product['item_number_bonus2'],
                  itemNumberBonus3: product['item_number_bonus3'],
                  itemNumberBonus4: product['item_number_bonus4'],
                  itemNumberBonus5: product['item_number_bonus5'],
                ))
            .toList();

        print('Found ${accessories.length} accessories for $area-$brand');
        return accessories;
      } else {
        throw Exception('Failed to load accessories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load accessories: $e');
    }
  }
}
