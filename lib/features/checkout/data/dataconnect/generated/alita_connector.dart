// ignore_for_file: unnecessary_library_name
library alita_connector_generated;

import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'dart:convert';

part 'upsert_customer.dart';
part 'get_customer_by_phone.dart';

class AlitaConnectorConnector {
  AlitaConnectorConnector({required this.dataConnect});

  UpsertCustomerVariablesBuilder upsertCustomer({
    required String phoneNumber,
    required String name,
  }) {
    return UpsertCustomerVariablesBuilder(
      dataConnect,
      phoneNumber: phoneNumber,
      name: name,
    );
  }

  GetCustomerByPhoneVariablesBuilder getCustomerByPhone({
    required String phoneNumber,
  }) {
    return GetCustomerByPhoneVariablesBuilder(
      dataConnect,
      phoneNumber: phoneNumber,
    );
  }

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-southeast1',
    'alita-connector',
    'alita-service',
  );

  static AlitaConnectorConnector get instance {
    return AlitaConnectorConnector(
      dataConnect: FirebaseDataConnect.instanceFor(
        connectorConfig: connectorConfig,
        sdkType: CallerSDKType.generated,
      ),
    );
  }

  FirebaseDataConnect dataConnect;
}
