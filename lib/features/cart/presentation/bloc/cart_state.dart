import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_entity.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartLoaded extends CartState {
  final List<CartEntity> cartItems;
  const CartLoaded(this.cartItems);

  // Filter out checked out items (items that have been saved to draft or checked out)
  List<CartEntity> get activeCartItems =>
      cartItems.where((item) => !item.isCheckedOut).toList();

  List<CartEntity> get selectedItems =>
      activeCartItems.where((item) => item.isSelected).toList();

  @override
  List<Object?> get props => [cartItems];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}
