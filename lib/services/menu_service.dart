import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:bikex/models/menu_item.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get restaurant ID for current chef
  Future<String?> getChefRestaurantId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final chefDoc = await _firestore.collection('chefs').doc(user.uid).get();
      
      if (!chefDoc.exists) {
        throw Exception('Chef profile not found');
      }
      
      return chefDoc.data()?['restaurantId'];
    } catch (e) {
      rethrow;
    }
  }

  // Upload menu item image
  Future<String> uploadMenuItemImage(File imageFile, String restaurantId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final destination = 'restaurants/$restaurantId/menu_items/$fileName';
      
      final ref = _storage.ref(destination);
      await ref.putFile(imageFile);
      
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Add new menu item
  Future<String> addMenuItem({
    required String name,
    required String description,
    required double price,
    required String category,
    required File imageFile,
    String? restaurantId,
    List<String>? allergens,
    Map<String, dynamic>? nutritionalInfo,
    List<String>? tags,
    Map<String, dynamic>? customizationOptions,
    double? discountPercentage,
    bool isFeatured = false,
  }) async {
    try {
      // Get the restaurant ID if not provided
      final String restId = restaurantId ?? await getChefRestaurantId() ?? '';
      
      if (restId.isEmpty) {
        throw Exception('Restaurant ID is required');
      }
      
      // Upload the image
      final imageUrl = await uploadMenuItemImage(imageFile, restId);
      
      // Create the menu item document
      final docRef = await _firestore.collection('menu_items').add({
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'restaurantId': restId,
        'imageUrl': imageUrl,
        'isAvailable': true,
        'isFeatured': isFeatured,
        'allergens': allergens,
        'nutritionalInfo': nutritionalInfo,
        'tags': tags,
        'customizationOptions': customizationOptions,
        'discountPercentage': discountPercentage,
        'createdAt': Timestamp.now(),
      });
      
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Update existing menu item
  Future<void> updateMenuItem({
    required String itemId,
    String? name,
    String? description,
    double? price,
    String? category,
    File? imageFile,
    bool? isAvailable,
    bool? isFeatured,
    List<String>? allergens,
    Map<String, dynamic>? nutritionalInfo,
    List<String>? tags,
    Map<String, dynamic>? customizationOptions,
    double? discountPercentage,
  }) async {
    try {
      // Get the current menu item
      final itemDoc = await _firestore.collection('menu_items').doc(itemId).get();
      
      if (!itemDoc.exists) {
        throw Exception('Menu item not found');
      }
      
      final data = itemDoc.data()!;
      final String restaurantId = data['restaurantId'];
      
      // Prepare the update data
      final Map<String, dynamic> updateData = {};
      
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (category != null) updateData['category'] = category;
      if (isAvailable != null) updateData['isAvailable'] = isAvailable;
      if (isFeatured != null) updateData['isFeatured'] = isFeatured;
      if (allergens != null) updateData['allergens'] = allergens;
      if (nutritionalInfo != null) updateData['nutritionalInfo'] = nutritionalInfo;
      if (tags != null) updateData['tags'] = tags;
      if (customizationOptions != null) updateData['customizationOptions'] = customizationOptions;
      if (discountPercentage != null) updateData['discountPercentage'] = discountPercentage;
      
      // If a new image was provided, upload it
      if (imageFile != null) {
        final imageUrl = await uploadMenuItemImage(imageFile, restaurantId);
        updateData['imageUrl'] = imageUrl;
      }
      
      updateData['updatedAt'] = Timestamp.now();
      
      // Update the document
      await _firestore.collection('menu_items').doc(itemId).update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  // Delete menu item
  Future<void> deleteMenuItem(String itemId) async {
    try {
      // Get the item first to get the image URL
      final itemDoc = await _firestore.collection('menu_items').doc(itemId).get();
      
      if (!itemDoc.exists) {
        throw Exception('Menu item not found');
      }
      
      final imageUrl = itemDoc.data()?['imageUrl'];
      
      // Delete the document
      await _firestore.collection('menu_items').doc(itemId).delete();
      
      // Attempt to delete the image if it exists
      if (imageUrl != null && imageUrl is String && imageUrl.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          // Just log the error but don't rethrow, as the menu item was deleted successfully
          print('Error deleting image: $e');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get all menu items for a restaurant
  Stream<List<MenuItem>> getRestaurantMenuItems(String restaurantId) {
    return _firestore
        .collection('menu_items')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList();
    });
  }

  // Get menu items by category
  Stream<List<MenuItem>> getMenuItemsByCategory(String restaurantId, String category) {
    return _firestore
        .collection('menu_items')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList();
    });
  }

  // Get featured menu items
  Stream<List<MenuItem>> getFeaturedMenuItems(String restaurantId) {
    return _firestore
        .collection('menu_items')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList();
    });
  }

  // Get menu categories for a restaurant
  Future<List<String>> getRestaurantCategories(String restaurantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('menu_items')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();
      
      final categories = querySnapshot.docs
          .map((doc) => doc.data()['category'] as String)
          .toSet() // Use a Set to get unique categories
          .toList();
      
      return categories;
    } catch (e) {
      rethrow;
    }
  }

  // Toggle menu item availability
  Future<void> toggleItemAvailability(String itemId, bool isAvailable) async {
    try {
      await _firestore.collection('menu_items').doc(itemId).update({
        'isAvailable': isAvailable,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Toggle menu item featured status
  Future<void> toggleItemFeatured(String itemId, bool isFeatured) async {
    try {
      await _firestore.collection('menu_items').doc(itemId).update({
        'isFeatured': isFeatured,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
