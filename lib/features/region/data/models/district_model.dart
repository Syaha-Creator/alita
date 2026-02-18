import 'package:equatable/equatable.dart';

/// Model untuk data Kecamatan dari API Wilayah Indonesia
class DistrictModel extends Equatable {
  final String id;
  final String regencyId;
  final String name;

  const DistrictModel({
    required this.id,
    required this.regencyId,
    required this.name,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: json['id']?.toString() ?? '',
      regencyId: json['regency_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'regency_id': regencyId,
      'name': name,
    };
  }

  @override
  String toString() => name;

  @override
  List<Object?> get props => [id, regencyId, name];
}
