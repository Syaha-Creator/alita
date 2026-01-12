import '../entities/item_lookup_entity.dart';
import '../repositories/item_lookup_repository.dart';

/// Use case untuk fetch lookup items dengan parameter filtering
class FetchLookupItemsUseCase {
  final ItemLookupRepository repository;

  FetchLookupItemsUseCase(this.repository);

  Future<List<ItemLookupEntity>> call({
    required String brand,
    required String kasur,
    String? divan,
    String? headboard,
    String? sorong,
    required String ukuran,
    String? contextItemType,
  }) async {
    return await repository.fetchLookupItems(
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

