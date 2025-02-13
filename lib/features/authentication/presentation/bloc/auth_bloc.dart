import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/auth_service.dart';
import '../../domain/usecases/login_usecase.dart';
import 'event/auth_event.dart';
import 'state/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;

  AuthBloc(this.loginUseCase) : super(AuthInitial()) {
    on<AuthLoginRequested>((event, emit) async {
      print("🔹 Event: AuthLoginRequested received");
      emit(AuthLoading());

      try {
        final auth = await loginUseCase(event.email, event.password);

        if (auth.accessToken.isEmpty) {
          throw Exception("Login gagal: Token tidak ditemukan.");
        }

        final success =
            await AuthService.login(auth.accessToken, auth.refreshToken);
        if (!success) {
          throw Exception("Gagal menyimpan token.");
        }

        print("✅ Login successful, token saved.");
        emit(AuthSuccess(auth.accessToken));
      } catch (e) {
        print("❌ Login failed: $e");
        emit(AuthFailure(e.toString()));
      }
    });
  }
}
