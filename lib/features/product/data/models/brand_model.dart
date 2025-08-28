class BrandModel {
  final int id;
  final String name;
  final String? code;
  final String? description;
  final bool? isActive;

  BrandModel({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.isActive,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] ?? 0,
      name: json['brand'] ?? '', // API uses 'brand' field
      code: json['code'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': name, // API uses 'brand' field
      'code': code,
      'description': description,
      'is_active': isActive,
    };
  }

  @override
  String toString() {
    return 'BrandModel(id: $id, name: $name, code: $code, description: $description, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BrandModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
