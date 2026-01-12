import '../../../../config/dependency_injection.dart';
import '../../../../features/product/presentation/bloc/product_bloc.dart';
import '../entities/cart_entity.dart';
import 'get_primary_item_name_usecase.dart';
import 'should_upload_item_usecase.dart';

/// Use case untuk get leader IDs dari cart items
/// 
/// Gets leader IDs from product state with item mapping
class GetLeaderIdsFromCartUseCase {
  final GetPrimaryItemNameUseCase _getPrimaryItemNameUseCase;

  GetLeaderIdsFromCartUseCase({
    GetPrimaryItemNameUseCase? getPrimaryItemNameUseCase,
  }) : _getPrimaryItemNameUseCase =
            getPrimaryItemNameUseCase ??
            GetPrimaryItemNameUseCase(ShouldUploadItemUseCase());

  /// Get leader IDs from cart items
  /// 
  /// Returns Map dengan keys:
  /// - itemLeaderIds: Map dengan Leader IDs per item name
  /// - leaderIds: List dengan Flattened leader IDs (for backward compatibility)
  Map<String, dynamic> call(List<CartEntity> cartItems) {
    // Get leader IDs from product state with item mapping
    final Map<String, List<int?>> itemLeaderIds = {};
    for (final item in cartItems) {
      final state = locator<ProductBloc>().state;
      final productLeaderIds = state.productLeaderIds[item.product.id] ?? [];
      if (productLeaderIds.isNotEmpty) {
        // Get primary item name based on priority
        final primaryName = _getPrimaryItemNameUseCase(item) ?? '';
        if (primaryName.isNotEmpty) {
          itemLeaderIds[primaryName] = productLeaderIds;
        }
      }
    }

    // For backward compatibility, flatten all leader IDs
    final List<int?> leaderIds = [];
    for (final item in cartItems) {
      final state = locator<ProductBloc>().state;
      final productLeaderIds = state.productLeaderIds[item.product.id] ?? [];
      leaderIds.addAll(productLeaderIds);
    }

    return {
      'itemLeaderIds': itemLeaderIds,
      'leaderIds': leaderIds,
    };
  }
}

