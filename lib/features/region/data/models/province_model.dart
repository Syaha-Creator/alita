import 'package:equatable/equatable.dart';

/// Model untuk data Provinsi dari API Wilayah Indonesia
class ProvinceModel extends Equatable {
  final String id;
  final String name;

  const ProvinceModel({
    required this.id,
    required this.name,
  });

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  String toString() => name;

  @override
  List<Object?> get props => [id, name];
}
