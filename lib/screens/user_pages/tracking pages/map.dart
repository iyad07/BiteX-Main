import 'package:bikex/components/order%20tracking/track_stepper.dart';
import 'package:bikex/models/order.dart';
import 'package:flutter/material.dart'; // Import Material
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart'; // Import Permission Handler

class TrackOrderPage extends StatefulWidget {
  final OrderModel order;
  const TrackOrderPage({super.key, required this.order});

  @override
  _TrackOrderPageState createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends State<TrackOrderPage> {
  LatLng? _currentLocation;
  final LatLng _restaurantLocation =
      const LatLng(37.7849, -122.4094); // Example restaurant location
  final List<Marker> _markers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission(); // Request location permission when the widget initializes
}

  Future<void> _requestLocationPermission() async {
    try {
      var status = await Permission.location.request();
      if (status.isGranted) {
        _getCurrentLocation();
      } else if (status.isDenied) {
        // Handle denied permission
        // Optionally, show a dialog or message to inform the user
      } else if (status.isPermanentlyDenied) {
        // Optionally, show a dialog or message to inform the user
        // and suggest to open app settings
        openAppSettings();
      } else {
      }
    } catch (e) {}
}

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(

          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
        _addMarkers();
      });
    } catch (e) {
    }
}

  void _addMarkers() {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
      _markers.add(
        Marker(
          markerId: MarkerId('restaurant_location'),
          position: _restaurantLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Track Order', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 50,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Map Widget
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation ?? const LatLng(0, 0),
                    zoom: 13.0,
                  ),
                  markers: Set<Marker>.from(_markers),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.normal,
                  onMapCreated: (GoogleMapController controller) {
                    // Store controller if needed for later use
                  },
                ),
                

                // Draggable Bottom Sheet
                DraggableScrollableSheet(
                  initialChildSize: 0.15,
                  minChildSize: 0.15,
                  maxChildSize: 0.6,
                  builder: (BuildContext context, ScrollController scrollController) {
                    return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                        ],
                        ),
                        child: SingleChildScrollView(
                          controller:
                          scrollController, // Enables smooth scrolling
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Drag Indicator
                                const Center(
                                  child: SizedBox(
                                    width: 50,
                                    height: 5,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius: BorderRadius.all(Radius.circular(10))
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                 // Restaurant Info
                                const Row(
                                  children: [
                                     SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                            color: Colors.grey,
                                            borderRadius: BorderRadius.all(Radius.circular(8))
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Uttora Coffee House",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Ordered At: 06 Sept, 10:00pm",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Order Details
                                const Text(
                                  "2x Burger\n4x Sandwich",
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 15),

                                // Estimated Delivery Time
                                const Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        "20 min",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        "ESTIMATED DELIVERY TIME",
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 15),

                                // Order Tracking Stepper
                                OrderTrackingStepper(),
                                const SizedBox(height: 60),

                                // Courier Info
                                const Divider(),
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Colors.grey,
                                      radius: 24,
                                      child: Icon(Icons.person, color: Colors.black),
                                    ),
                                    const SizedBox(width: 10),
                                     Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Robert F.",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          "Courier",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: Icon(Icons.phone,
                                          color: Colors.orange),
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.message,
                                          color: Colors.orange),
                                      onPressed: () {},
                                    ),
                                    
                                  ]
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          )
                        ));
                  },
                )
              ],
            ),
    );
  }
}