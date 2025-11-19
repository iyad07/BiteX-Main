import 'package:bikex/models/food.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class Restaurant {
  final String id;
  final String restaurantName;
  final String restaurantImage;
  final int rating;
  final String deliveryTime;
  final bool isFreeDelivery;
  final String restaurantCategories;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? phoneNumber;
  List<Food> foodList;

  Restaurant({
    String? id,
    required this.restaurantName,
    required this.restaurantImage,
    required this.rating,
    required this.deliveryTime,
    required this.isFreeDelivery,
    required this.restaurantCategories,
    this.latitude,
    this.longitude,
    this.address,
    this.phoneNumber,
    List<Food>? foodList,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        foodList = foodList ?? [];

  // Get LatLng for map usage
  LatLng? get location {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return null;
  }

  // Check if restaurant has valid location
  bool get hasLocation => latitude != null && longitude != null;

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
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'phoneNumber': phoneNumber,
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
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      address: map['address'],
      phoneNumber: map['phoneNumber'],
    );
  }

  // Calculate distance from a given location (in kilometers)
  double? distanceFrom(LatLng userLocation) {
    if (!hasLocation) return null;
    
    return calculateDistance(
      userLocation.latitude,
      userLocation.longitude,
      latitude!,
      longitude!,
    );
  }

  // Helper method to calculate distance using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
