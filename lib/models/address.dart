import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String userId;
  final String title; // e.g., 'Home', 'Work', 'Friend's Place'
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final double latitude;
  final double longitude;
  final String? instructions; // Delivery instructions
  final bool isDefault;
  final String? label; // Custom label if not a standard type
  final DateTime createdAt;
  final DateTime? updatedAt;

  Address({
    required this.id,
    required this.userId,
    required this.title,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.instructions,
    required this.isDefault,
    this.label,
    required this.createdAt,
    this.updatedAt,
  });

  factory Address.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Address(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      addressLine1: data['addressLine1'] ?? '',
      addressLine2: data['addressLine2'],
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      postalCode: data['postalCode'] ?? '',
      country: data['country'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      instructions: data['instructions'],
      isDefault: data['isDefault'] ?? false,
      label: data['label'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'instructions': instructions,
      'isDefault': isDefault,
      'label': label,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Address copyWith({
    String? title,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    String? instructions,
    bool? isDefault,
    String? label,
  }) {
    return Address(
      id: id,
      userId: userId,
      title: title ?? this.title,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      instructions: instructions ?? this.instructions,
      isDefault: isDefault ?? this.isDefault,
      label: label ?? this.label,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Get formatted full address
  String get formattedAddress {
    String formatted = addressLine1;
    
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      formatted += ', $addressLine2';
    }
    
    formatted += ', $city, $state $postalCode, $country';
    
    return formatted;
  }

  // Get short formatted address (for display in lists)
  String get shortAddress {
    return '$addressLine1, $city';
  }
}
