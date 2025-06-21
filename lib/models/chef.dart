import 'package:cloud_firestore/cloud_firestore.dart';

class Chef {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final String restaurantId;
  final String? speciality;
  final String? bio;
  final List<String>? certificates;
  final DateTime joinDate;
  final bool isActive;

  Chef({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    required this.restaurantId,
    this.speciality,
    this.bio,
    this.certificates,
    required this.joinDate,
    this.isActive = true,
  });

  factory Chef.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Chef(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      restaurantId: data['restaurantId'] ?? '',
      speciality: data['speciality'],
      bio: data['bio'],
      certificates: data['certificates'] != null ? List<String>.from(data['certificates']) : null,
      joinDate: data['joinDate'] != null ? (data['joinDate'] as Timestamp).toDate() : DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'restaurantId': restaurantId,
      'speciality': speciality,
      'bio': bio,
      'certificates': certificates,
      'joinDate': Timestamp.fromDate(joinDate),
      'isActive': isActive,
    };
  }

  Chef copyWith({
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    String? restaurantId,
    String? speciality,
    String? bio,
    List<String>? certificates,
    bool? isActive,
  }) {
    return Chef(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      restaurantId: restaurantId ?? this.restaurantId,
      speciality: speciality ?? this.speciality,
      bio: bio ?? this.bio,
      certificates: certificates ?? this.certificates,
      joinDate: joinDate,
      isActive: isActive ?? this.isActive,
    );
  }
}