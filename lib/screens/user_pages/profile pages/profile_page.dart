import 'package:bikex/components/buttons.dart';
import 'package:bikex/components/profile/profile_comp.dart';
import 'package:bikex/models/user.dart';
import 'package:bikex/services/auth_service.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  RestaurantUser? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    final user = await authService.getRestaurantUser();
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> firstGroup = [
      {
        'title': 'Personal Info',
        'icon': Icons.person,
        'onTap': () {
          Navigator.pushNamed(context, '/personal_profile');
        }
      },
      {
        'title': 'Addresses', 
        'icon': Icons.location_on,
        'onTap': () {
          Navigator.pushNamed(context, '/addresses');
        }
      },
    ];
    final List<Map<String, dynamic>> secondGroup = [
      {'title': 'Cart', 'icon': Icons.shopping_cart},
      {'title': 'Favourite', 'icon': Icons.favorite},
      {'title': 'Notifications', 'icon': Icons.notifications},
      {
        'title': 'Payment Methods', 
        'icon': Icons.payment,
        'onTap': () {
          Navigator.pushNamed(context, '/payment_methods');
        }
      },
      {
        'title': 'Transaction History', 
        'icon': Icons.receipt_long,
        'onTap': () {
          Navigator.pushNamed(context, '/transaction_history');
        }
      },
    ];
    final List<Map<String, dynamic>> thirdGroup = [
      {'title': 'FAQs', 'icon': Icons.help},
      {'title': 'User Reviews', 'icon': Icons.rate_review},
      {'title': 'Settings', 'icon': Icons.settings},
    ];
    final List<Map<String, dynamic>> fourthGroup = [
      {
        'title': 'Log Out',
        'icon': Icons.logout,
        'onTap': () async {
          await AuthService().signOut();
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
      },
    ];

    return Scaffold(
      appBar: AppBar(
        leading: backButton(context),
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // User Profile Section
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user?.name ?? 'User',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _user?.email ?? 'No email',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Menu Options
                Expanded(
                  flex: 2,
                  child: profilePageGroup(firstGroup),
                ),
                const SizedBox(height: 16),
                Expanded(
                  flex: 4,
                  child: profilePageGroup(secondGroup),
                ),
                const SizedBox(height: 16),
                Expanded(
                  flex: 3,
                  child: profilePageGroup(thirdGroup),
                ),
                const SizedBox(height: 16),
                Expanded(
                  flex: 1,
                  child: profilePageGroup(fourthGroup),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}