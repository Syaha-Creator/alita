import '../../../../core/error/exceptions.dart';
import '../datasources/item_lookup_remote_data_source.dart';
import '../../domain/entities/item_lookup_entity.dart';
import '../../domain/repositories/item_lookup_repository.dart';

class ItemLookupRepositoryImpl implements ItemLookupRepository {
  final ItemLookupRemoteDataSource remoteDataSource;

  ItemLookupRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ItemLookupEntity>> fetchItemLookups() async {
    try {
      final itemLookups = await remoteDataSource.fetchItemLookups();

      // Convert models to entities
      return itemLookups
          .map((model) => ItemLookupEntity(
                id: model.id,
                brand: model.brand,
                tipe: model.tipe,
                tebal: model.tebal,
                ukuran: model.ukuran,
                itemNum: model.itemNum,
                itemDesc: model.itemDesc,
                jenisKain: model.jenisKain,
                warnaKain: model.warnaKain,
                berat: model.berat,
                kubikasi: model.kubikasi,
                createdAt: model.createdAt,
                updatedAt: model.updatedAt,
              ))
          .toList();
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        "Terjadi kesalahan yang tidak diketahui saat memproses data: $e",
      );
    }
  }

  @override
  Future<List<ItemLookupEntity>> fetchLookupItems({
    required String brand,
    required String kasur,
    String? divan,
    String? headboard,
    String? sorong,
    required String ukuran,
    String? contextItemType,
  }) async {
    try {
      final itemLookups = await remoteDataSource.fetchLookupItems(
        brand: brand,
        kasur: kasur,
        divan: divan,
        headboard: headboard,
        sorong: sorong,
        ukuran: ukuran,
        contextItemType: contextItemType,
      );

      // Convert models to entities
      return itemLookups
          .map((model) => ItemLookupEntity(
                id: model.id,
                brand: model.brand,
                tipe: model.tipe,
                tebal: model.tebal,
                ukuran: model.ukuran,
                itemNum: model.itemNum,
                itemDesc: model.itemDesc,
                jenisKain: model.jenisKain,
                warnaKain: model.warnaKain,
                berat: model.berat,
                kubikasi: model.kubikasi,
                createdAt: model.createdAt,
                updatedAt: model.updatedAt,
              ))
          .toList();
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        "Terjadi kesalahan yang tidak diketahui saat memproses data: $e",
      );
    }
  }
}
