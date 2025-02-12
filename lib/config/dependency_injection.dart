import 'package:get_it/get_it.dart';

import '../features/product/data/repositories/product_repository.dart';
import '../features/product/domain/usecases/get_product_usecase.dart';
import '../features/product/presentation/bloc/product_bloc.dart';
import '../services/api_client.dart';
import '../features/authentication/data/repositories/auth_repository.dart';
import '../features/authentication/domain/usecases/login_usecase.dart';
import '../features/authentication/presentation/bloc/auth_bloc.dart';

final locator = GetIt.instance;

void setupLocator() {
  // Register API Client
  locator.registerLazySingleton<ApiClient>(() => ApiClient());

  // Register Auth Dependencies
  locator.registerLazySingleton<AuthRepository>(
      () => AuthRepository(apiClient: locator<ApiClient>()));
  locator.registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(locator<AuthRepository>()));
  locator
      .registerLazySingleton<AuthBloc>(() => AuthBloc(locator<LoginUseCase>()));

  // Register Product Dependencies
  locator.registerLazySingleton<ProductRepository>(
      () => ProductRepository(apiClient: locator<ApiClient>()));
  locator.registerLazySingleton<GetProductUseCase>(
      () => GetProductUseCase(locator<ProductRepository>()));
  locator.registerLazySingleton<ProductBloc>(
      () => ProductBloc(locator<GetProductUseCase>()));
}
