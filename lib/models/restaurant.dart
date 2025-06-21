import 'package:bikex/models/food.dart';

class Restaurant {
  final String id;
  final String restaurantName;
  final String restaurantImage;
  final int rating;
  final String deliveryTime;
  final bool isFreeDelivery;
  final String restaurantCategories;
  List<Food> foodList;

  Restaurant({
    String? id,
    required this.restaurantName,
    required this.restaurantImage,
    required this.rating,
    required this.deliveryTime,
    required this.isFreeDelivery,
    required this.restaurantCategories,
    List<Food>? foodList,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        foodList = foodList ?? [];

  void addFood(Food food) {
    foodList.add(food);
  }
  
  // Convert Restaurant to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': restaurantName,
      'image': restaurantImage,
      'rating': rating,
      'deliveryTime': deliveryTime,
      'isFreeDelivery': isFreeDelivery,
      'categories': restaurantCategories,
    };
  }
  
  // Create Restaurant from Map
  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'],
      restaurantName: map['name'],
      restaurantImage: map['image'],
      rating: map['rating'],
      deliveryTime: map['deliveryTime'],
      isFreeDelivery: map['isFreeDelivery'],
      restaurantCategories: map['categories'],
    );
  }
}
