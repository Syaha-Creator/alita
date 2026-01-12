import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';

import 'package:alitapricelist/features/product/data/repositories/area_repository.dart';
import 'package:alitapricelist/features/product/data/repositories/brand_repository.dart';
import 'package:alitapricelist/features/product/data/repositories/channel_repository.dart';
import 'package:alitapricelist/features/product/domain/usecases/get_product_usecase.dart';

/// Helper untuk setup test dependencies
///
/// Digunakan untuk integration tests yang memerlukan mock dependencies
@GenerateMocks([
  AreaRepository,
  ChannelRepository,
  BrandRepository,
  GetProductUseCase,
])
class TestSetup {
  static final GetIt testLocator = GetIt.instance;

  /// Setup mock dependencies untuk testing
  static void setupTestDependencies() {
    // Clear existing registrations
    if (testLocator.isRegistered<AreaRepository>()) {
      testLocator.unregister<AreaRepository>();
    }
    if (testLocator.isRegistered<ChannelRepository>()) {
      testLocator.unregister<ChannelRepository>();
    }
    if (testLocator.isRegistered<BrandRepository>()) {
      testLocator.unregister<BrandRepository>();
    }
    if (testLocator.isRegistered<GetProductUseCase>()) {
      testLocator.unregister<GetProductUseCase>();
    }
  }

  /// Cleanup test dependencies
  static void tearDownTestDependencies() {
    testLocator.reset();
  }
}
