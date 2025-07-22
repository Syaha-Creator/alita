import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/exceptions.dart';
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

        final success = await AuthService.login(auth.accessToken,
            auth.refreshToken, auth.id, auth.name, auth.areaId);

        if (!success) {
          throw Exception("Gagal menyimpan sesi login.");
        }

        emit(AuthSuccess(auth.accessToken));
      } on ServerException catch (e) {
        emit(AuthFailure(e.message));
      } on NetworkException catch (e) {
        emit(AuthFailure(e.message));
      } catch (e) {
        emit(AuthFailure('Terjadi kesalahan yang tidak terduga.'));
      }
    });

    on<AuthLogoutRequested>((event, emit) async {
      await AuthService.logout();
      emit(AuthInitial());
    });
  }
}
