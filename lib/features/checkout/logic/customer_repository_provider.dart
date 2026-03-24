import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});
