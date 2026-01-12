import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../features/product/data/repositories/product_repository.dart';
import '../features/product/data/repositories/area_repository.dart';
import '../features/product/data/repositories/channel_repository.dart';
import '../features/product/data/repositories/brand_repository.dart';
import '../features/product/data/repositories/item_lookup_repository.dart';
import '../features/product/data/datasources/brand_remote_data_source.dart';
import '../features/product/data/datasources/channel_remote_data_source.dart';
import '../features/product/data/datasources/area_remote_data_source.dart';
import '../features/product/data/datasources/product_remote_data_source.dart';
import '../features/product/data/datasources/item_lookup_remote_data_source.dart';
import '../features/product/domain/repositories/item_lookup_repository.dart';
import '../features/product/domain/usecases/get_product_usecase.dart';
import '../features/product/domain/usecases/get_item_lookup_usecase.dart';
import '../features/product/domain/usecases/fetch_lookup_items_usecase.dart';
import '../features/product/presentation/bloc/product_bloc.dart';
import '../services/api_client.dart';
import '../services/area_service.dart';
import '../services/channel_service.dart';
import '../services/brand_service.dart';
import '../core/utils/area_utils.dart';
import '../services/cart_storage_service.dart';
import '../services/order_letter_service.dart';
import '../services/checkout_service.dart';
import '../services/contact_work_experience_service.dart';
import '../services/leader_service.dart';
import '../services/team_hierarchy_service.dart';
import '../features/approval/data/repositories/approval_repository.dart';
import '../features/approval/data/datasources/approval_remote_data_source.dart';
import '../features/approval/data/datasources/approval_local_data_source.dart';
import '../features/approval/domain/usecases/get_approvals_usecase.dart';
import '../features/approval/domain/usecases/create_approval_usecase.dart';
import '../features/approval/presentation/bloc/approval_bloc.dart';
import '../features/authentication/data/repositories/auth_repository.dart';
import '../features/authentication/data/datasources/auth_remote_data_source.dart';
import '../features/authentication/data/datasources/auth_local_data_source.dart';
import '../features/authentication/domain/usecases/login_usecase.dart';
import '../features/authentication/presentation/bloc/auth_bloc.dart';
import '../features/order_letter_document/data/repositories/order_letter_document_repository.dart';
import '../features/order_letter_document/data/datasources/order_letter_document_remote_data_source.dart';
import '../features/order_letter_contact/data/datasources/order_letter_contact_remote_data_source.dart';
import '../features/order_letter_contact/data/repositories/order_letter_contact_repository_impl.dart';
import '../features/order_letter_contact/domain/repositories/order_letter_contact_repository.dart';
import '../features/order_letter_contact/domain/usecases/create_phone_contact_usecase.dart';
import '../features/order_letter_contact/domain/usecases/upload_phone_numbers_usecase.dart';
import '../features/order_letter_payment/data/datasources/order_letter_payment_remote_data_source.dart';
import '../features/order_letter_payment/data/repositories/order_letter_payment_repository_impl.dart';
import '../features/order_letter_payment/domain/repositories/order_letter_payment_repository.dart';
import '../features/order_letter_payment/domain/usecases/create_payment_usecase.dart';
import '../features/order_letter_payment/domain/usecases/upload_payment_methods_usecase.dart';
import '../features/item_mapping/data/repositories/item_mapping_repository_impl.dart';
import '../features/item_mapping/domain/repositories/item_mapping_repository.dart';
import '../features/item_mapping/domain/usecases/find_item_by_type_usecase.dart';
import '../features/item_mapping/domain/usecases/get_item_number_by_type_usecase.dart';
import '../features/item_mapping/domain/usecases/map_product_items_usecase.dart';
import '../features/item_mapping/domain/usecases/map_checkout_items_usecase.dart';
import 'api_config.dart';
import '../services/device_token_service.dart';
import '../services/product_options_service.dart';
import '../services/item_mapping_service.dart';
import '../services/enhanced_checkout_service.dart';
import '../services/order_letter_contact_service.dart';
import '../services/order_letter_payment_service.dart';
import '../services/attendance_service.dart';
import '../services/app_update_service.dart';
import '../core/constants/timeouts.dart';
import '../features/cart/data/repositories/checkout_repository_impl.dart';
import '../features/cart/data/repositories/cart_repository_impl.dart';
import '../features/cart/data/datasources/cart_local_data_source.dart';
import '../features/cart/domain/repositories/checkout_repository.dart';
import '../features/cart/domain/repositories/cart_repository.dart';
import '../features/cart/domain/usecases/checkout_usecase.dart';
import '../features/cart/domain/usecases/save_draft_usecase.dart';
import '../features/cart/domain/usecases/should_upload_item_usecase.dart';
import '../features/cart/domain/usecases/should_upload_bonus_usecase.dart';
import '../features/cart/domain/usecases/resolve_item_info_usecase.dart';
import '../features/cart/domain/usecases/resolve_item_info_per_unit_usecase.dart';
import '../features/cart/domain/usecases/resolve_bonus_item_info_usecase.dart';
import '../features/cart/domain/usecases/get_primary_item_name_usecase.dart';
import '../features/cart/domain/usecases/determine_order_status_usecase.dart';
import '../features/cart/domain/usecases/calculate_cart_totals_usecase.dart';
import '../features/cart/domain/usecases/prepare_order_letter_data_usecase.dart';
import '../features/cart/domain/usecases/prepare_order_letter_details_usecase.dart';
import '../features/cart/domain/usecases/get_leader_ids_from_cart_usecase.dart';
import '../features/order_letter/domain/usecases/create_order_letter_with_details_usecase.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<Dio>(() {
    final options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiTimeouts.standardConnectTimeout,
      receiveTimeout: ApiTimeouts.standardReceiveTimeout,
      headers: {'Accept': 'application/json'},
    );
    return Dio(options);
  });

  // Register Services
  locator.registerLazySingleton<ApiClient>(() => ApiClient());
  locator.registerLazySingleton<AreaService>(
    () => AreaService(apiClient: locator<ApiClient>()),
  );
  locator.registerLazySingleton<ChannelService>(
    () => ChannelService(apiClient: locator<ApiClient>()),
  );
  locator.registerLazySingleton<BrandService>(
    () => BrandService(apiClient: locator<ApiClient>()),
  );
  // Register Cart Dependencies
  // Register Cart Data Source (lazy-initialize SharedPreferences)
  locator.registerLazySingleton<CartLocalDataSource>(
    () => CartLocalDataSourceImpl(),
  );

  // Register Cart Repository
  locator.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(
      localDataSource: locator<CartLocalDataSource>(),
    ),
  );

  // Keep CartStorageService for backward compatibility (wrapper)
  locator.registerLazySingleton<CartStorageService>(() => CartStorageService());
  locator.registerLazySingleton<OrderLetterService>(
    () => OrderLetterService(locator<Dio>()),
  );
  locator.registerLazySingleton<OrderLetterContactService>(
    () => OrderLetterContactService(locator<Dio>()),
  );
  locator.registerLazySingleton<OrderLetterPaymentService>(
    () => OrderLetterPaymentService(locator<Dio>()),
  );
  locator.registerLazySingleton<AttendanceService>(
    () => AttendanceService(locator<Dio>()),
  );
  locator.registerLazySingleton<AppUpdateService>(
    () => AppUpdateService(),
  );
  // Register Checkout Helper Use Cases
  locator.registerLazySingleton<ShouldUploadItemUseCase>(
    () => ShouldUploadItemUseCase(),
  );
  locator.registerLazySingleton<ShouldUploadBonusUseCase>(
    () => ShouldUploadBonusUseCase(),
  );
  locator.registerLazySingleton<ResolveItemInfoUseCase>(
    () => ResolveItemInfoUseCase(),
  );
  locator.registerLazySingleton<ResolveItemInfoPerUnitUseCase>(
    () => ResolveItemInfoPerUnitUseCase(
      locator<ResolveItemInfoUseCase>(),
    ),
  );
  locator.registerLazySingleton<ResolveBonusItemInfoUseCase>(
    () => ResolveBonusItemInfoUseCase(),
  );
  locator.registerLazySingleton<GetPrimaryItemNameUseCase>(
    () => GetPrimaryItemNameUseCase(
      locator<ShouldUploadItemUseCase>(),
    ),
  );
  locator.registerLazySingleton<DetermineOrderStatusUseCase>(
    () => DetermineOrderStatusUseCase(),
  );
  locator.registerLazySingleton<CalculateCartTotalsUseCase>(
    () => CalculateCartTotalsUseCase(),
  );
  locator.registerLazySingleton<PrepareOrderLetterDataUseCase>(
    () => PrepareOrderLetterDataUseCase(),
  );
  locator.registerLazySingleton<PrepareOrderLetterDetailsUseCase>(
    () => PrepareOrderLetterDetailsUseCase(),
  );
  locator.registerLazySingleton<GetLeaderIdsFromCartUseCase>(
    () => GetLeaderIdsFromCartUseCase(),
  );

  // Register Order Letter Use Cases
  locator.registerLazySingleton<CreateOrderLetterWithDetailsUseCase>(
    () => CreateOrderLetterWithDetailsUseCase(
      locator<OrderLetterService>(),
    ),
  );

  // Register CheckoutService with use cases
  locator.registerLazySingleton<CheckoutService>(
    () => CheckoutService(
      calculateCartTotalsUseCase: locator<CalculateCartTotalsUseCase>(),
      prepareOrderLetterDataUseCase: locator<PrepareOrderLetterDataUseCase>(),
      prepareOrderLetterDetailsUseCase:
          locator<PrepareOrderLetterDetailsUseCase>(),
      getLeaderIdsFromCartUseCase: locator<GetLeaderIdsFromCartUseCase>(),
    ),
  );
  locator.registerLazySingleton<ContactWorkExperienceService>(
    () => ContactWorkExperienceService(locator<ApiClient>()),
  );
  locator.registerLazySingleton<LeaderService>(
    () => LeaderService(locator<ApiClient>()),
  );
  locator.registerLazySingleton<TeamHierarchyService>(
    () => TeamHierarchyService(locator<ApiClient>()),
  );
  locator.registerLazySingleton<DeviceTokenService>(
    () => DeviceTokenService(),
  );
  locator.registerLazySingleton<ProductOptionsService>(
    () => ProductOptionsService(apiClient: locator<ApiClient>()),
  );
  // Register Item Mapping Dependencies
  // Register Item Mapping Repository
  locator.registerLazySingleton<ItemMappingRepository>(
    () => ItemMappingRepositoryImpl(
      getItemLookupUsecase: locator<GetItemLookupUsecase>(),
    ),
  );

  // Register Item Mapping Use Cases
  locator.registerLazySingleton<FindItemByTypeUseCase>(
    () => FindItemByTypeUseCase(
      locator<ItemMappingRepository>(),
    ),
  );
  locator.registerLazySingleton<GetItemNumberByTypeUseCase>(
    () => GetItemNumberByTypeUseCase(
      locator<ItemMappingRepository>(),
    ),
  );
  locator.registerLazySingleton<MapProductItemsUseCase>(
    () => MapProductItemsUseCase(
      locator<ItemMappingRepository>(),
    ),
  );
  locator.registerLazySingleton<MapCheckoutItemsUseCase>(
    () => MapCheckoutItemsUseCase(
      locator<ItemMappingRepository>(),
    ),
  );

  // Keep ItemMappingService for backward compatibility (wrapper)
  locator.registerLazySingleton<ItemMappingService>(
    () => ItemMappingService(
        getItemLookupUsecase: locator<GetItemLookupUsecase>()),
  );
  locator.registerLazySingleton<EnhancedCheckoutService>(
    () => EnhancedCheckoutService(
      checkoutService: locator<CheckoutService>(),
      mapCheckoutItemsUseCase: locator<MapCheckoutItemsUseCase>(),
    ),
  );

  // Register Approval Dependencies
  // Register Approval Data Sources
  locator.registerLazySingleton<ApprovalRemoteDataSource>(
    () => ApprovalRemoteDataSourceImpl(
      orderLetterService: locator<OrderLetterService>(),
    ),
  );
  locator.registerLazySingleton<ApprovalLocalDataSource>(
    () => ApprovalLocalDataSourceImpl(),
  );

  // Register Approval Repository
  locator.registerLazySingleton<ApprovalRepository>(
    () => ApprovalRepository(
      remoteDataSource: locator<ApprovalRemoteDataSource>(),
      localDataSource: locator<ApprovalLocalDataSource>(),
    ),
  );
  locator.registerLazySingleton<GetApprovalsUseCase>(
    () => GetApprovalsUseCase(locator()),
  );
  locator.registerLazySingleton<GetApprovalByIdUseCase>(
    () => GetApprovalByIdUseCase(locator()),
  );
  locator.registerLazySingleton<GetPendingApprovalsUseCase>(
    () => GetPendingApprovalsUseCase(locator()),
  );
  locator.registerLazySingleton<GetApprovedApprovalsUseCase>(
    () => GetApprovedApprovalsUseCase(locator()),
  );
  locator.registerLazySingleton<GetRejectedApprovalsUseCase>(
    () => GetRejectedApprovalsUseCase(locator()),
  );
  locator.registerLazySingleton<CreateApprovalUseCase>(
    () => CreateApprovalUseCase(locator()),
  );
  locator.registerLazySingleton<ApprovalBloc>(
    () => ApprovalBloc(
      getApprovalsUseCase: locator<GetApprovalsUseCase>(),
      getApprovalByIdUseCase: locator<GetApprovalByIdUseCase>(),
      getPendingApprovalsUseCase: locator<GetPendingApprovalsUseCase>(),
      getApprovedApprovalsUseCase: locator<GetApprovedApprovalsUseCase>(),
      getRejectedApprovalsUseCase: locator<GetRejectedApprovalsUseCase>(),
      createApprovalUseCase: locator<CreateApprovalUseCase>(),
      approvalRepository: locator<ApprovalRepository>(),
    ),
  );

  // Register Auth Dependencies
  // Register Auth Data Sources
  locator.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: locator<ApiClient>()),
  );

  // Note: AuthLocalDataSource requires SharedPreferences which is async
  // We'll initialize it lazily when first accessed
  // For now, AuthService static methods will continue to work as wrapper

  // Register Auth Repository
  // AuthLocalDataSource will lazy-initialize SharedPreferences when first accessed
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      remoteDataSource: locator<AuthRemoteDataSource>(),
      localDataSource: AuthLocalDataSourceImpl(),
    ),
  );
  locator.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      loginUseCase: locator<LoginUseCase>(),
      authRepository: locator<AuthRepository>(),
    ),
  );

  // Register Product Dependencies
  // Register Product Data Sources
  locator.registerLazySingleton<BrandRemoteDataSource>(
    () => BrandRemoteDataSourceImpl(apiClient: locator<ApiClient>()),
  );
  locator.registerLazySingleton<ChannelRemoteDataSource>(
    () => ChannelRemoteDataSourceImpl(apiClient: locator<ApiClient>()),
  );
  locator.registerLazySingleton<AreaRemoteDataSource>(
    () => AreaRemoteDataSourceImpl(apiClient: locator<ApiClient>()),
  );
  locator.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(apiClient: locator<ApiClient>()),
  );
  locator.registerLazySingleton<ItemLookupRemoteDataSource>(
    () => ItemLookupRemoteDataSourceImpl(apiClient: locator<ApiClient>()),
  );

  // Register Product Repositories
  locator.registerLazySingleton<ProductRepository>(
    () =>
        ProductRepository(remoteDataSource: locator<ProductRemoteDataSource>()),
  );
  locator.registerLazySingleton<AreaRepository>(
    () => AreaRepository(remoteDataSource: locator<AreaRemoteDataSource>()),
  );
  locator.registerLazySingleton<ChannelRepository>(
    () =>
        ChannelRepository(remoteDataSource: locator<ChannelRemoteDataSource>()),
  );
  locator.registerLazySingleton<BrandRepository>(
    () => BrandRepository(remoteDataSource: locator<BrandRemoteDataSource>()),
  );
  locator.registerLazySingleton<ItemLookupRepositoryImpl>(
    () => ItemLookupRepositoryImpl(
      remoteDataSource: locator<ItemLookupRemoteDataSource>(),
    ),
  );
  // Register ItemLookupRepository as interface (using impl)
  locator.registerLazySingleton<ItemLookupRepository>(
    () => locator<ItemLookupRepositoryImpl>(),
  );
  // Register ItemLookup Use Cases
  locator.registerLazySingleton<FetchLookupItemsUseCase>(
    () => FetchLookupItemsUseCase(
      locator<ItemLookupRepository>(),
    ),
  );
  locator.registerLazySingleton<AreaUtils>(
    () => AreaUtils(areaRepository: locator<AreaRepository>()),
  );
  locator.registerLazySingleton<GetProductUseCase>(
    () => GetProductUseCase(locator<ProductRepository>()),
  );
  locator.registerLazySingleton<GetItemLookupUsecase>(
    () => GetItemLookupUsecase(repository: locator<ItemLookupRepositoryImpl>()),
  );
  locator.registerLazySingleton<ProductBloc>(
    () => ProductBloc(
      getProductUseCase: locator<GetProductUseCase>(),
      areaRepository: locator<AreaRepository>(),
      channelRepository: locator<ChannelRepository>(),
      brandRepository: locator<BrandRepository>(),
    ),
  );

  // Register Order Letter Document Dependencies
  // Register Order Letter Document Data Source
  locator.registerLazySingleton<OrderLetterDocumentRemoteDataSource>(
    () => OrderLetterDocumentRemoteDataSourceImpl(dio: locator<Dio>()),
  );

  // Register Order Letter Document Repository
  locator.registerLazySingleton<OrderLetterDocumentRepository>(
    () => OrderLetterDocumentRepository(
      remoteDataSource: locator<OrderLetterDocumentRemoteDataSource>(),
    ),
  );

  // Register Order Letter Contact Dependencies
  // Register Order Letter Contact Data Source
  locator.registerLazySingleton<OrderLetterContactRemoteDataSource>(
    () => OrderLetterContactRemoteDataSourceImpl(dio: locator<Dio>()),
  );

  // Register Order Letter Contact Repository
  locator.registerLazySingleton<OrderLetterContactRepository>(
    () => OrderLetterContactRepositoryImpl(
      remoteDataSource: locator<OrderLetterContactRemoteDataSource>(),
    ),
  );

  // Register Order Letter Contact Use Cases
  locator.registerLazySingleton<CreatePhoneContactUseCase>(
    () => CreatePhoneContactUseCase(
      locator<OrderLetterContactRepository>(),
    ),
  );
  locator.registerLazySingleton<UploadPhoneNumbersUseCase>(
    () => UploadPhoneNumbersUseCase(
      locator<OrderLetterContactRepository>(),
    ),
  );

  // Register Order Letter Payment Dependencies
  // Register Order Letter Payment Data Source
  locator.registerLazySingleton<OrderLetterPaymentRemoteDataSource>(
    () => OrderLetterPaymentRemoteDataSourceImpl(dio: locator<Dio>()),
  );

  // Register Order Letter Payment Repository
  locator.registerLazySingleton<OrderLetterPaymentRepository>(
    () => OrderLetterPaymentRepositoryImpl(
      remoteDataSource: locator<OrderLetterPaymentRemoteDataSource>(),
    ),
  );

  // Register Order Letter Payment Use Cases
  locator.registerLazySingleton<CreatePaymentUseCase>(
    () => CreatePaymentUseCase(
      locator<OrderLetterPaymentRepository>(),
    ),
  );
  locator.registerLazySingleton<UploadPaymentMethodsUseCase>(
    () => UploadPaymentMethodsUseCase(
      locator<OrderLetterPaymentRepository>(),
    ),
  );

  // Register Cart/Checkout Dependencies
  locator.registerLazySingleton<CheckoutRepositoryImpl>(
    () => CheckoutRepositoryImpl(
      enhancedCheckoutService: locator<EnhancedCheckoutService>(),
      uploadPhoneNumbersUseCase: locator<UploadPhoneNumbersUseCase>(),
      uploadPaymentMethodsUseCase: locator<UploadPaymentMethodsUseCase>(),
    ),
  );
  locator.registerLazySingleton<CheckoutRepository>(
    () => locator<CheckoutRepositoryImpl>(),
  );
  locator.registerLazySingleton<CheckoutUseCase>(
    () => CheckoutUseCase(repository: locator<CheckoutRepository>()),
  );
  locator.registerLazySingleton<SaveDraftUseCase>(
    () => SaveDraftUseCase(repository: locator<CheckoutRepository>()),
  );
}
