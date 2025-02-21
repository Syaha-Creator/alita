import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../services/auth_service.dart';
import '../../../product/presentation/bloc/event/product_event.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
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
        locator<ProductBloc>().add(FetchProducts());
      } catch (e) {
        print("❌ Login failed: $e");
        emit(AuthFailure(e.toString()));
      }
    });

    on<AuthLogoutRequested>((event, emit) async {
      print("🚪 Logging out...");

      await AuthService.logout();
      emit(AuthInitial());

      locator<ProductBloc>().add(ResetProductState());

      print("✅ Logout successful.");
    });
  }
}
