import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GoogleMapScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final LatLng? restaurantLocation;
  final Function(LatLng)? onMapCreated;

  const GoogleMapScreen({
    Key? key,
    this.initialPosition,
    this.restaurantLocation,
    this.onMapCreated,
  }) : super(key: key);

  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  LatLng? _currentLocation;
  final LatLng _defaultLocation = const LatLng(37.7749, -122.4194); // Default to San Francisco

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
      setState(() => _isLoading = false);
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
        _updateMarkers();
      });
    } catch (e) {
      setState(() => _currentLocation = _defaultLocation);
    }
  }

  void _updateMarkers() {
    final location = _currentLocation ?? widget.initialPosition ?? _defaultLocation;
    
    setState(() {
      _markers.clear();
      
      // Add current location marker
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );

      // Add restaurant marker if provided
      if (widget.restaurantLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('restaurant_location'),
            position: widget.restaurantLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'Restaurant'),
          ),
        );
      }
    });

    // Move camera to show all markers
    if (_mapController != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          _boundsFromLatLngList(
            _markers.map((m) => m.position).toList(),
          ),
          100.0, // Padding
        ),
      );
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation ?? widget.initialPosition ?? _defaultLocation,
          zoom: 15.0,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        onMapCreated: (controller) {
          _mapController = controller;
          if (widget.onMapCreated != null && _currentLocation != null) {
            widget.onMapCreated!(_currentLocation!);
          }
        },
      ),
    );
  }
}
