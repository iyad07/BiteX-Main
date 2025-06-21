import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math';

import '../../../../data/restaurant_handler.dart';
import '../../../../models/order.dart';
import '../../../../models/address.dart';
import '../../../../services/address_service.dart';
import 'google_map_screen.dart';

class TrackOrderPage extends StatefulWidget {
  final OrderModel? order;
  const TrackOrderPage({Key? key, this.order}) : super(key: key);

  @override
  _TrackOrderPageState createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends State<TrackOrderPage> with TickerProviderStateMixin {
  LatLng? _currentLocation;
  LatLng _deliveryLocation = const LatLng(37.7749, -122.4194); // Simulated delivery person location
  late LatLng _restaurantLocation;
  late LatLng _customerLocation;
  bool _isLoading = true;
  late int _currentStep;
  Timer? _locationUpdateTimer;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  String _estimatedTime = "15 min";
  String _deliveryPersonName = "Robert F.";
  String _deliveryPersonPhone = "+1 234 567 8900";
  GoogleMapController? _mapController;
  
  // Order data
  OrderModel? _currentOrder;
  
  // Address service
  final AddressService _addressService = AddressService();

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _initializeOrderData();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _requestLocationPermission();
    _startLocationUpdates();
    _animateProgress();
  }
  
  void _initializeOrderData() async {
    if (_currentOrder != null) {
      // Set restaurant location (using default coordinates for now)
      _restaurantLocation = const LatLng(37.7849, -122.4094);
      
      // Set current step based on order status
      switch (_currentOrder!.status) {
        case OrderStatus.pending:
          _currentStep = 0;
          break;
        case OrderStatus.preparing:
          _currentStep = 1;
          break;
        case OrderStatus.ready:
          _currentStep = 2;
          break;
        case OrderStatus.completed:
          _currentStep = 3;
          break;
        case OrderStatus.cancelled:
          _currentStep = 0;
          break;
      }
    } else {
      // Fallback to default values
      _restaurantLocation = const LatLng(37.7849, -122.4094);
      _currentStep = 2;
    }
    
    // Get user's address for customer location
    await _loadUserAddress();
  }
  
  Future<void> _loadUserAddress() async {
    try {
      final Address? userAddress = await _addressService.getDefaultAddress();
      if (userAddress != null) {
        setState(() {
          _customerLocation = LatLng(userAddress.latitude, userAddress.longitude);
          _isLoading = false;
        });
        // Update estimated time based on new location
        _updateEstimatedTime();
        // Update map camera to show the new location
        _fitMapToShowAllMarkers();
      } else {
        // Fallback to default coordinates if no address found
        setState(() {
          _customerLocation = const LatLng(37.7649, -122.4294);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user address: $e');
      // Fallback to default coordinates on error
      setState(() {
        _customerLocation = const LatLng(37.7649, -122.4294);
        _isLoading = false;
      });
    }
  }
  
  void _fitMapToShowAllMarkers() {
    if (_mapController == null) return;
    
    // Calculate bounds to include all relevant markers
    double minLat = _customerLocation.latitude;
    double maxLat = _customerLocation.latitude;
    double minLng = _customerLocation.longitude;
    double maxLng = _customerLocation.longitude;
    
    // Include restaurant location
    minLat =min(minLat, _restaurantLocation.latitude);
    maxLat =max(maxLat, _restaurantLocation.latitude);
    minLng =min(minLng, _restaurantLocation.longitude);
    maxLng =max(maxLng, _restaurantLocation.longitude);
    
    // Include delivery location if in delivery phase
    if (_currentStep == 2) {
      minLat = min(minLat, _deliveryLocation.latitude);
      maxLat = max(maxLat, _deliveryLocation.latitude);
      minLng = min(minLng, _deliveryLocation.longitude);
      maxLng =max(maxLng, _deliveryLocation.longitude);
    }
    
    // Add padding
    const double padding = 0.01;
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _animateProgress() {
    _progressController.animateTo(_currentStep / 3);
  }

  void _startLocationUpdates() {
    // Simulate delivery person movement
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentStep == 2) { // Only move when "On the way"
        _simulateDeliveryMovement();
      }
    });
  }

  void _simulateDeliveryMovement() {
    // Simulate delivery person moving towards customer
    const double step = 0.001; // Small movement step
    final double latDiff = _customerLocation.latitude - _deliveryLocation.latitude;
    final double lngDiff = _customerLocation.longitude - _deliveryLocation.longitude;
    
    if (latDiff.abs() > 0.01 || lngDiff.abs() > 0.01) {
      setState(() {
        _deliveryLocation = LatLng(
          _deliveryLocation.latitude + (latDiff > 0 ? step : -step),
          _deliveryLocation.longitude + (lngDiff > 0 ? step : -step),
        );
      });
      
      // Update estimated time based on distance
      _updateEstimatedTime();
    }
  }

  void _updateEstimatedTime() {
    final double distance = _calculateDistance(
      _deliveryLocation.latitude,
      _deliveryLocation.longitude,
      _customerLocation.latitude,
      _customerLocation.longitude,
    );
    
    final int minutes = (distance * 20).round(); // Rough estimation
    setState(() {
      _estimatedTime = "${minutes.clamp(1, 30)} min";
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  Future<void> _requestLocationPermission() async {
    try {
      var status = await Permission.location.request();
      if (status.isGranted) {
        await _getCurrentLocation();
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantHandler = Provider.of<RestaurantHandler>(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Track Order', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 50,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Enhanced Map Section
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      _buildEnhancedMap(),
                      
                      // Floating delivery info card
                      if (_currentStep == 2)
                        Positioned(
                          top: 20,
                          left: 20,
                          right: 20,
                          child: _buildDeliveryInfoCard(),
                        ),
                      
                      // Estimated time floating widget
                      Positioned(
                        top: 100,
                        right: 20,
                        child: _buildEstimatedTimeWidget(),
                      ),
                    ],
                  ),
                ),
                
                // Order Status Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildEnhancedStatusStepper(),
                      const SizedBox(height: 20),
                      if (_currentStep == 2) _buildDeliveryPersonInfo(),
                      const SizedBox(height: 16),
                      _buildOrderDetails(restaurantHandler),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEnhancedMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _customerLocation,
        zoom: 14.0,
      ),
      markers: _buildMapMarkers(),
      polylines: _buildRoutePolyline(),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        _fitMapToShowAllMarkers();
      },
    );
  }

  Set<Marker> _buildMapMarkers() {
    return {
      // Restaurant marker
      Marker(
        markerId: const MarkerId('restaurant'),
        position: _restaurantLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Restaurant'),
      ),
      
      // Customer location marker
      Marker(
        markerId: const MarkerId('customer'),
        position: _customerLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
      
      // Delivery person marker (animated)
      if (_currentStep == 2)
        Marker(
          markerId: const MarkerId('delivery'),
          position: _deliveryLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: _deliveryPersonName),
        ),
    };
  }

  Set<Polyline> _buildRoutePolyline() {
    if (_currentStep != 2) return {};
    
    return {
      Polyline(
        polylineId: const PolylineId('delivery_route'),
        points: [_deliveryLocation, _customerLocation],
        color: Colors.blue,
        width: 3,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
  }

  Widget _buildDeliveryInfoCard() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.05),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delivery_dining, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _deliveryPersonName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        'is on the way',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _callDeliveryPerson(),
                  icon: const Icon(Icons.phone, color: Colors.green),
                  iconSize: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstimatedTimeWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            _estimatedTime,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatusStepper() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatusStep(0, 'Order\nPlaced', Icons.shopping_bag, _currentStep >= 0),
            _buildStatusStep(1, 'Preparing', Icons.restaurant, _currentStep >= 1),
            _buildStatusStep(2, 'On the way', Icons.delivery_dining, _currentStep >= 2),
            _buildStatusStep(3, 'Delivered', Icons.check_circle, _currentStep >= 3),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _progressController,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _progressController.value,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              minHeight: 4,
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusStep(int step, String label, IconData icon, bool isActive) {
    final bool isCurrent = step == _currentStep;
    
    return Expanded(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: isCurrent ? _pulseController : kAlwaysCompleteAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isCurrent ? 1.0 + (_pulseController.value * 0.1) : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.orange : Colors.grey[300],
                    shape: BoxShape.circle,
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.orange : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPersonInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.orange,
            child: Text(
              _deliveryPersonName.split(' ').map((e) => e[0]).join(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _deliveryPersonName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  'Delivery Partner',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'ETA: $_estimatedTime',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _callDeliveryPerson(),
                icon: const Icon(Icons.phone),
                color: Colors.green,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.1),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _messageDeliveryPerson(),
                icon: const Icon(Icons.message),
                color: Colors.blue,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _callDeliveryPerson() {
    // Implement call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $_deliveryPersonName...'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _messageDeliveryPerson() {
    // Implement messaging functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat with $_deliveryPersonName...'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildOrderDetails(RestaurantHandler restaurantHandler) {
    // Use order data if available, otherwise fallback to cart items
    final items = _currentOrder?.items ?? restaurantHandler.cartItems;
    final totalPrice = _currentOrder?.totalPrice ?? 
        restaurantHandler.cartItems.fold(0.0, (sum, item) => (sum ?? 0.0) + (item.food.price * item.quantity));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Order Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (_currentOrder != null)
              Text(
                'Order #${_currentOrder!.id.substring(0, 8)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        if (_currentOrder != null) ...[
          const SizedBox(height: 4),
          Text(
            'From ${_currentOrder!.restaurant.restaurantName}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            'Ordered on ${_currentOrder!.formattedOrderTime}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 8),
        ...items.map((item) => ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(item.food.foodImage!),
              ),
              title: Text(item.food.foodTitle),
              subtitle: Text('Qty: ${item.quantity}'),
              trailing: Text('\$${(item.food.price * item.quantity).toStringAsFixed(2)}'),
            )),
        const Divider(),
        if (_currentOrder != null && _currentOrder!.notes != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Special Instructions:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentOrder!.notes!,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Divider(),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '\$${(totalPrice ?? 0.0).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        if (_currentOrder != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Delivering to: ${_currentOrder!.deliveryAddress}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
