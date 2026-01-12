import '../entities/cart_entity.dart';
import 'should_upload_item_usecase.dart';

/// Use case untuk get primary item name berdasarkan priority
/// Priority: Kasur → Divan → Headboard → Sorong
class GetPrimaryItemNameUseCase {
  final ShouldUploadItemUseCase _shouldUploadItemUseCase;

  GetPrimaryItemNameUseCase(this._shouldUploadItemUseCase);

  String? call(CartEntity item) {
    if (_shouldUploadItemUseCase(item.product.kasur) &&
        item.product.plKasur > 0) {
      return item.product.kasur;
    } else if (_shouldUploadItemUseCase(item.product.divan) &&
        item.product.plDivan > 0) {
      return item.product.divan;
    } else if (_shouldUploadItemUseCase(item.product.headboard) &&
        item.product.plHeadboard > 0) {
      return item.product.headboard;
    } else if (_shouldUploadItemUseCase(item.product.sorong) &&
        item.product.plSorong > 0) {
      return item.product.sorong;
    }
    return null;
  }
}

