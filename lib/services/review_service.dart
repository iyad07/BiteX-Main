import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikex/models/review.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a new review
  Future<void> addReview({
    required String restaurantId,
    String? foodId,
    required double rating,
    required String comment,
    List<String>? imageUrls,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User must be logged in to submit a review");
      }

      // Get user name from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? user.displayName ?? 'Anonymous';

      await _firestore.collection('reviews').add({
        'userId': user.uid,
        'userName': userName,
        'restaurantId': restaurantId,
        'foodId': foodId,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.now(),
        'images': imageUrls,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get reviews for a restaurant
  Stream<List<Review>> getRestaurantReviews(String restaurantId) {
    return _firestore
        .collection('reviews')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
    });
  }

  // Get reviews for a specific food item
  Stream<List<Review>> getFoodReviews(String foodId) {
    return _firestore
        .collection('reviews')
        .where('foodId', isEqualTo: foodId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
    });
  }

  // Get average rating for a restaurant
  Future<double> getRestaurantAverageRating(String restaurantId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();
    
    if (snapshot.docs.isEmpty) {
      return 0.0;
    }
    
    double totalRating = snapshot.docs.fold(
        0.0, (sum, doc) => sum + (doc.data()['rating'] ?? 0.0));
    
    return totalRating / snapshot.docs.length;
  }

  // Get user's reviews
  Stream<List<Review>> getUserReviews() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
    });
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Update a review
  Future<void> updateReview({
    required String reviewId,
    required double rating,
    required String comment,
    List<String>? imageUrls,
  }) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'rating': rating,
        'comment': comment,
        'images': imageUrls,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
