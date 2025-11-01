import '../../../../services/lookup_item_service.dart';

class FabricLookupUsecase {
  final LookupItemService _service;

  FabricLookupUsecase({LookupItemService? service})
      : _service = service ?? LookupItemService();

  Future<List<LookupItem>> fetchByContext({
    required String brand,
    required String kasur,
    String? divan,
    String? headboard,
    String? sorong,
    required String ukuran,
    required String contextItemType,
  }) async {
    return await _service.fetchLookupItems(
      brand: brand,
      kasur: kasur,
      divan: divan,
      headboard: headboard,
      sorong: sorong,
      ukuran: ukuran,
      contextItemType: contextItemType,
    );
  }
}
