class AddressModel {
  final String id;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String country;
  bool isDefault;
  String type; // home, work, other

  AddressModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
    this.isDefault = false,
    this.type = 'home',
  });

  AddressModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    String? country,
    bool? isDefault,
    String? type,
  }) {
    return AddressModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      type: type ?? this.type,
    );
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    final rawPhone = json['phone'] ??
        json['phoneNumber'] ??
        json['mobile'] ??
        json['mobileNo'] ??
        json['mobile_number'] ??
        json['contactPhone'] ??
        json['contactNumber'] ??
        json['phone_no'] ??
        json['contact'] ??
        '';

    return AddressModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? json['userName'] ?? '').toString(),
      phone: rawPhone.toString().trim(),
      addressLine1: (json['addressLine1'] ?? json['street'] ?? json['line1'] ?? json['address'] ?? '').toString(),
      addressLine2: (json['addressLine2'] ?? json['line2'] ?? json['area'] ?? json['landmark'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      pincode: (json['pincode'] ?? json['zipCode'] ?? json['zip'] ?? json['postalCode'] ?? '').toString(),
      country: (json['country'] ?? 'India').toString(),
      isDefault: json['isDefault'] as bool? ?? json['default'] as bool? ?? false,
      type: (json['type'] ?? 'home').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'name': fullName,
      'phone': phone,
      'phoneNumber': phone,
      'mobile': phone,
      'mobileNo': phone,
      'mobile_number': phone,
      'contactPhone': phone,
      'addressLine1': addressLine1,
      'line1': addressLine1,
      'street': addressLine1,
      'addressLine2': addressLine2,
      'line2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'zipCode': pincode,
      'country': country,
      'isDefault': isDefault,
      'type': type,
    };
  }

  String get fullAddress {
    return '$addressLine1, $addressLine2, $city, $state - $pincode, $country';
  }
}
