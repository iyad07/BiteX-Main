import 'package:bikex/models/food.dart';

class CartItem {
  final String id;
  final Food food; // Reference to the food item
  int quantity;
  String? notes;
  bool isPrepared;
  
  CartItem({
    String? id,
    required this.food,
    required this.quantity,
    this.notes,
    this.isPrepared = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  
  // Create a copy of the cart item with updated fields
  CartItem copyWith({
    String? id,
    Food? food,
    int? quantity,
    String? notes,
    bool? isPrepared,
  }) {
    return CartItem(
      id: id ?? this.id,
      food: food ?? this.food,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      isPrepared: isPrepared ?? this.isPrepared,
    );
  }
  
  // Convert CartItem to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodId': food.id,
      'foodName': food.foodTitle,
      'price': food.price,
      'quantity': quantity,
      'notes': notes,
      'isPrepared': isPrepared,
    };
  }
  
  // Create CartItem from Map
  factory CartItem.fromMap(Map<String, dynamic> map, Food food) {
    return CartItem(
      id: map['id'],
      food: food,
      quantity: map['quantity'] ?? 1,
      notes: map['notes'],
      isPrepared: map['isPrepared'] ?? false,
    );
  }
  
  // Calculate the total price for this cart item
  int get totalPrice => food.price * quantity;
}