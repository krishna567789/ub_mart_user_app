class StoreModel {
  final String id;
  final String name;
  final String ownerName;
  final String phone;
  final String status;
  final String plan;

  StoreModel({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.phone,
    required this.status,
    required this.plan,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      ownerName: json['ownerName'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      plan: json['plan'] ?? 'BASIC',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'ownerName': ownerName,
      'phone': phone,
      'status': status,
      'plan': plan,
    };
  }
}
