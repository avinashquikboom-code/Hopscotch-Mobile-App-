class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? address;
  final String? city;
  final String? zipCode;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.avatarUrl,
    this.address,
    this.city,
    this.zipCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? json['username'] ?? '').toString(),
      phoneNumber: json['phoneNumber'] as String? ??
          json['phone_number'] as String? ??
          json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String? ??
          json['avatar_url'] as String? ??
          json['avatar'] as String? ??
          json['profileImage'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      zipCode: json['zipCode'] as String? ?? json['zip_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'address': address,
      'city': city,
      'zipCode': zipCode,
    };
  }

  static List<UserModel> listFromJson(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map(UserModel.fromJson)
          .toList();
    }
    return [];
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? avatarUrl,
    String? address,
    String? city,
    String? zipCode,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is UserModel && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;
}
