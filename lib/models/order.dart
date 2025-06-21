import 'package:bikex/models/cart_item.dart';
import 'package:bikex/models/food.dart';
import 'package:bikex/models/restaurant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum OrderStatus {
  pending,
  preparing,
  ready,
  completed,
  cancelled,
}

class OrderModel {
  final String id;
  final Restaurant restaurant;
  final List<CartItem> items;
  final double totalPrice;
  final String deliveryAddress;
  final String customerName;
  final String customerPhone;
  final DateTime orderTime;
  OrderStatus status;
  String? notes;
  
  String get formattedOrderTime => DateFormat('MMM d, y - h:mm a').format(orderTime);
  
  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  OrderModel({
    String? id,
    required this.restaurant,
    required this.items,
    required this.totalPrice,
    required this.deliveryAddress,
    required this.customerName,
    required this.customerPhone,
    DateTime? orderTime,
    this.status = OrderStatus.pending,
    this.notes,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        orderTime = orderTime ?? DateTime.now();
        
  // Convert Order to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurantId': restaurant.id,
      'items': items.map((item) => {
        'foodId': item.food.id,
        'foodName': item.food.foodTitle,
        'quantity': item.quantity,
        'price': item.food.price,
      }).toList(),
      'totalPrice': totalPrice,
      'deliveryAddress': deliveryAddress,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'orderTime': orderTime.toIso8601String(),
      'status': status.toString().split('.').last,
      'notes': notes,
    };
  }
  
  // Create Order from Map
  factory OrderModel.fromMap(Map<String, dynamic> map, Restaurant restaurant) {
    return OrderModel(
      id: map['id'],
      restaurant: restaurant,
      items: (map['items'] as List).map((item) => CartItem(
        id: item['id'],
        food: Food(
          id: item['foodId'],
          foodTitle: item['foodName'],
          price: item['price'],
          restaurant: restaurant,
        ),
        quantity: item['quantity'],
        notes: item['notes'],
        isPrepared: item['isPrepared'] ?? false,
      )).toList(),
      totalPrice: map['totalPrice'] is int ? (map['totalPrice'] as int).toDouble() : map['totalPrice'],
      deliveryAddress: map['deliveryAddress'],
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      orderTime: map['orderTime'] is Timestamp 
          ? (map['orderTime'] as Timestamp).toDate() 
          : DateTime.parse(map['orderTime']),
      status: map['status'] is String 
          ? OrderStatus.values.firstWhere(
              (e) => e.toString() == 'OrderStatus.${map['status']}',
              orElse: () => OrderStatus.pending,
            )
          : OrderStatus.pending,
      notes: map['notes'],
    );
  }
  
  // Create a copy of the order with updated fields
  OrderModel copyWith({
    String? id,
    Restaurant? restaurant,
    List<CartItem>? items,
    double? totalPrice,
    String? deliveryAddress,
    String? customerName,
    String? customerPhone,
    DateTime? orderTime,
    OrderStatus? status,
    String? notes,
  }) {
    return OrderModel(
      id: id ?? this.id,
      restaurant: restaurant ?? this.restaurant,
      items: items ?? List.from(this.items),
      totalPrice: totalPrice ?? this.totalPrice,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      orderTime: orderTime ?? this.orderTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

