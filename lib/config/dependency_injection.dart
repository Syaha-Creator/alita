import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../features/product/data/repositories/product_repository.dart';
import '../features/product/domain/usecases/get_product_usecase.dart';
import '../features/product/presentation/bloc/product_bloc.dart';
import '../services/api_client.dart';
import '../services/cart_storage_service.dart';
import '../services/order_letter_service.dart';
import '../services/checkout_service.dart';
import '../services/contact_work_experience_service.dart';
import '../services/leader_service.dart';
import '../features/approval/data/repositories/approval_repository.dart';
import '../features/approval/domain/usecases/get_approvals_usecase.dart';
import '../features/approval/domain/usecases/create_approval_usecase.dart';
import '../features/approval/presentation/bloc/approval_bloc.dart';
import '../features/authentication/data/repositories/auth_repository.dart';
import '../features/authentication/domain/usecases/login_usecase.dart';
import '../features/authentication/presentation/bloc/auth_bloc.dart';
import '../features/order_letter_document/data/repositories/order_letter_document_repository.dart';
import 'api_config.dart';

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
  locator.registerLazySingleton<ApiClient>(() => ApiClient());
  locator.registerLazySingleton<CartStorageService>(() => CartStorageService());
  locator.registerLazySingleton<OrderLetterService>(
      () => OrderLetterService(locator<Dio>()));
  locator.registerLazySingleton<CheckoutService>(() => CheckoutService());
  locator.registerLazySingleton<ContactWorkExperienceService>(
      () => ContactWorkExperienceService(locator<ApiClient>()));
  locator.registerLazySingleton<LeaderService>(
      () => LeaderService(locator<ApiClient>()));

  // Register Approval Dependencies
  locator.registerLazySingleton<ApprovalRepository>(() => ApprovalRepository());
  locator.registerLazySingleton<GetApprovalsUseCase>(
      () => GetApprovalsUseCase(locator()));
  locator.registerLazySingleton<GetApprovalByIdUseCase>(
      () => GetApprovalByIdUseCase(locator()));
  locator.registerLazySingleton<GetPendingApprovalsUseCase>(
      () => GetPendingApprovalsUseCase(locator()));
  locator.registerLazySingleton<GetApprovedApprovalsUseCase>(
      () => GetApprovedApprovalsUseCase(locator()));
  locator.registerLazySingleton<GetRejectedApprovalsUseCase>(
      () => GetRejectedApprovalsUseCase(locator()));
  locator.registerLazySingleton<CreateApprovalUseCase>(
      () => CreateApprovalUseCase(locator()));
  locator.registerLazySingleton<ApprovalBloc>(() => ApprovalBloc());

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

  // Register Order Letter Document Dependencies
  locator.registerLazySingleton<OrderLetterDocumentRepository>(
      () => OrderLetterDocumentRepository(locator<Dio>()));
}
