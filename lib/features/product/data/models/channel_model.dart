class ChannelModel {
  final int id;
  final String name;
  final String? code;
  final String? description;
  final bool? isActive;

  ChannelModel({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.isActive,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: json['id'] ?? 0,
      name: json['channel'] ?? '', // API uses 'channel' field
      code: json['code'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel': name, // API uses 'channel' field
      'code': code,
      'description': description,
      'is_active': isActive,
    };
  }

  @override
  String toString() {
    return 'ChannelModel(id: $id, name: $name, code: $code, description: $description, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChannelModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
