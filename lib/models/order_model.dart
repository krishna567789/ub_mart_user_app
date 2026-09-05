import 'user_model.dart';

class OrderItemModel {
  final String productId;
  final String name;
  final String variantSize;
  final int quantity;
  final double priceAtPurchase;
  final String? imageUrl;

  OrderItemModel({
    required this.productId,
    required this.name,
    required this.variantSize,
    required this.quantity,
    required this.priceAtPurchase,
    this.imageUrl,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    String pId = '';
    String pName = json['name'] ?? '';
    String? pImage = json['imageUrl'];

    if (json['product'] is Map) {
      pId = json['product']['_id'] ?? '';
      if (pName.isEmpty) pName = json['product']['name'] ?? '';
      if (pImage == null && json['product']['images'] is List && (json['product']['images'] as List).isNotEmpty) {
        pImage = json['product']['images'][0];
      }
    } else if (json['product'] is String) {
      pId = json['product'];
    }

    return OrderItemModel(
      productId: pId,
      name: pName,
      variantSize: json['variantSize'] ?? '',
      quantity: json['quantity'] ?? 1,
      priceAtPurchase: (json['priceAtPurchase'] ?? 0).toDouble(),
      imageUrl: pImage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': productId,
      'name': name,
      'variantSize': variantSize,
      'quantity': quantity,
      'priceAtPurchase': priceAtPurchase,
      'imageUrl': imageUrl,
    };
  }
}

class OrderModel {
  final String id;
  final String orderId;
  final String? userId;
  final String customerName;
  final String customerPhone;
  final AddressModel deliveryAddress;
  final List<OrderItemModel> items;
  final double itemTotal;
  final double deliveryFee;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String status; // PENDING, ACCEPTED, PACKING, OUT_FOR_DELIVERY, DELIVERED, CANCELLED
  final String paymentMethod; // COD, ONLINE, WALLET
  final String paymentStatus; // PENDING, PAID, FAILED
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.orderId,
    this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.itemTotal,
    required this.deliveryFee,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    String? uId;
    if (json['user'] is Map) {
      uId = json['user']['_id'];
    } else if (json['user'] is String) {
      uId = json['user'];
    }

    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((i) => OrderItemModel.fromJson(i))
            .toList() ??
        [];

    final addrJson = json['deliveryAddress'] is Map
        ? Map<String, dynamic>.from(json['deliveryAddress'])
        : <String, dynamic>{};

    return OrderModel(
      id: json['_id'] ?? '',
      orderId: json['orderId'] ?? '',
      userId: uId,
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      deliveryAddress: AddressModel.fromJson(addrJson),
      items: itemsList,
      itemTotal: (json['itemTotal'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      paymentMethod: json['paymentMethod'] ?? 'COD',
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'orderId': orderId,
      'user': userId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress.toJson(),
      'items': items.map((i) => i.toJson()).toList(),
      'itemTotal': itemTotal,
      'deliveryFee': deliveryFee,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
    };
  }
}
