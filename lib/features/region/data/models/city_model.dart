import 'package:equatable/equatable.dart';

/// Model untuk data Kota/Kabupaten dari API Wilayah Indonesia
class CityModel extends Equatable {
  final String id;
  final String provinceId;
  final String name;

  const CityModel({
    required this.id,
    required this.provinceId,
    required this.name,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id']?.toString() ?? '',
      provinceId: json['province_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'province_id': provinceId,
      'name': name,
    };
  }

  @override
  String toString() => name;

  @override
  List<Object?> get props => [id, provinceId, name];
}
