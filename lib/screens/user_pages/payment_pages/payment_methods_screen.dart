import 'package:flutter/material.dart';
import 'package:bikex/models/payment_method.dart';
import 'package:bikex/services/payment_service.dart';
import 'package:bikex/services/mobile_money_service.dart';
import 'package:bikex/screens/user_pages/payment_pages/add_mobile_money_screen.dart';
import 'package:bikex/screens/user_pages/payment_pages/add_paystack_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final bool selectMode;
  final Function(PaymentMethodModel)? onPaymentMethodSelected;

  const PaymentMethodsScreen({
    super.key,
    this.selectMode = false,
    this.onPaymentMethodSelected,
  });

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final PaymentService _paymentService = PaymentService();
  final MobileMoneyService _mobileMoneyService = MobileMoneyService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectMode 
            ? 'Select Payment Method' 
            : 'Payment Methods'),
        actions: [
          if (!widget.selectMode)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _showAddPaymentMethodOptions(context);
              },
              tooltip: 'Add payment method',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<PaymentMethodModel>>(
              stream: _paymentService.getUserPaymentMethods(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final paymentMethods = snapshot.data ?? [];

                if (paymentMethods.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.credit_card_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No payment methods found',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showAddPaymentMethodOptions(context);
                          },
                          icon: const Icon(Icons.add_card),
                          label: const Text('Add Payment Method'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: paymentMethods.length,
                  itemBuilder: (context, index) {
                    final paymentMethod = paymentMethods[index];
                    return PaymentMethodCard(
                      paymentMethod: paymentMethod,
                      onTap: widget.selectMode
                          ? () {
                              if (widget.onPaymentMethodSelected != null) {
                                widget.onPaymentMethodSelected!(paymentMethod);
                                Navigator.pop(context);
                              }
                            }
                          : null,
                      onDelete: widget.selectMode
                          ? null
                          : () async {
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Payment Method'),
                                  content: Text(
                                    'Are you sure you want to delete this payment method?\n\n${paymentMethod.displayName}',
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
                                  await _paymentService.deletePaymentMethod(paymentMethod.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Payment method deleted')),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              }
                            },
                      onSetDefault: (paymentMethod.isDefault || widget.selectMode)
                          ? null
                          : () async {
                              try {
                                setState(() {
                                  _isLoading = true;
                                });
                                await _paymentService.setPaymentMethodAsDefault(paymentMethod.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Default payment method updated')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              }
                            },
                    );
                  },
                );
              },
            ),
      floatingActionButton: !widget.selectMode
          ? FloatingActionButton(
              onPressed: () {
                _showAddPaymentMethodOptions(context);
              },
              tooltip: 'Add payment method',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  void _showAddPaymentMethodOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add Payment Method',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_android, color: Colors.orange),
            ),
            title: const Text('Mobile Money'),
            subtitle: const Text('MTN, Vodafone, AirtelTigo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMobileMoneyScreen(
                    selectMode: widget.selectMode,
                    onPaymentMethodAdded: widget.selectMode ? (paymentMethod) {
                      if (widget.onPaymentMethodSelected != null) {
                        widget.onPaymentMethodSelected!(paymentMethod);
                        Navigator.pop(context);
                      }
                    } : null,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet, color: Colors.green),
            ),
            title: const Text('Paystack'),
            subtitle: const Text('Card payments via Paystack'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPaystackScreen(
                    selectMode: widget.selectMode,
                    onPaymentMethodAdded: widget.selectMode ? (paymentMethod) {
                      if (widget.onPaymentMethodSelected != null) {
                        widget.onPaymentMethodSelected!(paymentMethod);
                        Navigator.pop(context);
                      }
                    } : null,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.credit_card, color: Colors.blue),
            ),
            title: const Text('Credit/Debit Card'),
            subtitle: const Text('Visa, Mastercard, etc.'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPaymentMethodScreen(
                    selectMode: widget.selectMode,
                    onPaymentMethodAdded: widget.selectMode ? (paymentMethod) {
                      if (widget.onPaymentMethodSelected != null) {
                        widget.onPaymentMethodSelected!(paymentMethod);
                        Navigator.pop(context);
                      }
                    } : null,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.payments_outlined, color: Colors.grey[700]),
            ),
            title: const Text('Cash on Delivery'),
            subtitle: const Text('Pay when your order arrives'),
            onTap: () async {
              Navigator.pop(context);
              try {
                final paymentService = PaymentService();
                await paymentService.addPaymentMethod(
                  cardNumber: '',
                  expiryDate: '',
                  type: PaymentMethodTypeModel.cashOnDelivery,
                  title: 'Cash on Delivery', 
                  isDefault: false,
                  cvv: '',
                  cardHolderName: '',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cash on Delivery added as a payment method')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    ),
  );

}
}

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethodModel paymentMethod;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;

  const PaymentMethodCard({
    super.key,
    required this.paymentMethod,
    this.onTap,
    this.onDelete,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: paymentMethod.isDefault
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card icon/image
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _getPaymentMethodIcon(),
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
                              paymentMethod.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (paymentMethod.isDefault)
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
                          paymentMethod.displayName,
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (paymentMethod.type == PaymentMethodTypeModel.creditCard ||
                            paymentMethod.type == PaymentMethodTypeModel.debitCard) ...[
                          const SizedBox(height: 4),
                          if (paymentMethod.expiryDate != null)
                            Text(
                              'Expires: ${paymentMethod.expiryDate}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (onDelete != null || onSetDefault != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (onSetDefault != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onSetDefault,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Set Default'),
                        ),
                      ),
                    if (onSetDefault != null && onDelete != null)
                      const SizedBox(width: 8),
                    if (onDelete != null)
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _getPaymentMethodIcon() {
    switch (paymentMethod.type) {
      case PaymentMethodTypeModel.creditCard:
      case PaymentMethodTypeModel.debitCard:
        final brand = paymentMethod.brand?.toLowerCase() ?? '';
        if (brand.contains('visa')) {
          return Image.asset('assets/icons/visa.png', width: 32, height: 32);
        } else if (brand.contains('mastercard')) {
          return Image.asset('assets/icons/mastercard.png', width: 32, height: 32);
        } else if (brand.contains('amex') || brand.contains('american express')) {
          return Image.asset('assets/icons/amex.png', width: 32, height: 32);
        } else if (brand.contains('discover')) {
          return Image.asset('assets/icons/discover.png', width: 32, height: 32);
        } else {
          return const Icon(Icons.credit_card, color: Colors.blue);
        }
      case PaymentMethodTypeModel.mtnMobileMoney:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.yellow[700],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.phone_android, color: Colors.white, size: 24),
        );
      case PaymentMethodTypeModel.vodafoneCash:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.phone_android, color: Colors.white, size: 24),
        );
      case PaymentMethodTypeModel.airtelTigoMoney:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.phone_android, color: Colors.white, size: 24),
        );
      case PaymentMethodTypeModel.mobileMoney:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.orange[700],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.phone_android, color: Colors.white, size: 24),
        );
      case PaymentMethodTypeModel.paypal:
        return Image.asset('assets/icons/paypal.png', width: 32, height: 32);
      case PaymentMethodTypeModel.applePay:
        return Image.asset('assets/icons/apple_pay.png', width: 32, height: 32);
      case PaymentMethodTypeModel.googlePay:
        return Image.asset('assets/icons/google_pay.png', width: 32, height: 32);
      case PaymentMethodTypeModel.cashOnDelivery:
        return const Icon(Icons.payments_outlined, color: Colors.green);
      default:
        return const Icon(Icons.payment, color: Colors.blue);
    }
  }

}

class AddPaymentMethodScreen extends StatefulWidget {
  final bool selectMode;
  final Function(PaymentMethodModel)? onPaymentMethodAdded;
  
  const AddPaymentMethodScreen({
    super.key,
    this.selectMode = false,
    this.onPaymentMethodAdded,
  });

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

  



class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderNameController = TextEditingController();
  final _titleController = TextEditingController();
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  bool _isDefault = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderNameController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter card number';
    }
    final cleanNumber = value.replaceAll(RegExp(r'\s+\b|\b\s'), '');
    if (cleanNumber.length != 16) {
      return 'Card number must be 16 digits';
    }
    return null;
  }

  String? _validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter expiry date';
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Use format MM/YY';
    }
    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter CVV';
    }
    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return 'CVV must be 3 or 4 digits';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      final expiryDate = _expiryDateController.text;
      final cvv = _cvvController.text;
      final cardHolderName = _cardHolderNameController.text;
      final title = _titleController.text;

      final newPaymentMethod = await _paymentService.addNewCard(
        cardNumber: cardNumber,
        expiryDate: expiryDate,
        cvv: cvv,
        cardHolderName: cardHolderName,
        title: title,
        isDefault: _isDefault,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment method added successfully')),
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
      if (mounted) {
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
        title: const Text('Add Card'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Card Nickname',
                  hintText: 'e.g. My Personal Card',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a nickname for this card';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: '1234 5678 9012 3456',
                ),
                keyboardType: TextInputType.number,
                validator: _validateCardNumber,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM/YY',
                      ),
                      validator: _validateExpiryDate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      validator: _validateCVV,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardHolderNameController,
                decoration: const InputDecoration(
                  labelText: 'Card Holder Name',
                  hintText: 'JOHN DOE',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter card holder name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
                title: const Text('Set as default payment method'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add Card'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
