import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/error_logger.dart';
import '../../../../services/auth_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final AuthRepository authRepository;

  AuthBloc({
    required this.loginUseCase,
    required this.authRepository,
  }) : super(AuthInitial()) {
    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());

      if (kDebugMode) {
        ErrorLogger.logDebug(
          'AuthBloc: Login requested',
          extra: {'email': event.email},
        );
      }

      try {
        final auth = await loginUseCase(event.email, event.password);

        if (kDebugMode) {
          ErrorLogger.logDebug(
            'AuthBloc: Login use case completed',
            extra: {
              'hasToken': auth.accessToken.isNotEmpty,
              'userId': auth.id,
            },
          );
        }

        if (auth.accessToken.isEmpty) {
          throw Exception("Login gagal: Token tidak ditemukan.");
        }

        // Use repository to save login data (which uses local data source)
        // Also call AuthService.login for backward compatibility (clears cache, registers FCM, etc.)
        final success = await authRepository.saveLoginData(
          token: auth.accessToken,
          refreshToken: auth.refreshToken,
          userId: auth.id,
          userName: auth.name,
          areaId: auth.areaId,
          areaName: auth.areaName,
        );

        if (!success) {
          throw Exception("Gagal menyimpan sesi login.");
        }

        // Call AuthService.login for additional side effects (cache clearing, FCM registration)
        await AuthService.login(
          auth.accessToken,
          auth.refreshToken,
          auth.id,
          auth.name,
          auth.areaId,
          areaName: auth.areaName,
          addressNumber: auth.addressNumber,
        );

        emit(AuthSuccess(auth.accessToken));

        if (kDebugMode) {
          ErrorLogger.logInfo('AuthBloc: Login successful');
        }
      } on ServerException catch (e, stackTrace) {
        if (kDebugMode) {
          ErrorLogger.logError(
            e,
            stackTrace: stackTrace,
            context: 'AuthBloc: ServerException during login',
            extra: {'message': e.message},
            fatal: false,
          );
        }
        emit(AuthFailure(e.message));
      } on NetworkException catch (e, stackTrace) {
        if (kDebugMode) {
          ErrorLogger.logError(
            e,
            stackTrace: stackTrace,
            context: 'AuthBloc: NetworkException during login',
            extra: {'message': e.message},
            fatal: false,
          );
        }
        emit(AuthFailure(e.message));
      } catch (e, stackTrace) {
        if (kDebugMode) {
          ErrorLogger.logError(
            e,
            stackTrace: stackTrace,
            context: 'AuthBloc: Unexpected error during login',
            extra: {
              'errorType': e.runtimeType.toString(),
              'errorMessage': e.toString(),
            },
            fatal: false,
          );
        }
        // Show actual error message if available
        final errorMessage = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Terjadi kesalahan yang tidak terduga: ${e.toString()}';
        emit(AuthFailure(errorMessage));
      }
    });

    on<AuthLogoutRequested>((event, emit) async {
      await authRepository.logout();
      await AuthService.logout(); // For backward compatibility (cache clearing)
      emit(AuthInitial());
    });
  }
}
