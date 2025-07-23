// File: lib/config/dependency_injection.dart
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../features/product/data/repositories/product_repository.dart';
import '../features/product/domain/usecases/get_product_usecase.dart';
import '../features/product/presentation/bloc/product_bloc.dart';
import '../services/api_client.dart';
import '../services/cart_storage_service.dart';
import '../features/authentication/data/repositories/auth_repository.dart';
import '../features/authentication/domain/usecases/login_usecase.dart';
import '../features/authentication/presentation/bloc/auth_bloc.dart';
import 'api_config.dart';
import '../features/approval/data/repositories/approval_repository.dart';
import '../features/approval/domain/usecases/create_approval_usecase.dart';
import '../features/approval/domain/usecases/get_approvals_usecase.dart';
import '../features/approval/presentation/bloc/approval_bloc.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<Dio>(() {
    final options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
      },
    );
    return Dio(options);
  });

  // Register Services
  locator.registerLazySingleton<ApiClient>(() => ApiClient(locator<Dio>()));
  locator.registerLazySingleton<CartStorageService>(() => CartStorageService());

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

  // Approval Feature
  locator.registerLazySingleton<ApprovalRepository>(
      () => ApprovalRepositoryImpl(dio: locator<Dio>()));
  locator.registerLazySingleton<CreateApprovalUseCase>(
      () => CreateApprovalUseCase(repository: locator<ApprovalRepository>()));
  locator.registerLazySingleton<GetApprovalsUseCase>(
      () => GetApprovalsUseCase(repository: locator<ApprovalRepository>()));
  locator.registerLazySingleton<ApprovalBloc>(() => ApprovalBloc(
        createApprovalUseCase: locator<CreateApprovalUseCase>(),
        getApprovalsUseCase: locator<GetApprovalsUseCase>(),
      ));
}
