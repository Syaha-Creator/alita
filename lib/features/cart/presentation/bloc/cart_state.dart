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

  // All cart items are active now (checked out items are removed from cart)
  List<CartEntity> get activeCartItems => cartItems;

  List<CartEntity> get selectedItems =>
      cartItems.where((item) => item.isSelected).toList();

  @override
  List<Object?> get props => [cartItems];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}
