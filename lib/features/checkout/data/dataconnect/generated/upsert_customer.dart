// ignore_for_file: non_constant_identifier_names, prefer_single_quotes, prefer_final_fields
part of 'alita_connector.dart';

class UpsertCustomerVariablesBuilder {
  UpsertCustomerVariablesBuilder(
    this._dataConnect, {
    required this.phoneNumber,
    required this.name,
  });

  String phoneNumber;
  String name;
  Optional<String> _email = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _region = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _address = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _provinsi = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _kota = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _kecamatan = Optional.optional(nativeFromJson, nativeToJson);
  final FirebaseDataConnect _dataConnect;

  UpsertCustomerVariablesBuilder email(String? t) {
    _email.value = t;
    return this;
  }

  UpsertCustomerVariablesBuilder region(String? t) {
    _region.value = t;
    return this;
  }

  UpsertCustomerVariablesBuilder address(String? t) {
    _address.value = t;
    return this;
  }

  UpsertCustomerVariablesBuilder provinsi(String? t) {
    _provinsi.value = t;
    return this;
  }

  UpsertCustomerVariablesBuilder kota(String? t) {
    _kota.value = t;
    return this;
  }

  UpsertCustomerVariablesBuilder kecamatan(String? t) {
    _kecamatan.value = t;
    return this;
  }

  Deserializer<UpsertCustomerData> dataDeserializer =
      (dynamic json) => UpsertCustomerData.fromJson(jsonDecode(json));

  Serializer<UpsertCustomerVariables> varsSerializer =
      (UpsertCustomerVariables vars) => jsonEncode(vars.toJson());

  Future<OperationResult<UpsertCustomerData, UpsertCustomerVariables>>
      execute() {
    return ref().execute();
  }

  MutationRef<UpsertCustomerData, UpsertCustomerVariables> ref() {
    final vars = UpsertCustomerVariables(
      phoneNumber: phoneNumber,
      name: name,
      email: _email,
      region: _region,
      address: _address,
      provinsi: _provinsi,
      kota: _kota,
      kecamatan: _kecamatan,
    );
    return _dataConnect.mutation(
      "UpsertCustomer",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

class UpsertCustomerCustomerUpsert {
  UpsertCustomerCustomerUpsert({required this.phoneNumber});

  UpsertCustomerCustomerUpsert.fromJson(dynamic json)
      : phoneNumber = nativeFromJson<String>(json['phoneNumber']);

  String phoneNumber;

  Map<String, dynamic> toJson() => {
        'phoneNumber': nativeToJson<String>(phoneNumber),
      };
}

class UpsertCustomerData {
  UpsertCustomerData({required this.customer_upsert});

  UpsertCustomerData.fromJson(dynamic json)
      : customer_upsert = UpsertCustomerCustomerUpsert.fromJson(
          json['customer_upsert'],
        );

  UpsertCustomerCustomerUpsert customer_upsert;

  Map<String, dynamic> toJson() => {
        'customer_upsert': customer_upsert.toJson(),
      };
}

class UpsertCustomerVariables {
  UpsertCustomerVariables({
    required this.phoneNumber,
    required this.name,
    required this.email,
    required this.region,
    required this.address,
    required this.provinsi,
    required this.kota,
    required this.kecamatan,
  });

  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  UpsertCustomerVariables.fromJson(Map<String, dynamic> json)
      : phoneNumber = nativeFromJson<String>(json['phoneNumber']),
        name = nativeFromJson<String>(json['name']) {
    email = Optional.optional(nativeFromJson, nativeToJson);
    email.value = json['email'] == null
        ? null
        : nativeFromJson<String>(json['email']);
    region = Optional.optional(nativeFromJson, nativeToJson);
    region.value = json['region'] == null
        ? null
        : nativeFromJson<String>(json['region']);
    address = Optional.optional(nativeFromJson, nativeToJson);
    address.value = json['address'] == null
        ? null
        : nativeFromJson<String>(json['address']);
    provinsi = Optional.optional(nativeFromJson, nativeToJson);
    provinsi.value = json['provinsi'] == null
        ? null
        : nativeFromJson<String>(json['provinsi']);
    kota = Optional.optional(nativeFromJson, nativeToJson);
    kota.value = json['kota'] == null
        ? null
        : nativeFromJson<String>(json['kota']);
    kecamatan = Optional.optional(nativeFromJson, nativeToJson);
    kecamatan.value = json['kecamatan'] == null
        ? null
        : nativeFromJson<String>(json['kecamatan']);
  }

  String phoneNumber;
  String name;
  late Optional<String> email;
  late Optional<String> region;
  late Optional<String> address;
  late Optional<String> provinsi;
  late Optional<String> kota;
  late Optional<String> kecamatan;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['phoneNumber'] = nativeToJson<String>(phoneNumber);
    json['name'] = nativeToJson<String>(name);
    if (email.state == OptionalState.set) json['email'] = email.toJson();
    if (region.state == OptionalState.set) json['region'] = region.toJson();
    if (address.state == OptionalState.set) {
      json['address'] = address.toJson();
    }
    if (provinsi.state == OptionalState.set) {
      json['provinsi'] = provinsi.toJson();
    }
    if (kota.state == OptionalState.set) json['kota'] = kota.toJson();
    if (kecamatan.state == OptionalState.set) {
      json['kecamatan'] = kecamatan.toJson();
    }
    return json;
  }
}
