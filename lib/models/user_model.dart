class AddressModel {
  final String? id;
  final String tag; // HOME, WORK, OTHER
  final String completeAddress;
  final double? lat;
  final double? lng;
  final String? landmark;
  final String receiverName;
  final String receiverPhone;

  AddressModel({
    this.id,
    required this.tag,
    required this.completeAddress,
    this.lat,
    this.lng,
    this.landmark,
    required this.receiverName,
    required this.receiverPhone,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id'],
      tag: json['tag'] ?? 'HOME',
      completeAddress: json['completeAddress'] ?? '',
      lat: json['lat'] != null ? (json['lat']).toDouble() : null,
      lng: json['lng'] != null ? (json['lng']).toDouble() : null,
      landmark: json['landmark'],
      receiverName: json['receiverName'] ?? '',
      receiverPhone: json['receiverPhone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'tag': tag,
      'completeAddress': completeAddress,
      'lat': lat,
      'lng': lng,
      'landmark': landmark,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
    };
  }
}

class UserModel {
  final String id;
  final String storeId;
  final String name;
  final String phone;
  final String? email;
  final double walletBalance;
  final List<AddressModel> addresses;

  UserModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.phone,
    this.email,
    required this.walletBalance,
    required this.addresses,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final addrList = (json['addresses'] as List<dynamic>?)
            ?.map((a) => AddressModel.fromJson(a))
            .toList() ??
        [];

    return UserModel(
      id: json['_id'] ?? '',
      storeId: json['storeId'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      walletBalance: (json['walletBalance'] ?? 0).toDouble(),
      addresses: addrList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'storeId': storeId,
      'name': name,
      'phone': phone,
      'email': email,
      'walletBalance': walletBalance,
      'addresses': addresses.map((a) => a.toJson()).toList(),
    };
  }
}
