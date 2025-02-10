import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'event/auth_event.dart';
part 'state/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
