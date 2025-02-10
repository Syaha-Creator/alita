import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'event/product_event.dart';
part 'state/product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc() : super(ProductInitial()) {
    on<ProductEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
