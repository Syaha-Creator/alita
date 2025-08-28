class AreaModel {
  final int id;
  final String name;
  final String? code;
  final String? description;
  final bool? isActive;

  AreaModel({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.isActive,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['id'] ?? 0,
      name: json['area'] ?? '',
      code: json['code'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'is_active': isActive,
    };
  }

  @override
  String toString() {
    return 'AreaModel(id: $id, name: $name, code: $code, description: $description, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AreaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
