import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../../models/restaurant.dart';
import '../../models/food.dart';
import '../../data/restaurant_handler.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Restaurant restaurant;
  final List<Food> orderItems;
  final String orderNumber;
  final LatLng? customerLocation;

  const OrderTrackingScreen({
    Key? key,
    required this.restaurant,
    required this.orderItems,
    required this.orderNumber,
    this.customerLocation,
  }) : super(key: key);

  @override
  _OrderTrackingScreenState createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;
  LatLng? _currentLocation;
  LatLng? _deliveryLocation;
  LatLng? _customerLocation;
  
  Timer? _locationUpdateTimer;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  
  int _currentStep = 2; // 0: Preparing, 1: Ready, 2: On the way, 3: Delivered
  String _estimatedTime = "15 min";
  String _deliveryPersonName = "Alex Johnson";
  String _deliveryPersonPhone = "+1 (555) 123-4567";
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLocations();
    _requestLocationPermission();
    _startLocationUpdates();
  }

  void _initializeLocations() {
    // Use provided customer location or default
    _customerLocation = widget.customerLocation ?? const LatLng(37.7649, -122.4294);
    
    // Set initial delivery location near restaurant
    if (widget.restaurant.hasLocation) {
      _deliveryLocation = LatLng(
        widget.restaurant.latitude! + 0.002, // Slightly offset from restaurant
        widget.restaurant.longitude! + 0.002,
      );
    } else {
      _deliveryLocation = const LatLng(37.7749, -122.4194);
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    try {
      var status = await Permission.location.request();
      if (status.isGranted) {
        await _getCurrentLocation();
      }
      setState(() => _isLoading = false);
      _addMarkers();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        // Update customer location if not provided
        if (widget.customerLocation == null) {
          _customerLocation = _currentLocation;
        }
      });
    } catch (e) {
      // Keep default customer location
    }
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentStep == 2) {
        _simulateDeliveryMovement();
      }
    });
  }

  void _simulateDeliveryMovement() {
    if (_deliveryLocation == null || _customerLocation == null) return;
    
    const double step = 0.0005;
    final double latDiff = _customerLocation!.latitude - _deliveryLocation!.latitude;
    final double lngDiff = _customerLocation!.longitude - _deliveryLocation!.longitude;
    
    if (latDiff.abs() > 0.005 || lngDiff.abs() > 0.005) {
      setState(() {
        _deliveryLocation = LatLng(
          _deliveryLocation!.latitude + (latDiff > 0 ? step : -step),
          _deliveryLocation!.longitude + (lngDiff > 0 ? step : -step),
        );
      });
      _updateMarkers();
      _updateEstimatedTime();
    } else {
      // Delivery completed
      setState(() {
        _currentStep = 3;
      });
      _locationUpdateTimer?.cancel();
    }
  }

  void _updateEstimatedTime() {
    if (_deliveryLocation == null || _customerLocation == null) return;
    
    final double distance = widget.restaurant.calculateDistance(
      _deliveryLocation!.latitude,
      _deliveryLocation!.longitude,
      _customerLocation!.latitude,
      _customerLocation!.longitude,
    );
    
    final int minutes = (distance * 20).round().clamp(1, 30);
    setState(() {
      _estimatedTime = "$minutes min";
    });
  }

  void _addMarkers() {
    setState(() {
      _markers.clear();
      
      // Restaurant marker
      if (widget.restaurant.hasLocation) {
        _markers.add(
          Marker(
            markerId: const MarkerId('restaurant'),
            position: widget.restaurant.location ?? const LatLng(0, 0),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: widget.restaurant.restaurantName,
              snippet: 'Restaurant',
            ),
          ),
        );
      }
      
      // Customer location marker
      if (_customerLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('customer'),
            position: _customerLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(
              title: 'Your Location',
              snippet: 'Delivery destination',
            ),
          ),
        );
      }
      
      // Delivery person marker
      if (_currentStep == 2 && _deliveryLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('delivery'),
            position: _deliveryLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: _deliveryPersonName,
              snippet: 'Delivery person',
            ),
          ),
        );
      }
    });
    
    _updatePolylines();
  }

  void _updateMarkers() {
    if (_markers.isNotEmpty && _deliveryLocation != null) {
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == 'delivery');
        if (_currentStep == 2) {
          _markers.add(
            Marker(
              markerId: const MarkerId('delivery'),
              position: _deliveryLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              infoWindow: InfoWindow(
                title: _deliveryPersonName,
                snippet: 'Delivery person',
              ),
            ),
          );
        }
      });
      _updatePolylines();
    }
  }

  void _updatePolylines() {
    setState(() {
      _polylines.clear();
      if (_currentStep == 2 && _deliveryLocation != null && _customerLocation != null) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('delivery_route'),
            points: [_deliveryLocation!, _customerLocation!],
            color: Colors.blue,
            width: 3,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
    });
  }

  void _centerMapOnDelivery() {
    if (_mapController != null && _deliveryLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_deliveryLocation!, 15),
      );
    }
  }

  void _callDeliveryPerson() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Call $_deliveryPersonName'),
        content: Text('Would you like to call $_deliveryPersonPhone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, you would use url_launcher to make the call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling delivery person...')),
              );
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  double _calculateOrderTotal() {
    return widget.orderItems.fold(0.0, (sum, item) => sum + item.price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Track Order',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _getCurrentLocation();
              _addMarkers();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _deliveryLocation ?? const LatLng(37.7749, -122.4194),
                    zoom: 13.5,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                ),
                
                // Floating ETA Card
                Positioned(
                  top: 100,
                  left: 20,
                  child: _buildETACard(),
                ),
                
                // Floating Action Buttons
                Positioned(
                  top: 100,
                  right: 20,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: "center",
                        onPressed: _centerMapOnDelivery,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.my_location, color: Colors.blue),
                      ),
                      const SizedBox(height: 10),
                      if (_currentStep == 2)
                        FloatingActionButton.small(
                          heroTag: "call",
                          onPressed: _callDeliveryPerson,
                          backgroundColor: Colors.green,
                          child: const Icon(Icons.phone, color: Colors.white),
                        ),
                    ],
                  ),
                ),
                
                // Draggable Bottom Sheet
                DraggableScrollableSheet(
                  initialChildSize: 0.35,
                  minChildSize: 0.35,
                  maxChildSize: 0.8,
                  builder: (BuildContext context, ScrollController scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDragIndicator(),
                              const SizedBox(height: 20),
                              _buildOrderHeader(),
                              const SizedBox(height: 20),
                              _buildDeliveryStatus(),
                              const SizedBox(height: 25),
                              _buildOrderStepper(),
                              const SizedBox(height: 25),
                              if (_currentStep == 2) _buildDeliveryPersonCard(),
                              const SizedBox(height: 20),
                              _buildOrderSummary(),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildETACard() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.03),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  _estimatedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragIndicator() {
    return Center(
      child: Container(
        width: 50,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: AssetImage(widget.restaurant.restaurantImage),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.orderNumber,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.restaurant.restaurantName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.restaurant.address != null)
                Text(
                  widget.restaurant.address!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryStatus() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (_currentStep) {
      case 0:
        statusText = 'Preparing your order';
        statusColor = Colors.orange;
        statusIcon = Icons.restaurant;
        break;
      case 1:
        statusText = 'Order ready for pickup';
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case 2:
        statusText = 'On the way';
        statusColor = Colors.green;
        statusIcon = Icons.delivery_dining;
        break;
      case 3:
        statusText = 'Delivered';
        statusColor = Colors.green;
        statusIcon = Icons.done_all;
        break;
      default:
        statusText = 'Processing';
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStepper() {
    final steps = [
      'Order Confirmed',
      'Preparing',
      'On the way',
      'Delivered',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Progress',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isCompleted = index <= _currentStep;
          final isActive = index == _currentStep;

          return Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Colors.green : Colors.grey[300],
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDeliveryPersonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _deliveryPersonName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Delivery Partner',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _callDeliveryPerson,
            icon: const Icon(Icons.phone, color: Colors.green),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Messaging feature coming soon!')),
              );
            },
            icon: const Icon(Icons.message, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final total = _calculateOrderTotal();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.orderItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.foodTitle,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              Text(
                '\$${item.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )).toList(),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}