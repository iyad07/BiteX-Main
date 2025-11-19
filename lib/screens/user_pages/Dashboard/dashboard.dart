import 'package:bikex/components/buttons.dart';
import 'package:bikex/components/dashboard/restaurant_card.dart';
import 'package:bikex/components/dashboard/searchbar.dart';

import 'package:bikex/data/restaurant_handler.dart';
import 'package:bikex/models/user.dart';
import 'package:bikex/screens/user_pages/Dashboard/search_page.dart';
import 'package:bikex/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  RestaurantDashboardState createState() => RestaurantDashboardState();
}

class RestaurantDashboardState extends State<RestaurantDashboard> {
  String selectedCategory = 'All';
  String? selectedAddress;
  RestaurantUser? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    final fbUser = authService.getCurrentUser();
    
    if (fbUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(fbUser.uid)
          .get();
      
      // Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          user = RestaurantUser(
            id: fbUser.uid,
            name: userDoc.get('name') ?? fbUser.displayName ?? 'User',
            email: fbUser.email ?? '',
            address: List<String>.from(userDoc.get('address') ?? []),
            phoneNumber: userDoc.get('phoneNumber') ?? '',
          );
          selectedAddress = user!.address.isNotEmpty ? user!.address.first : null;
          isLoading = false;
        });
      }
    }
  }

  void _showUserDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${user!.name}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Email: ${user!.email}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Phone: ${user!.phoneNumber}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Addresses:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...user!.address.map((addr) => Text('• $addr', style: const TextStyle(fontSize: 14))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantHandler>(
      builder: (context, value, child) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leadingWidth: 56,
          leading: menuButton(context),
          backgroundColor: Colors.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DELIVER TO',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : DropdownButton<String>(
                          value: selectedAddress,
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.black),
                          items: user?.address.map((address) {
                            return DropdownMenuItem<String>(
                              value: address,
                              child: Text(address),
                            );
                          }).toList() ?? [],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedAddress = value;
                              });
                            }
                          },
                        ),
                ],
              ),
            ],
          ),
          actions: [
            GestureDetector(
              onTap: _showUserDetails,
              child: Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(right: 16),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/restaurant_map');
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(right: 16),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange,
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/my_cart');
              },
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(right: 16),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${value.cartItems.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 16),
                      child: Row(
                        children: [
                          Text(
                            'Hey ${user!.name}, ',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const Text(
                            'Good day!',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SearchPage()),
                          );
                        },
                        child: searchBar(enabled: false),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Open Restaurants',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: value.restaurants.length,
                        itemBuilder: (context, index) => RestaurantCard(
                          onTap: () => Navigator.pushNamed(context, '/restaurant',
                              arguments: value.restaurants[index]),
                          restaurant: value.restaurants[index],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}