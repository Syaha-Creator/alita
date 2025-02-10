import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'event/cart_event.dart';
part 'state/cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartInitial()) {
    on<CartEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
