import 'package:flutter/material.dart';
import 'package:bikex/models/payment_method.dart';
import 'package:bikex/services/mobile_money_service.dart';

class AddMobileMoneyScreen extends StatefulWidget {
  final bool selectMode;
  final Function(PaymentMethodModel)? onPaymentMethodAdded;
  
  const AddMobileMoneyScreen({
    super.key,
    this.selectMode = false,
    this.onPaymentMethodAdded,
  });

  @override
  State<AddMobileMoneyScreen> createState() => _AddMobileMoneyScreenState();
}

class _AddMobileMoneyScreenState extends State<AddMobileMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _titleController = TextEditingController();
  
  final MobileMoneyService _mobileMoneyService = MobileMoneyService();
  bool _isLoading = false;
  bool _isDefault = false;
  PaymentMethodTypeModel _selectedProvider = PaymentMethodTypeModel.mtnMobileMoney;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _accountNameController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addMobileMoneyMethod() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final newPaymentMethod = await _mobileMoneyService.addMobileMoneyMethod(
          provider: _selectedProvider,
          phoneNumber: _phoneNumberController.text.trim(),
          accountName: _accountNameController.text.trim(),
          title: _titleController.text.trim(),
          isDefault: _isDefault,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mobile Money payment method added successfully')),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Mobile Money'),
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
                    // Provider selection
                    const Text(
                      'Select Mobile Money Provider',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Mobile Money provider selection with logos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildProviderOption(
                          PaymentMethodTypeModel.mtnMobileMoney,
                          'assets/icons/mtn_mobile_money.png',
                          'MTN MoMo',
                          Colors.yellow[700]!,
                        ),
                        _buildProviderOption(
                          PaymentMethodTypeModel.vodafoneCash,
                          'assets/icons/vodafone_cash.png',
                          'Vodafone Cash', 
                          Colors.red,
                        ),
                        _buildProviderOption(
                          PaymentMethodTypeModel.airtelTigoMoney,
                          'assets/icons/airtel_tigo_money.png',
                          'AirtelTigo Money',
                          Colors.blue,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Account nickname
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Account Nickname',
                        hintText: 'e.g., My MTN MoMo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_circle),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a nickname for this account';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone number
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '0XX XXX XXXX',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your mobile money number';
                        }
                        // Basic Ghanaian phone number validation
                        final cleanValue = value.trim().replaceAll(' ', '');
                        if (cleanValue.length != 10) {
                          return 'Phone number must be 10 digits';
                        }
                        if (!cleanValue.startsWith('0')) {
                          return 'Phone number must start with 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Account name
                    TextFormField(
                      controller: _accountNameController,
                      decoration: const InputDecoration(
                        labelText: 'Account Name',
                        hintText: 'Name registered with mobile money account',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the account name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Default payment method toggle
                    SwitchListTile(
                      title: const Text('Set as Default Payment Method'),
                      subtitle: const Text(
                        'This payment method will be selected by default for checkout',
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

                    // Information about mobile money
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              const Text(
                                'How it works',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1. When you checkout, we\'ll send a prompt to your mobile money number',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '2. Authorize the payment with your PIN on your phone',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '3. Once approved, your order will be processed',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Add button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _addMobileMoneyMethod,
                        child: const Text(
                          'Add Mobile Money',
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

  Widget _buildProviderOption(
    PaymentMethodTypeModel provider, 
    String imagePath, 
    String name,
    Color color,
  ) {
    final isSelected = _selectedProvider == provider;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProvider = provider;
          
          // Prefill nickname based on selected provider
          if (_titleController.text.isEmpty || 
              _titleController.text == 'My MTN MoMo' ||
              _titleController.text == 'My Vodafone Cash' ||
              _titleController.text == 'My AirtelTigo Money') {
            switch (provider) {
              case PaymentMethodTypeModel.mtnMobileMoney:
                _titleController.text = 'My MTN MoMo';
                break;
              case PaymentMethodTypeModel.vodafoneCash:
                _titleController.text = 'My Vodafone Cash';
                break;
              case PaymentMethodTypeModel.airtelTigoMoney:
                _titleController.text = 'My AirtelTigo Money';
                break;
              default:
                break;
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // This would be the actual image in a real app
            // For now, let's use an Icon as a placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
          ],
        ),
      ),
    );
  }
}
