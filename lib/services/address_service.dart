import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bikex/models/address.dart';
import 'package:geocoding/geocoding.dart';

class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all addresses for current user
  Stream<List<Address>> getUserAddresses() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('addresses')
        .where('userId', isEqualTo: user.uid)
        .orderBy('isDefault', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Address.fromFirestore(doc)).toList();
    });
  }

  // Get default address for current user
  Future<Address?> getDefaultAddress() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final snapshot = await _firestore
        .collection('addresses')
        .where('userId', isEqualTo: user.uid)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      // If no default address, try to get any address
      final anyAddressSnapshot = await _firestore
          .collection('addresses')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
          
      if (anyAddressSnapshot.docs.isEmpty) {
        return null;
      }
      
      return Address.fromFirestore(anyAddressSnapshot.docs.first);
    }

    return Address.fromFirestore(snapshot.docs.first);
  }

  // Add a new address
  Future<String> addAddress({
    required String title,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    required double latitude,
    required double longitude,
    String? instructions,
    bool isDefault = false,
    String? label,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to add an address');
      }

      // If this is set as default, unset any existing default
      if (isDefault) {
        await _unsetCurrentDefaultAddress(user.uid);
      }

      // Create new address document
      final docRef = await _firestore.collection('addresses').add({
        'userId': user.uid,
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
        'createdAt': Timestamp.now(),
      });

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Update an existing address
  Future<void> updateAddress({
    required String addressId,
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
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to update an address');
      }

      // If this is set as default, unset any existing default
      if (isDefault == true) {
        await _unsetCurrentDefaultAddress(user.uid);
      }

      // Prepare update data
      final Map<String, dynamic> updateData = {};

      if (title != null) updateData['title'] = title;
      if (addressLine1 != null) updateData['addressLine1'] = addressLine1;
      if (addressLine2 != null) updateData['addressLine2'] = addressLine2;
      if (city != null) updateData['city'] = city;
      if (state != null) updateData['state'] = state;
      if (postalCode != null) updateData['postalCode'] = postalCode;
      if (country != null) updateData['country'] = country;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (instructions != null) updateData['instructions'] = instructions;
      if (isDefault != null) updateData['isDefault'] = isDefault;
      if (label != null) updateData['label'] = label;

      updateData['updatedAt'] = Timestamp.now();

      // Update address document
      await _firestore.collection('addresses').doc(addressId).update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  // Delete an address
  Future<void> deleteAddress(String addressId) async {
    try {
      final doc = await _firestore.collection('addresses').doc(addressId).get();
      
      // If this was a default address, make another address the default
      if (doc.exists && doc.data()?['isDefault'] == true) {
        final user = _auth.currentUser;
        if (user != null) {
          await _setNewDefaultAddress(user.uid, addressId);
        }
      }
      
      await _firestore.collection('addresses').doc(addressId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Set address as default
  Future<void> setAddressAsDefault(String addressId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to set a default address');
      }

      // Unset current default address
      await _unsetCurrentDefaultAddress(user.uid);

      // Set new default address
      await _firestore.collection('addresses').doc(addressId).update({
        'isDefault': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Private: Unset current default address
  Future<void> _unsetCurrentDefaultAddress(String userId) async {
    final snapshot = await _firestore
        .collection('addresses')
        .where('userId', isEqualTo: userId)
        .where('isDefault', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isDefault': false,
        'updatedAt': Timestamp.now(),
      });
    }

    await batch.commit();
  }

  // Private: Set a new default address when current default is deleted
  Future<void> _setNewDefaultAddress(String userId, String excludeAddressId) async {
    final snapshot = await _firestore
        .collection('addresses')
        .where('userId', isEqualTo: userId)
        .where(FieldPath.documentId, isNotEqualTo: excludeAddressId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await _firestore.collection('addresses').doc(snapshot.docs.first.id).update({
        'isDefault': true,
        'updatedAt': Timestamp.now(),
      });
    }
  }

  // Get current location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Request user to enable location services
      await Permission.location.request();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable location services.');
      }
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied, cannot request permissions.');
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Get address from coordinates (reverse geocoding)
  Future<Map<String, dynamic>> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      Placemark place = placemarks[0];
      
      return {
        'addressLine1': '${place.street}',
        'addressLine2': place.subLocality ?? "",
        'city': '${place.locality}',
        'state': '${place.administrativeArea}',
        'postalCode': '${place.postalCode}',
        'country': '${place.country}',
        'latitude': latitude,
        'longitude': longitude,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Get coordinates from address (forward geocoding)
  Future<Map<String, double>> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isEmpty) {
        throw Exception('No coordinates found for this address');
      }
      
      return {
        'latitude': locations.first.latitude,
        'longitude': locations.first.longitude,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Validate if address is within delivery range of a restaurant
  Future<bool> isAddressInDeliveryRange(String addressId, String restaurantId) async {
    try {
      // Get address coordinates
      final addressDoc = await _firestore.collection('addresses').doc(addressId).get();
      if (!addressDoc.exists) {
        throw Exception('Address not found');
      }
      
      final addressData = addressDoc.data()!;
      final addressLat = addressData['latitude'] as double;
      final addressLng = addressData['longitude'] as double;
      
      // Get restaurant location and delivery range
      final restaurantDoc = await _firestore.collection('restaurants').doc(restaurantId).get();
      if (!restaurantDoc.exists) {
        throw Exception('Restaurant not found');
      }
      
      final restaurantData = restaurantDoc.data()!;
      final restaurantLat = restaurantData['latitude'] as double;
      final restaurantLng = restaurantData['longitude'] as double;
      final deliveryRange = restaurantData['deliveryRange'] as double? ?? 10.0; // Default 10km
      
      // Calculate distance
      final distanceInMeters = Geolocator.distanceBetween(
        addressLat,
        addressLng,
        restaurantLat,
        restaurantLng,
      );
      
      // Convert to kilometers
      final distanceInKm = distanceInMeters / 1000;
      
      return distanceInKm <= deliveryRange;
    } catch (e) {
      rethrow;
    }
  }
}
