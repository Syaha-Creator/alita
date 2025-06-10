import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/auth_service.dart';
import '../../domain/usecases/login_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;

  AuthBloc(this.loginUseCase) : super(AuthInitial()) {
    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final auth = await loginUseCase(event.email, event.password);

        if (auth.accessToken.isEmpty) {
          throw Exception("Login gagal: Token tidak ditemukan.");
        }

        final success = await AuthService.login(
            auth.accessToken, auth.refreshToken, auth.id);

        if (!success) {
          throw Exception("Gagal menyimpan sesi login.");
        }

        print("✅ Login successful, token saved.");
        emit(AuthSuccess(auth.accessToken));
      } catch (e) {
        print("❌ Login failed: $e");
        String errorMessage = "Terjadi kesalahan. Silakan coba lagi.";
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('401') ||
            errorString.contains('invalid credentials')) {
          errorMessage = "Email atau password yang Anda masukkan salah.";
        } else if (errorString.contains('socketexception') ||
            errorString.contains('network is unreachable')) {
          errorMessage =
              "Gagal terhubung ke server. Periksa koneksi internet Anda.";
        }

        emit(AuthFailure(errorMessage));
      }
    });

    on<AuthLogoutRequested>((event, emit) async {
      print("🚪 Logging out...");

      await AuthService.logout();
      emit(AuthInitial());

      print("✅ Logout successful.");
    });
  }
}
