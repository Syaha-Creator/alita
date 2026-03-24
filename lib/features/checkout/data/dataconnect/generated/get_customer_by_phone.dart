// ignore_for_file: prefer_single_quotes
part of 'alita_connector.dart';

class GetCustomerByPhoneVariablesBuilder {
  GetCustomerByPhoneVariablesBuilder(
    this._dataConnect, {
    required this.phoneNumber,
  });

  String phoneNumber;
  final FirebaseDataConnect _dataConnect;

  Deserializer<GetCustomerByPhoneData> dataDeserializer =
      (dynamic json) => GetCustomerByPhoneData.fromJson(jsonDecode(json));

  Serializer<GetCustomerByPhoneVariables> varsSerializer =
      (GetCustomerByPhoneVariables vars) => jsonEncode(vars.toJson());

  Future<QueryResult<GetCustomerByPhoneData, GetCustomerByPhoneVariables>>
      execute() {
    return ref().execute();
  }

  QueryRef<GetCustomerByPhoneData, GetCustomerByPhoneVariables> ref() {
    final vars = GetCustomerByPhoneVariables(phoneNumber: phoneNumber);
    return _dataConnect.query(
      'GetCustomerByPhone',
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

class GetCustomerByPhoneCustomer {
  GetCustomerByPhoneCustomer({
    required this.phoneNumber,
    required this.name,
    this.email,
    this.region,
    this.address,
    this.provinsi,
    this.kota,
    this.kecamatan,
  });

  GetCustomerByPhoneCustomer.fromJson(dynamic json)
      : phoneNumber = nativeFromJson<String>(json['phoneNumber']),
        name = nativeFromJson<String>(json['name']),
        email = json['email'] == null
            ? null
            : nativeFromJson<String>(json['email']),
        region = json['region'] == null
            ? null
            : nativeFromJson<String>(json['region']),
        address = json['address'] == null
            ? null
            : nativeFromJson<String>(json['address']),
        provinsi = json['provinsi'] == null
            ? null
            : nativeFromJson<String>(json['provinsi']),
        kota = json['kota'] == null
            ? null
            : nativeFromJson<String>(json['kota']),
        kecamatan = json['kecamatan'] == null
            ? null
            : nativeFromJson<String>(json['kecamatan']);

  String phoneNumber;
  String name;
  String? email;
  String? region;
  String? address;
  String? provinsi;
  String? kota;
  String? kecamatan;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['phoneNumber'] = nativeToJson<String>(phoneNumber);
    json['name'] = nativeToJson<String>(name);
    if (email != null) json['email'] = nativeToJson<String?>(email);
    if (region != null) json['region'] = nativeToJson<String?>(region);
    if (address != null) json['address'] = nativeToJson<String?>(address);
    if (provinsi != null) json['provinsi'] = nativeToJson<String?>(provinsi);
    if (kota != null) json['kota'] = nativeToJson<String?>(kota);
    if (kecamatan != null) {
      json['kecamatan'] = nativeToJson<String?>(kecamatan);
    }
    return json;
  }
}

class GetCustomerByPhoneData {
  GetCustomerByPhoneData({this.customer});

  GetCustomerByPhoneData.fromJson(dynamic json)
      : customer = json['customer'] == null
            ? null
            : GetCustomerByPhoneCustomer.fromJson(json['customer']);

  GetCustomerByPhoneCustomer? customer;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (customer != null) json['customer'] = customer!.toJson();
    return json;
  }
}

class GetCustomerByPhoneVariables {
  GetCustomerByPhoneVariables({required this.phoneNumber});

  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetCustomerByPhoneVariables.fromJson(Map<String, dynamic> json)
      : phoneNumber = nativeFromJson<String>(json['phoneNumber']);

  String phoneNumber;

  Map<String, dynamic> toJson() => {
        'phoneNumber': nativeToJson<String>(phoneNumber),
      };
}
