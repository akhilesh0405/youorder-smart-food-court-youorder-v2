import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuItemId: map['menuItemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
    );
  }
}

class Order {
  final String? id;
  final String restaurantId;
  final String userId;
  final String tableNumber;
  final List<OrderItem> items;
  final String status;
  final double totalPrice;
  final DateTime timestamp;
  final int? estimatedWaitTime;

  Order({
    this.id,
    required this.restaurantId,
    required this.userId,
    required this.tableNumber,
    required this.items,
    required this.status,
    required this.totalPrice,
    required this.timestamp,
    this.estimatedWaitTime,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'userId': userId,
      'tableNumber': tableNumber,
      'items': items.map((i) => i.toMap()).toList(),
      'status': status,
      'totalPrice': totalPrice,
      'timestamp': timestamp,
      'estimatedWaitTime': estimatedWaitTime,
    };
  }

  factory Order.fromFirestore(Map<String, dynamic> data, String id) {
    return Order(
      id: id,
      restaurantId: data['restaurantId'] ?? '',
      userId: data['userId'] ?? '',
      tableNumber: data['tableNumber'] ?? '',
      items: (data['items'] as List?)?.map((i) => OrderItem.fromMap(i)).toList() ?? [],
      status: data['status'] ?? 'pending',
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      estimatedWaitTime: data['estimatedWaitTime'],
    );
  }
}