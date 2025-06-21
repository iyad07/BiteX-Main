import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String userName;
  final String restaurantId;
  final String? foodId; // Optional, if review is for a specific food item
  final double rating;
  final String comment;
  final DateTime createdAt;
  final List<String>? images; // Optional, for photo reviews

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.restaurantId,
    this.foodId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.images,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      foodId: data['foodId'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      images: data['images'] != null ? List<String>.from(data['images']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'restaurantId': restaurantId,
      'foodId': foodId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'images': images,
    };
  }
}
