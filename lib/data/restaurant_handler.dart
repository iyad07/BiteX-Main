import 'dart:async';
import 'package:bikex/models/cart_item.dart';
import 'package:bikex/models/food.dart';
import 'package:bikex/models/order.dart';
import 'package:bikex/models/restaurant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

class RestaurantHandler extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Restaurant> _restaurants = [];
  List<OrderModel> _orders = [];
  StreamSubscription? _ordersSubscription;
  
  // Getters
  List<Restaurant> get restaurants => _restaurants;
  List<OrderModel> get orders => _orders;
  List<OrderModel> get pendingOrders => _orders.where((order) => order.status == OrderStatus.pending).toList();
  List<OrderModel> get preparingOrders => _orders.where((order) => order.status == OrderStatus.preparing).toList();
  List<OrderModel> get readyOrders => _orders.where((order) => order.status == OrderStatus.ready).toList();
  
  RestaurantHandler() {
    // Initialize with some sample data if needed
    _initializeSampleData();
    
    // Set up real-time order updates
    _setupOrderListener();
  }
  
  void _initializeSampleData() {
    // Add sample restaurants and foods with location data
    final restaurant1 = Restaurant(
      id: '1',
      restaurantName: 'Waakye Supreme',
      restaurantImage: "https://images.bolt.eu/store/2022/2022-02-09/0007c966-0747-4e5b-842c-beddf6b776af.jpeg",
      rating: 4,
      deliveryTime: "30 mins",
      isFreeDelivery: true,
      restaurantCategories: "Fast Food",
      latitude: 5.6037,  // Accra, Ghana coordinates
      longitude: -0.1870,
      address: "123 Oxford Street, Osu, Accra",
      phoneNumber: "+233 24 123 4567",
    );
    
    final restaurant2 = Restaurant(
      id: '2',
      restaurantName: 'Pizza Palace',
      restaurantImage: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQGARNcg22HO5RZdURE8nl_ppn7ZX2rAtXyow&s",
      rating: 5,
      deliveryTime: "45 mins",
      isFreeDelivery: false,
      restaurantCategories: "Pizza",
      latitude: 5.6108,  // East Legon, Accra coordinates
      longitude: -0.1673,
      address: "456 Liberation Road, East Legon, Accra",
      phoneNumber: "+233 30 987 6543",
    );
    
    final restaurant3 = Restaurant(
      id: '3',
      restaurantName: 'Burger Junction',
      restaurantImage: "https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=500",
      rating: 4,
      deliveryTime: "25 mins",
      isFreeDelivery: true,
      restaurantCategories: "Burgers",
      latitude: 5.5502,  // Tema coordinates
      longitude: -0.0074,
      address: "789 Community 1, Tema",
      phoneNumber: "+233 26 555 7890",
    );
    
    // Add sample foods to restaurants
    restaurant1.addFood(Food(
      id: 'f1',
      foodTitle: "Jollof Rice",
      foodImage: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcScVNVvymzdm9IHeq9REMYRky2CILFnbtJDMQ&s",
      price: 70,
      restaurant: restaurant1,
      description: "Delicious Ghanaian jollof rice with chicken",
      preparationTime: 25,
    ));
    
    restaurant1.addFood(Food(
      id: 'f2',
      foodTitle: "Beans and Gari",
      foodImage: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQHllcw0H5cCzTH2-ZU25Lm-SUKcBlwMaCLCstawlIHKJMKTBGF_z_f5rt9tQ5tcpyNBdY&usqp=CAU",
      price: 50,
      restaurant: restaurant1,
      description: "Stewed beans with gari and fried plantain",
      isVegan: true,
      preparationTime: 20,
    ));
    
    restaurant2.addFood(Food(
      id: 'f3',
      foodTitle: "Pepperoni Pizza",
      foodImage: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ5ask8c39yQLLJYEXGXsq9ajVwRYjkEPjhJA&s",
      price: 120,
      restaurant: restaurant2,
      description: "Classic pepperoni pizza with mozzarella",
      preparationTime: 30,
    ));
    
    restaurant2.addFood(Food(
      id: 'f4',
      foodTitle: "Margherita Pizza",
      foodImage: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ5ask8c39yQLLJYEXGXsq9ajVwRYjkEPjhJA&s",
      price: 100,
      restaurant: restaurant2,
      description: "Fresh tomato sauce, mozzarella, and basil",
      isVegetarian: true,
      preparationTime: 25,
    ));
    
    // Add foods to restaurant3
    restaurant3.addFood(Food(
      id: 'f5',
      foodTitle: "Classic Burger",
      foodImage: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500",
      price: 85,
      restaurant: restaurant3,
      description: "Juicy beef patty with lettuce, tomato, and cheese",
      preparationTime: 15,
    ));
    
    restaurant3.addFood(Food(
      id: 'f6',
      foodTitle: "Chicken Burger",
      foodImage: "https://images.unsplash.com/photo-1606755962773-d324e2d53352?w=500",
      price: 90,
      restaurant: restaurant3,
      description: "Grilled chicken breast with avocado and mayo",
      preparationTime: 18,
    ));
    
    _restaurants = [restaurant1, restaurant2, restaurant3];
  }
  // Cart Management
  List<CartItem> cartItems = [];
  bool isAlreadyInCart = false;

  void addToCart(Food food, {int quantity = 1}) {
    // Check if the food item already exists in the cart
    final existingItemIndex = cartItems.indexWhere((item) => item.food.id == food.id);
    
    if (existingItemIndex >= 0) {
      // Item exists, update quantity
      cartItems[existingItemIndex] = cartItems[existingItemIndex].copyWith(
        quantity: cartItems[existingItemIndex].quantity + quantity,
      );
    } else {
      // Add new item to cart
      cartItems.add(CartItem(
        id: const Uuid().v4(),
        food: food,
        quantity: quantity,
        notes: '',
      ));
    }
    
    isAlreadyInCart = existingItemIndex >= 0;
    notifyListeners();
  }

  void increaseQuantity(Food food) {
    final index = cartItems.indexWhere((item) => item.food.id == food.id);
    if (index != -1) {
      cartItems[index] = cartItems[index].copyWith(
        quantity: cartItems[index].quantity + 1,
      );
      notifyListeners();
    }
  }

  void decreaseQuantity(Food food) {
    final index = cartItems.indexWhere((item) => item.food.id == food.id);
    if (index != -1 && cartItems[index].quantity > 1) {
      cartItems[index] = cartItems[index].copyWith(
        quantity: cartItems[index].quantity - 1,
      );
      notifyListeners();
    }
  }

  void removeFromCart(Food food) {
    cartItems.removeWhere((item) => item.food.id == food.id);
    notifyListeners();
  }

  void updateCartItemNote(Food food, String note) {
    final index = cartItems.indexWhere((item) => item.food.id == food.id);
    if (index != -1) {
      cartItems[index] = cartItems[index].copyWith(notes: note);
      notifyListeners();
    }
  }

  double getTotal() {
    return cartItems.fold(0, (total, item) => total + (item.food.price * item.quantity));
  }
  
  // Order Management
  Future<OrderModel> placeOrder({
    required String deliveryAddress,
    required String customerName,
    required String customerPhone,
    String? notes,
  }) async {
    if (cartItems.isEmpty) {
      throw Exception('Cannot place an empty order');
    }
    
    // Get the restaurant (assuming all items are from the same restaurant)
    final restaurant = cartItems.first.food.restaurant;
    if (restaurant == null) {
      throw Exception('Invalid restaurant');
    }
    
    // Create the order
    final order = OrderModel(
      restaurant: restaurant,
      items: List.from(cartItems),
      totalPrice: getTotal(),
      deliveryAddress: deliveryAddress,
      customerName: customerName,
      customerPhone: customerPhone,
      notes: notes,
    );
    
    try {
      // Save to Firestore
      await _firestore.collection('orders').doc(order.id).set(order.toMap());
      
      // Add to local orders list
      _orders.add(order);
      
      // Clear the cart after successful order
      cartItems.clear();
      notifyListeners();
      
      // Return the created order
      return order;
    } catch (e) {
      debugPrint('Error placing order: $e');
      rethrow;
    }
  }
  
  // Update an existing order
  Future<void> updateOrder(OrderModel order) async {
    try {
      await _firestore.collection('orders').doc(order.id).update({
        'items': order.items.map((item) => item.toMap()).toList(),
        'status': order.status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local orders list
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders[index] = order;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating order: $e');
      rethrow;
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);
      final updatedOrder = order.copyWith(status: newStatus);
      
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local orders list
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }
  
  // Real-time Order Listener
  void _setupOrderListener() {
    final user = _auth.currentUser;
    if (user == null) return;
    
    // Listen for orders where the current user is the restaurant owner
    _ordersSubscription = _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: user.uid)
        .orderBy('orderTime', descending: true)
        .snapshots()
        .listen((snapshot) {
      _orders = snapshot.docs.map((doc) {
        // Convert document to Order object
        // This is a simplified example - you'll need to fetch the restaurant and food items
        // based on the IDs stored in the order document
        final restaurant = getRestaurantById(doc['restaurantId']);
        if (restaurant == null) {
          throw Exception('Restaurant not found');
        }
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>, restaurant);
      }).toList();
      
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error listening to orders: $error');
    });
  }
  
  // Clean up
  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
  // Getters
  List<Food> getAllFood() {
    return _restaurants.expand((restaurant) => restaurant.foodList).toList();
  }

  List<CartItem> getCartItems() {
    return List.from(cartItems);
  }
  
  Restaurant? getRestaurantById(String id) {
    try {
      return _restaurants.firstWhere((restaurant) => restaurant.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get orders for a specific restaurant
  List<OrderModel> getOrdersByRestaurant(String restaurantId) {
    return _orders.where((order) => order.restaurant.id == restaurantId).toList();
  }
  
  // Get order by ID
  OrderModel? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }
  
  // Location-based methods for map integration
  
  // Get restaurants sorted by distance from user location
  List<Restaurant> getRestaurantsByDistance(LatLng userLocation) {
    final restaurantsWithDistance = _restaurants
        .where((restaurant) => restaurant.hasLocation)
        .map((restaurant) => {
              'restaurant': restaurant,
              'distance': restaurant.distanceFrom(userLocation) ?? double.infinity,
            })
        .toList();
    
    restaurantsWithDistance.sort((a, b) => 
        (a['distance'] as double).compareTo(b['distance'] as double));
    
    return restaurantsWithDistance
        .map((item) => item['restaurant'] as Restaurant)
        .toList();
  }
  
  // Get restaurants within a specific radius (in kilometers)
  List<Restaurant> getRestaurantsWithinRadius(LatLng userLocation, double radiusKm) {
    return _restaurants
        .where((restaurant) => 
            restaurant.hasLocation && 
            (restaurant.distanceFrom(userLocation) ?? double.infinity) <= radiusKm)
        .toList();
  }
  
  // Get all restaurants with valid locations for map display
  List<Restaurant> getRestaurantsWithLocation() {
    return _restaurants.where((restaurant) => restaurant.hasLocation).toList();
  }
  
  // Get map markers for all restaurants
  Set<Marker> getRestaurantMarkers({Function(Restaurant)? onMarkerTap}) {
    return _restaurants
        .where((restaurant) => restaurant.hasLocation)
        .map((restaurant) => Marker(
              markerId: MarkerId('restaurant_${restaurant.id}'),
              position: restaurant.location!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              infoWindow: InfoWindow(
                title: restaurant.restaurantName,
                snippet: '${restaurant.rating}⭐ • ${restaurant.deliveryTime}',
              ),
              onTap: onMarkerTap != null ? () => onMarkerTap(restaurant) : null,
            ))
        .toSet();
  }
  
  // Calculate estimated delivery time based on distance
  String getEstimatedDeliveryTime(Restaurant restaurant, LatLng userLocation) {
    if (!restaurant.hasLocation) return restaurant.deliveryTime;
    
    final distance = restaurant.distanceFrom(userLocation);
    if (distance == null) return restaurant.deliveryTime;
    
    // Estimate: 2 minutes per km + preparation time
    final travelTime = (distance * 2).round();
    final preparationTime = int.tryParse(restaurant.deliveryTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 30;
    final totalTime = travelTime + preparationTime;
    
    return '$totalTime mins';
  }
}
