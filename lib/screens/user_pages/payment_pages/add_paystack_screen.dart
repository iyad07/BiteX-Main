import 'package:bikex/models/payment_method.dart';
import 'package:flutter/material.dart';
import 'package:bikex/services/paystack_service.dart';

class AddPaystackScreen extends StatefulWidget {
  final bool selectMode;
  final Function(PaymentMethodModel)? onPaymentMethodAdded;
  
  const AddPaystackScreen({
    super.key,
    this.selectMode = false,
    this.onPaymentMethodAdded,
  });

  @override
  State<AddPaystackScreen> createState() => _AddPaystackScreenState();
}

class _AddPaystackScreenState extends State<AddPaystackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _titleController = TextEditingController();
  
  final PaystackService _paystackService = PaystackService();
  bool _isLoading = false;
  bool _isDefault = false;
  
  // This would be handled by the Paystack SDK in a real implementation
  String? _authorizationCode;
  String? _cardType;
  
  @override
  void initState() {
    super.initState();
    _titleController.text = 'My Paystack Card';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // This method would use the Paystack SDK in a real implementation
  Future<void> _verifyCard() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // For testing, we'll simulate the card verification
      // In a real app, you would use the Paystack SDK here
      
      // Test card number validation
      if (_cardNumberController.text != '4123456789123456') {
        throw Exception('Invalid test card number. Use 4123456789123456 for testing');
      }
      
      // Test expiry date validation
      final expiry = _expiryDateController.text;
      if (expiry.length != 5 || !expiry.contains('/')) {
        throw Exception('Invalid expiry date format. Use MM/YY');
      }
      
      // Test CVV validation
      if (_cvvController.text.length < 3) {
        throw Exception('Invalid CVV. Must be at least 3 digits');
      }
      
      // Simulate successful card verification
      await Future.delayed(const Duration(seconds: 2));
      
      // For testing purposes, we'll use a mock authorization code
      _authorizationCode = 'AUTH_${DateTime.now().millisecondsSinceEpoch}';
      
      // Determine card type from test card
      _cardType = 'Visa'; // The test card number is a Visa card
      
      // Add the payment method
      await _addPaystackMethod();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _addPaystackMethod() async {
    if (_formKey.currentState!.validate() && _authorizationCode != null) {
      try {
        final lastFourDigits = _cardNumberController.text.substring(_cardNumberController.text.length - 4);
        
        final newPaymentMethod = await _paystackService.addPaystackMethod(
          email: _emailController.text.trim(),
          authorizationCode: _authorizationCode!,
          cardType: _cardType ?? 'Card',
          lastFourDigits: lastFourDigits,
          expiryDate: _expiryDateController.text.trim(),
          title: _titleController.text.trim(),
          isDefault: _isDefault,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paystack payment method added successfully')),
          );
          
          // If in select mode and callback is provided, call it with the new payment method
          if (widget.selectMode && widget.onPaymentMethodAdded != null && newPaymentMethod != null) {
            widget.onPaymentMethodAdded!(newPaymentMethod as PaymentMethodModel);
          }
          
          Navigator.pop(context);
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
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Paystack Card'),
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
                    // Paystack logo and info
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.green,
                          size: 50,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: const Text(
                        'Paystack',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: const Text(
                        'Secure payments for Ghana and Africa',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Account nickname
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Card Nickname',
                        hintText: 'My Paystack Card',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a nickname for this card';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'your.email@example.com',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Card Number
                    TextFormField(
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Card Number',
                        hintText: '4111 1111 1111 1111',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your card number';
                        }
                        // Basic validation - would be more sophisticated in a real app
                        if (value.replaceAll(' ', '').length < 16) {
                          return 'Please enter a valid card number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Expiry and CVV row
                    Row(
                      children: [
                        // Expiry Date
                        Expanded(
                          child: TextFormField(
                            controller: _expiryDateController,
                            keyboardType: TextInputType.datetime,
                            decoration: const InputDecoration(
                              labelText: 'Expiry Date (MM/YY)',
                              hintText: '12/25',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (!RegExp(r'^\d\d/\d\d$').hasMatch(value)) {
                                return 'Use MM/YY format';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // CVV
                        Expanded(
                          child: TextFormField(
                            controller: _cvvController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              hintText: '123',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
                                return 'Invalid CVV';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Set as default
                    SwitchListTile(
                      title: const Text('Set as default payment method'),
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() {
                          _isDefault = value;
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),

                    const SizedBox(height: 8),
                    
                    // Payment info
                    Card(
                      elevation: 0,
                      color: Colors.grey[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.grey[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'About Paystack Payments',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '1. Your card details are secure with Paystack',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '2. You can pay with either Ghana Cedis (GHS) or other currencies',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '3. Both local and international cards are accepted',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Add button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _verifyCard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Paystack's color
                        ),
                        child: const Text(
                          'Add Card',
                          style: TextStyle(fontSize: 16),
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
