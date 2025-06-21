import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math';

class EnhancedMapTracking extends StatefulWidget {
  const EnhancedMapTracking({Key? key}) : super(key: key);

  @override
  _EnhancedMapTrackingState createState() => _EnhancedMapTrackingState();
}

class _EnhancedMapTrackingState extends State<EnhancedMapTracking>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;
  LatLng? _currentLocation;
  LatLng _deliveryLocation = const LatLng(37.7749, -122.4194);
  final LatLng _restaurantLocation = const LatLng(37.7849, -122.4094);
  final LatLng _customerLocation = const LatLng(37.7649, -122.4294);
  
  Timer? _locationUpdateTimer;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  
  int _currentStep = 2;
  String _estimatedTime = "12 min";
  String _deliveryPersonName = "Alex Johnson";
  String _orderNumber = "#BX2024001";
  String _restaurantName = "Delicious Bites";
  
  final List<Map<String, dynamic>> _orderItems = [
    {'name': '2x Burger Deluxe', 'price': 24.99},
    {'name': '1x Crispy Fries', 'price': 8.99},
    {'name': '2x Soft Drinks', 'price': 6.98},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _requestLocationPermission();
    _startLocationUpdates();
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
      });
    } catch (e) {
      setState(() => _currentLocation = _customerLocation);
    }
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentStep == 2) {
        _simulateDeliveryMovement();
      }
    });
  }

  void _simulateDeliveryMovement() {
    const double step = 0.0008;
    final double latDiff = _customerLocation.latitude - _deliveryLocation.latitude;
    final double lngDiff = _customerLocation.longitude - _deliveryLocation.longitude;
    
    if (latDiff.abs() > 0.01 || lngDiff.abs() > 0.01) {
      setState(() {
        _deliveryLocation = LatLng(
          _deliveryLocation.latitude + (latDiff > 0 ? step : -step),
          _deliveryLocation.longitude + (lngDiff > 0 ? step : -step),
        );
      });
      _updateMarkers();
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
    
    final int minutes = (distance * 15).round();
    setState(() {
      _estimatedTime = "${minutes.clamp(1, 25)} min";
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
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

  void _addMarkers() {
    setState(() {
      _markers.clear();
      
      // Restaurant marker
      _markers.add(
        Marker(
          markerId: const MarkerId('restaurant'),
          position: _restaurantLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: _restaurantName),
        ),
      );
      
      // Customer location marker
      _markers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: _customerLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
      
      // Delivery person marker
      if (_currentStep == 2) {
        _markers.add(
          Marker(
            markerId: const MarkerId('delivery'),
            position: _deliveryLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(title: _deliveryPersonName),
          ),
        );
      }
    });
    
    _updatePolylines();
  }

  void _updateMarkers() {
    if (_markers.isNotEmpty) {
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == 'delivery');
        if (_currentStep == 2) {
          _markers.add(
            Marker(
              markerId: const MarkerId('delivery'),
              position: _deliveryLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              infoWindow: InfoWindow(title: _deliveryPersonName),
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
      if (_currentStep == 2) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('delivery_route'),
            points: [_deliveryLocation, _customerLocation],
            color: Colors.blue,
            width: 3,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
    });
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
                    target: _deliveryLocation,
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
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.restaurant,
            color: Colors.orange.shade600,
            size: 24,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _restaurantName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Order $_orderNumber',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'LIVE',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.delivery_dining, color: Colors.blue.shade600, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                Text(
                  'Estimated arrival: $_estimatedTime',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (_currentStep) {
      case 0:
        return 'Order received';
      case 1:
        return 'Preparing your order';
      case 2:
        return 'On the way to you';
      case 3:
        return 'Delivered';
      default:
        return 'Processing';
    }
  }

  Widget _buildOrderStepper() {
    final steps = [
      {'title': 'Order Placed', 'icon': Icons.receipt_long},
      {'title': 'Preparing', 'icon': Icons.restaurant_menu},
      {'title': 'On the way', 'icon': Icons.delivery_dining},
      {'title': 'Delivered', 'icon': Icons.check_circle},
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
        const SizedBox(height: 15),
        ...steps.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> step = entry.value;
          bool isActive = index <= _currentStep;
          bool isCurrent = index == _currentStep;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: isCurrent ? _pulseController : kAlwaysCompleteAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isCurrent ? 1.0 + (_pulseController.value * 0.1) : 1.0,
                      child: Container(
                        width: 40,
                        height: 40,
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
                          step['icon'],
                          color: isActive ? Colors.white : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    step['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
                if (isActive && index < 3)
                  Icon(
                    Icons.check,
                    color: Colors.green,
                    size: 20,
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDeliveryPersonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.orange,
            child: Text(
              _deliveryPersonName.split(' ').map((e) => e[0]).join(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 15),
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
                    fontSize: 14,
                  ),
                ),
                Text(
                  'ETA: $_estimatedTime',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
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
                onPressed: _callDeliveryPerson,
                icon: const Icon(Icons.phone),
                color: Colors.green,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.1),
                ),
              ),
              IconButton(
                onPressed: _messageDeliveryPerson,
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

  Widget _buildOrderSummary() {
    final total = _orderItems.fold(0.0, (sum, item) => sum + item['price']);
    
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
        const SizedBox(height: 15),
        ..._orderItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['name'],
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                '\$${item['price'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )).toList(),
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _centerMapOnDelivery() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_deliveryLocation, 15),
      );
    }
  }

  void _callDeliveryPerson() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $_deliveryPersonName...'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _messageDeliveryPerson() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat with $_deliveryPersonName...'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}