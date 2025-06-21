import 'package:flutter/material.dart';
import 'package:bikex/models/address.dart';
import 'package:bikex/services/address_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Address? address;
  final double? initialLatitude;
  final double? initialLongitude;
  final bool useCurrentLocation;

  const AddEditAddressScreen({
    super.key,
    this.address,
    this.initialLatitude,
    this.initialLongitude, 
    this.useCurrentLocation = false,
  });

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _instructionsController = TextEditingController();
  final AddressService _addressService = AddressService();
  
  // Default to center of map if no location provided
  double _latitude = 37.7749;
  double _longitude = -122.4194;
  bool _isDefault = false;
  bool _isLoading = false;
  bool _isLoadingMap = true;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _initializeAddress();
  }

  Future<void> _initializeAddress() async {
    setState(() {
      _isLoading = true;
      _isLoadingMap = true;
    });

    try {
      if (widget.address != null) {
        // Edit existing address
        _titleController.text = widget.address!.title;
        _addressLine1Controller.text = widget.address!.addressLine1;
        _addressLine2Controller.text = widget.address!.addressLine2 ?? '';
        _cityController.text = widget.address!.city;
        _stateController.text = widget.address!.state;
        _postalCodeController.text = widget.address!.postalCode;
        _countryController.text = widget.address!.country;
        _instructionsController.text = widget.address!.instructions ?? '';
        _isDefault = widget.address!.isDefault;
        _latitude = widget.address!.latitude;
        _longitude = widget.address!.longitude;
      } else if (widget.initialLatitude != null && widget.initialLongitude != null) {
        // Use provided coordinates
        _latitude = widget.initialLatitude!;
        _longitude = widget.initialLongitude!;
        
        if (widget.useCurrentLocation) {
          // Try to get address from coordinates
          final addressData = await _addressService.getAddressFromCoordinates(
            _latitude,
            _longitude,
          );
          
          _addressLine1Controller.text = addressData['addressLine1'] ?? '';
          _addressLine2Controller.text = addressData['addressLine2'] ?? '';
          _cityController.text = addressData['city'] ?? '';
          _stateController.text = addressData['state'] ?? '';
          _postalCodeController.text = addressData['postalCode'] ?? '';
          _countryController.text = addressData['country'] ?? '';
          _titleController.text = 'Home'; // Default title
        }
      } else {
        // Try to get current location
        try {
          final position = await _addressService.getCurrentLocation();
          _latitude = position.latitude;
          _longitude = position.longitude;
          
          // Try to get address from coordinates
          final addressData = await _addressService.getAddressFromCoordinates(
            _latitude,
            _longitude,
          );
          
          _addressLine1Controller.text = addressData['addressLine1'] ?? '';
          _addressLine2Controller.text = addressData['addressLine2'] ?? '';
          _cityController.text = addressData['city'] ?? '';
          _stateController.text = addressData['state'] ?? '';
          _postalCodeController.text = addressData['postalCode'] ?? '';
          _countryController.text = addressData['country'] ?? '';
          _titleController.text = 'Home'; // Default title
        } catch (e) {
          // Use default location (already set)
          print('Could not get current location: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMap = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _updateAddressFromMap() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final addressData = await _addressService.getAddressFromCoordinates(
        _latitude,
        _longitude,
      );
      
      setState(() {
        _addressLine1Controller.text = addressData['addressLine1'] ?? '';
        _addressLine2Controller.text = addressData['addressLine2'] ?? '';
        _cityController.text = addressData['city'] ?? '';
        _stateController.text = addressData['state'] ?? '';
        _postalCodeController.text = addressData['postalCode'] ?? '';
        _countryController.text = addressData['country'] ?? '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting address from location: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchAddress() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Build full address string for geocoding
      final String searchAddress = [
        _addressLine1Controller.text,
        _addressLine2Controller.text,
        _cityController.text,
        _stateController.text,
        _postalCodeController.text,
        _countryController.text,
      ].where((part) => part.isNotEmpty).join(', ');
      
      final coordinates = await _addressService.getCoordinatesFromAddress(searchAddress);
      
      setState(() {
        _latitude = coordinates['latitude']!;
        _longitude = coordinates['longitude']!;
      });
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_latitude, _longitude),
          18,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finding location: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoading = true;
        });
        
        if (widget.address == null) {
          // Add new address
          await _addressService.addAddress(
            title: _titleController.text,
            addressLine1: _addressLine1Controller.text,
            addressLine2: _addressLine2Controller.text.isEmpty 
                ? null 
                : _addressLine2Controller.text,
            city: _cityController.text,
            state: _stateController.text,
            postalCode: _postalCodeController.text,
            country: _countryController.text,
            latitude: _latitude,
            longitude: _longitude,
            instructions: _instructionsController.text.isEmpty 
                ? null 
                : _instructionsController.text,
            isDefault: _isDefault,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Address added successfully')),
            );
            Navigator.pop(context);
          }
        } else {
          // Update existing address
          await _addressService.updateAddress(
            addressId: widget.address!.id,
            title: _titleController.text,
            addressLine1: _addressLine1Controller.text,
            addressLine2: _addressLine2Controller.text.isEmpty 
                ? null 
                : _addressLine2Controller.text,
            city: _cityController.text,
            state: _stateController.text,
            postalCode: _postalCodeController.text,
            country: _countryController.text,
            latitude: _latitude,
            longitude: _longitude,
            instructions: _instructionsController.text.isEmpty 
                ? null 
                : _instructionsController.text,
            isDefault: _isDefault,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Address updated successfully')),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add New Address' : 'Edit Address'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Map
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            _isLoadingMap
                                ? const Center(child: CircularProgressIndicator())
                                : GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: LatLng(_latitude, _longitude),
                                      zoom: 16,
                                    ),
                                    onMapCreated: (GoogleMapController controller) {
                                      _mapController = controller;
                                    },
                                    onTap: (tapPosition) {
                                      setState(() {
                                        _latitude = tapPosition.latitude;
                                        _longitude = tapPosition.longitude;
                                      });
                                      _updateAddressFromMap();
                                    },
                                    markers: {
                                      Marker(
                                        markerId: const MarkerId('selected_location'),
                                        position: LatLng(_latitude, _longitude),
                                        infoWindow: const InfoWindow(
                                          title: 'Selected Location',
                                        ),
                                      ),
                                    },
                                  ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Column(
                                children: [
                                  FloatingActionButton.small(
                                    onPressed: () async {
                                      try {
                                        final position = await _addressService.getCurrentLocation();
                                        setState(() {
                                          _latitude = position.latitude;
                                          _longitude = position.longitude;
                                        });
                                        _mapController?.animateCamera(
                                          CameraUpdate.newLatLngZoom(
                                            LatLng(_latitude, _longitude),
                                            18,
                                          ),
                                        );
                                        _updateAddressFromMap();
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    },
                                    heroTag: 'location',
                                    child: const Icon(Icons.my_location),
                                  ),
                                  const SizedBox(height: 8),
                                  FloatingActionButton.small(
                                    onPressed: _searchAddress,
                                    heroTag: 'search',
                                    child: const Icon(Icons.search),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Address Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Address title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Address Title',
                        hintText: 'Home, Work, etc.',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an address title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Address line 1
                    TextFormField(
                      controller: _addressLine1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Street Address',
                        hintText: 'Street name and number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your street address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Address line 2
                    TextFormField(
                      controller: _addressLine2Controller,
                      decoration: const InputDecoration(
                        labelText: 'Apartment, Suite, etc. (optional)',
                        hintText: 'Apt #, Floor, Building, etc.',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.apartment),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // City and State
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(
                              labelText: 'State/Province',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.map),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Postal code and Country
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _postalCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Postal/ZIP Code',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.markunread_mailbox),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _countryController,
                            decoration: const InputDecoration(
                              labelText: 'Country',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.flag),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Delivery instructions
                    TextFormField(
                      controller: _instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Instructions (optional)',
                        hintText: 'E.g., "Gate code: 1234", "Call when at door"',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // Default address toggle
                    SwitchListTile(
                      title: const Text('Set as Default Address'),
                      subtitle: const Text(
                        'This address will be selected by default for delivery',
                      ),
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() {
                          _isDefault = value;
                        });
                      },
                      secondary: Icon(
                        Icons.check_circle,
                        color: _isDefault ? Theme.of(context).primaryColor : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveAddress,
                        child: Text(
                          widget.address == null ? 'Add Address' : 'Update Address',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
