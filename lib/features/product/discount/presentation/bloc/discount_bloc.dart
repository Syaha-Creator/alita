import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'event/discount_event.dart';
part 'state/discount_state.dart';

class DiscountBloc extends Bloc<DiscountEvent, DiscountState> {
  DiscountBloc() : super(DiscountInitial()) {
    on<DiscountEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
