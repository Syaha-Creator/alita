import 'package:get_it/get_it.dart';

import '../services/api_client.dart';
import '../features/authentication/data/repositories/auth_repository.dart';
import '../features/authentication/domain/usecases/login_usecase.dart';
import '../features/authentication/presentation/bloc/auth_bloc.dart';

final locator = GetIt.instance;

void setupLocator() {
  // ✅ Register API Client (agar bisa digunakan di berbagai repository)
  locator.registerLazySingleton<ApiClient>(() => ApiClient());

  // ✅ Register Auth Repository (Menggunakan API Client dari DI)
  locator.registerLazySingleton<AuthRepository>(
      () => AuthRepository(apiClient: locator<ApiClient>()));

  // ✅ Register UseCase untuk Login
  locator.registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(locator<AuthRepository>()));

  // ✅ Register AuthBloc
  locator
      .registerLazySingleton<AuthBloc>(() => AuthBloc(locator<LoginUseCase>()));
}
