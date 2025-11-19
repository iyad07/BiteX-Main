import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:bikex/data/restaurant_handler.dart';
import 'package:bikex/models/restaurant.dart';

class RestaurantMapScreen extends StatefulWidget {
  const RestaurantMapScreen({Key? key}) : super(key: key);

  @override
  _RestaurantMapScreenState createState() => _RestaurantMapScreenState();
}

class _RestaurantMapScreenState extends State<RestaurantMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  LatLng? _currentLocation;
  final LatLng _defaultLocation = const LatLng(5.6037, -0.1870); // Accra, Ghana
  Restaurant? _selectedRestaurant;
  bool _showRestaurantDetails = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    try {
      var status = await Permission.location.request();
      if (status.isGranted) {
        await _getCurrentLocation();
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      _setupMarkers();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _setupMarkers();
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
      setState(() => _currentLocation = _defaultLocation);
    }
  }

  void _setupMarkers() {
    final restaurantHandler = Provider.of<RestaurantHandler>(context, listen: false);
    final restaurants = restaurantHandler.getRestaurantsWithLocation();
    
    setState(() {
      _markers.clear();
      
      // Add current location marker if available
      if (_currentLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      }
      
      // Add restaurant markers
      for (final restaurant in restaurants) {
        if (restaurant.hasLocation) {
          _markers.add(
            Marker(
              markerId: MarkerId('restaurant_${restaurant.id}'),
              position: restaurant.location!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              infoWindow: InfoWindow(
                title: restaurant.restaurantName,
                snippet: '${restaurant.rating}⭐ • ${restaurant.deliveryTime}',
              ),
              onTap: () => _onRestaurantMarkerTap(restaurant),
            ),
          );
        }
      }
    });
  }

  void _onRestaurantMarkerTap(Restaurant restaurant) {
    setState(() {
      _selectedRestaurant = restaurant;
      _showRestaurantDetails = true;
    });
  }

  void _centerMapOnRestaurants() {
    if (_mapController == null || _markers.isEmpty) return;
    
    final bounds = _calculateBounds(_markers.map((m) => m.position).toList());
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final position in positions) {
      minLat = minLat < position.latitude ? minLat : position.latitude;
      maxLat = maxLat > position.latitude ? maxLat : position.latitude;
      minLng = minLng < position.longitude ? minLng : position.longitude;
      maxLng = maxLng > position.longitude ? maxLng : position.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Restaurants Near You',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_currentLocation != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: _centerMapOnRestaurants,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? _defaultLocation,
              zoom: 13.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              // Center map to show all restaurants after a short delay
              Future.delayed(const Duration(milliseconds: 500), () {
                _centerMapOnRestaurants();
              });
            },
            onTap: (_) {
              setState(() {
                _showRestaurantDetails = false;
                _selectedRestaurant = null;
              });
            },
          ),
          
          // Restaurant details bottom sheet
          if (_showRestaurantDetails && _selectedRestaurant != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: _buildRestaurantDetails(),
              ),
            ),
          
          // Distance-based restaurant list toggle
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: "restaurant_list",
              backgroundColor: Colors.white,
              onPressed: () => _showNearbyRestaurantsList(),
              child: const Icon(Icons.list, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantDetails() {
    if (_selectedRestaurant == null) return const SizedBox.shrink();
    
    final restaurant = _selectedRestaurant!;
    final restaurantHandler = Provider.of<RestaurantHandler>(context, listen: false);
    
    String distanceText = '';
    if (_currentLocation != null && restaurant.hasLocation) {
      final distance = restaurant.distanceFrom(_currentLocation!);
      if (distance != null) {
        distanceText = '${distance.toStringAsFixed(1)} km away';
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  restaurant.restaurantImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.restaurant),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.restaurantName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(' ${restaurant.rating}'),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, color: Colors.grey, size: 16),
                        Text(' ${restaurant.deliveryTime}'),
                      ],
                    ),
                    if (distanceText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.grey, size: 16),
                          Text(' $distanceText'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/restaurant',
                      arguments: restaurant,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('View Menu'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  // TODO: Implement directions functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Directions feature coming soon!')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.directions),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNearbyRestaurantsList() {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
      return;
    }

    final restaurantHandler = Provider.of<RestaurantHandler>(context, listen: false);
    final nearbyRestaurants = restaurantHandler.getRestaurantsByDistance(_currentLocation!);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Nearby Restaurants',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: nearbyRestaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = nearbyRestaurants[index];
                  final distance = restaurant.distanceFrom(_currentLocation!);
                  
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        restaurant.restaurantImage,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[300],
                          child: const Icon(Icons.restaurant),
                        ),
                      ),
                    ),
                    title: Text(restaurant.restaurantName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            Text(' ${restaurant.rating}'),
                            const SizedBox(width: 16),
                            Icon(Icons.access_time, color: Colors.grey, size: 16),
                            Text(' ${restaurant.deliveryTime}'),
                          ],
                        ),
                        if (distance != null)
                          Text('${distance.toStringAsFixed(1)} km away'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/restaurant',
                        arguments: restaurant,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}