import 'package:bikex/components/buttons.dart';

import 'package:bikex/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    // Send verification email when the page loads
    _sendVerificationEmail();
  }

  void _sendVerificationEmail() async {
    User? user = _authService.getCurrentUser();
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send verification email.')),
        );
      }
    }
  }

  void _verifyEmail() async {
    setState(() {
      _isLoading = true;
    });

    User? user = _authService.getCurrentUser();
    if (user != null) {
      await user.reload(); // Refresh user state
      if (user.emailVerified) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Email not verified. Please check your inbox.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in.')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get email from arguments
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    _email = args?['email'] ?? 'example@gmail.com';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 120),
              const Text(
                "Verification",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "We have sent a verification link to your email",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                _email!,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "VERIFICATION",
                      style: TextStyle(color: Colors.grey),
                    ),
                    textButton("Resend Email", _sendVerificationEmail),
                  ],
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : elevatedButton("VERIFY", _verifyEmail),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}