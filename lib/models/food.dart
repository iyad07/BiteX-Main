import 'package:bikex/models/restaurant.dart';

class Food {
  final String id;
  final String foodTitle;
  final String? foodImage;
  final int price;
  final Restaurant? restaurant; // Reference to the parent Restaurant
  final String? description;
  final List<String>? ingredients;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final int preparationTime; // in minutes

  Food({
    String? id,
    required this.foodTitle,
    this.foodImage,
    required this.price,
    this.restaurant,
    this.description,
    this.ingredients,
    this.isVegetarian = false,
    this.isVegan = false,
    this.isGlutenFree = false,
    this.preparationTime = 15, // default 15 minutes
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Convert Food to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': foodTitle,
      'image': foodImage,
      'price': price,
      'restaurantId': restaurant?.id,
      'description': description,
      'ingredients': ingredients,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
      'preparationTime': preparationTime,
    };
  }

  // Create Food from Map
  factory Food.fromMap(Map<String, dynamic> map, {Restaurant? restaurant}) {
    return Food(
      id: map['id'],
      foodTitle: map['title'],
      foodImage: map['image'],
      price: map['price'],
      restaurant: restaurant,
      description: map['description'],
      ingredients: map['ingredients'] != null ? List<String>.from(map['ingredients']) : null,
      isVegetarian: map['isVegetarian'] ?? false,
      isVegan: map['isVegan'] ?? false,
      isGlutenFree: map['isGlutenFree'] ?? false,
      preparationTime: map['preparationTime'] ?? 15,
    );
  }
  
  // Create a copy of the food item with updated fields
  Food copyWith({
    String? id,
    String? foodTitle,
    String? foodImage,
    int? price,
    Restaurant? restaurant,
    String? description,
    List<String>? ingredients,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    int? preparationTime,
  }) {
    return Food(
      id: id ?? this.id,
      foodTitle: foodTitle ?? this.foodTitle,
      foodImage: foodImage ?? this.foodImage,
      price: price ?? this.price,
      restaurant: restaurant ?? this.restaurant,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
      preparationTime: preparationTime ?? this.preparationTime,
    );
  }
}