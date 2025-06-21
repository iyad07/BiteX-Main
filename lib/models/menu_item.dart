import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String restaurantId;
  final String imageUrl;
  final bool isAvailable;
  final bool isFeatured;
  final List<String>? allergens;
  final Map<String, dynamic>? nutritionalInfo;
  final List<String>? tags;
  final Map<String, dynamic>? customizationOptions;
  final double? discountPercentage;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.restaurantId,
    required this.imageUrl,
    this.isAvailable = true,
    this.isFeatured = false,
    this.allergens,
    this.nutritionalInfo,
    this.tags,
    this.customizationOptions,
    this.discountPercentage,
    required this.createdAt,
    this.updatedAt,
  });

  factory MenuItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MenuItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      allergens: data['allergens'] != null ? List<String>.from(data['allergens']) : null,
      nutritionalInfo: data['nutritionalInfo'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      customizationOptions: data['customizationOptions'],
      discountPercentage: data['discountPercentage'] != null 
          ? (data['discountPercentage'] as num).toDouble()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'restaurantId': restaurantId,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'allergens': allergens,
      'nutritionalInfo': nutritionalInfo,
      'tags': tags,
      'customizationOptions': customizationOptions,
      'discountPercentage': discountPercentage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  MenuItem copyWith({
    String? name,
    String? description,
    double? price,
    String? category,
    String? restaurantId,
    String? imageUrl,
    bool? isAvailable,
    bool? isFeatured,
    List<String>? allergens,
    Map<String, dynamic>? nutritionalInfo,
    List<String>? tags,
    Map<String, dynamic>? customizationOptions,
    double? discountPercentage,
  }) {
    return MenuItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      restaurantId: restaurantId ?? this.restaurantId,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      allergens: allergens ?? this.allergens,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      tags: tags ?? this.tags,
      customizationOptions: customizationOptions ?? this.customizationOptions,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  double get finalPrice {
    if (discountPercentage != null && discountPercentage! > 0) {
      return price - (price * discountPercentage! / 100);
    }
    return price;
  }
}
