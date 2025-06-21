import 'package:bikex/components/buttons.dart';
import 'package:bikex/components/profile/profile_comp.dart';
import 'package:bikex/models/user.dart';
import 'package:bikex/services/auth_service.dart';
import 'package:flutter/material.dart';

class PersonalProfilePage extends StatefulWidget {
  const PersonalProfilePage({super.key});

  @override
  State<PersonalProfilePage> createState() => _PersonalProfilePageState();
}

class _PersonalProfilePageState extends State<PersonalProfilePage> {
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
        'title': 'FULL NAME',
        'icon': Icons.person,
        'subtitle': _user?.name ?? 'User',
      },
      {
        'title': 'EMAIL',
        'icon': Icons.email_rounded,
        'subtitle': _user?.email ?? 'No email',
      },
      {
        'title': 'PHONE',
        'icon': Icons.phone_rounded,
        'subtitle': _user?.phoneNumber.isNotEmpty ?? false
            ? _user!.phoneNumber
            : 'No phone number',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        leading: backButton(context),
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () {
              // Placeholder for edit functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit functionality coming soon!')),
              );
            },
            child: const Text(
              'EDIT',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
                const SizedBox(height: 16),
                // Menu Options
                persnalprofileGroup(firstGroup),
              ],
            ),
    );
  }
}