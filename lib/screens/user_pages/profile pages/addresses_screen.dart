import 'package:bikex/screens/user_pages/profile%20pages/add_edit_address_screen.dart';
import 'package:flutter/material.dart';
import 'package:bikex/models/address.dart';
import 'package:bikex/services/address_service.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final AddressService _addressService = AddressService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditAddressScreen(),
                ),
              );
            },
            tooltip: 'Add new address',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Address>>(
              stream: _addressService.getUserAddresses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final addresses = snapshot.data ?? [];

                if (addresses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No saved addresses found',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddEditAddressScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_location_alt),
                          label: const Text('Add New Address'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return AddressCard(
                      address: address,
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditAddressScreen(address: address),
                          ),
                        );
                      },
                      onDelete: () async {
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Address'),
                            content: Text(
                              'Are you sure you want to delete this address?\n\n${address.title}: ${address.shortAddress}',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('CANCEL'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('DELETE'),
                              ),
                            ],
                          ),
                        );

                        if (shouldDelete == true) {
                          try {
                            setState(() {
                              _isLoading = true;
                            });
                            await _addressService.deleteAddress(address.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Address deleted')),
                              );
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
                      },
                      onSetDefault: address.isDefault
                          ? null
                          : () async {
                              try {
                                setState(() {
                                  _isLoading = true;
                                });
                                await _addressService.setAddressAsDefault(address.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Default address updated')),
                                  );
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
                            },
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            setState(() {
              _isLoading = true;
            });
            final position = await _addressService.getCurrentLocation();
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditAddressScreen(
                    initialLatitude: position.latitude,
                    initialLongitude: position.longitude,
                    useCurrentLocation: true,
                  ),
                ),
              );
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
        },
        tooltip: 'Use current location',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

class AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  const AddressCard({
    super.key,
    required this.address,
    required this.onEdit,
    required this.onDelete,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: address.isDefault
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getAddressIcon(address.title.toLowerCase()),
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            address.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (address.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Default',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        address.addressLine1,
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (address.addressLine2 != null &&
                          address.addressLine2!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          address.addressLine2!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${address.city}, ${address.state} ${address.postalCode}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.country,
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (address.instructions != null &&
                          address.instructions!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Instructions: ${address.instructions}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSetDefault,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Set Default'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: onSetDefault == null
                          ? Colors.grey
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAddressIcon(String title) {
    if (title.contains('home')) {
      return Icons.home;
    } else if (title.contains('work') || title.contains('office')) {
      return Icons.work;
    } else if (title.contains('school') || title.contains('college')) {
      return Icons.school;
    } else if (title.contains('gym')) {
      return Icons.fitness_center;
    } else if (title.contains('friend') || title.contains('family')) {
      return Icons.people;
    } else {
      return Icons.location_on;
    }
  }
}
