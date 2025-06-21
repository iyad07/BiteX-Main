import 'package:flutter/material.dart';
import 'package:bikex/models/payment_method.dart';
import 'package:bikex/models/transaction.dart';
import 'package:bikex/services/payment_service.dart';
import 'package:bikex/services/mobile_money_service.dart';
import 'package:bikex/screens/user_pages/payment_pages/payment_methods_screen.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String restaurantName;
  final VoidCallback? onPaymentSuccess;
  final VoidCallback? onPaymentFailure;

  const PaymentCheckoutScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.restaurantName,
    this.onPaymentSuccess,
    this.onPaymentFailure,
  });

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  final PaymentService _paymentService = PaymentService();
  final MobileMoneyService _mobileMoneyService = MobileMoneyService();
  
  PaymentMethodModel? _selectedPaymentMethod;
  bool _isProcessing = false;
  bool _isLoadingPaymentMethods = true;
  double _tipAmount = 0.0;
  final List<double> _tipPercentages = [0, 5, 10, 15, 20, 25];
  int _selectedTipIndex = 0;
  String? _errorMessage;
  TransactionModel? _transaction;

  @override
  void initState() {
    super.initState();
    _loadDefaultPaymentMethod();
  }

  Future<void> _loadDefaultPaymentMethod() async {
    try {
      setState(() {
        _isLoadingPaymentMethods = true;
      });
      
      final defaultMethod = await _paymentService.getDefaultPaymentMethod();
      
      setState(() {
        _selectedPaymentMethod = defaultMethod;
        _isLoadingPaymentMethods = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading payment methods: $e';
        _isLoadingPaymentMethods = false;
      });
    }
  }

  void _updateTipAmount(int index) {
    setState(() {
      _selectedTipIndex = index;
      
      if (index == 0) {
        _tipAmount = 0.0;
      } else {
        final tipPercentage = _tipPercentages[index];
        _tipAmount = (widget.amount * tipPercentage / 100).roundToDouble();
      }
    });
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      setState(() {
        _errorMessage = 'Please select a payment method';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Check if this is a mobile money payment
      bool isMobileMoney = [
        PaymentMethodTypeModel.mtnMobileMoney,
        PaymentMethodTypeModel.vodafoneCash,
        PaymentMethodTypeModel.airtelTigoMoney,
        PaymentMethodTypeModel.mobileMoney,
      ].contains(_selectedPaymentMethod!.type);
      
      TransactionModel transaction;
      
      if (isMobileMoney) {
        // Process as mobile money payment
        transaction = await _mobileMoneyService.processMobileMoneyPayment(
          orderId: widget.orderId,
          paymentMethodId: _selectedPaymentMethod!.id,
          amount: widget.amount,
          tipAmount: _tipAmount,
        );
        
        // Check payment status after a delay (simulate mobile money approval)
        if (transaction.status == TransactionStatus.processing) {
          // Show mobile money prompt dialog
          _showMobileMoneyPromptDialog(transaction.gatewayTransactionId!);
          
          // Wait for a few seconds to simulate user responding to prompt
          await Future.delayed(const Duration(seconds: 5));
          
          // Check the status
          final status = await _mobileMoneyService.checkMobileMoneyStatus(
            transaction.gatewayTransactionId!,
          );
          
          if (status == TransactionStatus.completed) {
            transaction = TransactionModel(
              id: transaction.id,
              userId: transaction.userId,
              orderId: transaction.orderId,
              paymentMethodId: transaction.paymentMethodId,
              type: transaction.type,
              status: TransactionStatus.completed,
              amount: transaction.amount,
              currency: transaction.currency,
              gatewayTransactionId: transaction.gatewayTransactionId,
              gatewayResponse: transaction.gatewayResponse,
              createdAt: transaction.createdAt,
              completedAt: DateTime.now(),
            );
          } else {
            transaction = TransactionModel(
              id: transaction.id,
              userId: transaction.userId,
              orderId: transaction.orderId,
              paymentMethodId: transaction.paymentMethodId,
              type: transaction.type,
              status: TransactionStatus.failed,
              amount: transaction.amount,
              currency: transaction.currency,
              gatewayTransactionId: transaction.gatewayTransactionId,
              gatewayResponse: transaction.gatewayResponse,
              createdAt: transaction.createdAt,
              errorMessage: 'Payment was not confirmed',
            );
          }
        }
      } else {
        // Process as regular card payment
        transaction = await _paymentService.processPayment(
          orderId: widget.orderId,
          paymentMethodId: _selectedPaymentMethod!.id,
          amount: widget.amount,
          tipAmount: _tipAmount,
        );
      }
      
      setState(() {
        _transaction = transaction;
        _isProcessing = false;
      });
      
      // Show success and navigate
      if (transaction.isSuccessful) {
        _showSuccessDialog();
        if (widget.onPaymentSuccess != null) {
          widget.onPaymentSuccess!();
        }
      } else {
        setState(() {
          _errorMessage = 'Payment failed: ${transaction.errorMessage ?? 'Unknown error'}';
        });
        if (widget.onPaymentFailure != null) {
          widget.onPaymentFailure!();
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error processing payment: $e';
      });
      if (widget.onPaymentFailure != null) {
        widget.onPaymentFailure!();
      }
    }
  }
  
  // Show mobile money prompt dialog to simulate the mobile money payment flow
  void _showMobileMoneyPromptDialog(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('${_getMobileMoneyProviderName()} Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getMobileMoneyColor(),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_android,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text('A payment request has been sent to your phone number.'),
            const SizedBox(height: 8),
            Text(
              'Please check your phone and enter your PIN to approve the payment of GHS ${(widget.amount + _tipAmount).toStringAsFixed(2)}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Transaction ID: ${transactionId.substring(0, 8)}...',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
    
    // Automatically close dialog after a few seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }
  
  String _getMobileMoneyProviderName() {
    if (_selectedPaymentMethod == null) return 'Mobile Money';
    
    switch (_selectedPaymentMethod!.type) {
      case PaymentMethodTypeModel.mtnMobileMoney:
        return 'MTN Mobile Money';
      case PaymentMethodTypeModel.vodafoneCash:
        return 'Vodafone Cash';
      case PaymentMethodTypeModel.airtelTigoMoney:
        return 'AirtelTigo Money';
      default:
        return 'Mobile Money';
    }
  }
  
  Color _getMobileMoneyColor() {
    if (_selectedPaymentMethod == null) return Colors.orange;
    
    switch (_selectedPaymentMethod!.type) {
      case PaymentMethodTypeModel.mtnMobileMoney:
        return Colors.yellow[700]!;
      case PaymentMethodTypeModel.vodafoneCash:
        return Colors.red;
      case PaymentMethodTypeModel.airtelTigoMoney:
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
  
  Widget _getPaymentIcon(PaymentMethodModel paymentMethod) {
    switch (paymentMethod.type) {
      case PaymentMethodTypeModel.creditCard:
      case PaymentMethodTypeModel.debitCard:
        final brand = paymentMethod.brand?.toLowerCase() ?? '';
        if (brand.contains('visa')) {
          return Image.asset('assets/icons/visa.png', width: 32, height: 32);
        } else if (brand.contains('mastercard')) {
          return Image.asset('assets/icons/mastercard.png', width: 32, height: 32);
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
      case PaymentMethodTypeModel.cashOnDelivery:
        return const Icon(Icons.payments_outlined, color: Colors.green);
      default:
        return const Icon(Icons.payment, color: Colors.blue);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text('Your order from ${widget.restaurantName} has been placed!'),
            const SizedBox(height: 8),
            Text(
              'Total Paid: \$${(widget.amount + _tipAmount).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_tipAmount > 0) ...[
              const SizedBox(height: 4),
              Text('(Including \$${_tipAmount.toStringAsFixed(2)} tip)'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('VIEW ORDER'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              // Return to home screen or go to tracking page
              Navigator.of(context).pushReplacementNamed('/dashboard');
            },
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalAmount = widget.amount + _tipAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: _isLoadingPaymentMethods
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal'),
                              Text('\$${widget.amount.toStringAsFixed(2)}'),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tip'),
                              Text('\$${_tipAmount.toStringAsFixed(2)}'),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '\$${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tip options
                  const Text(
                    'Add a Tip',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _tipPercentages.length,
                      itemBuilder: (context, index) {
                        final tipPercentage = _tipPercentages[index];
                        final isSelected = _selectedTipIndex == index;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              tipPercentage == 0
                                  ? 'No Tip'
                                  : '$tipPercentage%',
                              style: TextStyle(
                                color: isSelected ? Colors.white : null,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _updateTipAmount(index);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Payment method
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Selected payment method or select button
                  if (_selectedPaymentMethod != null)
                    InkWell(
                      onTap: () async {
                        final PaymentMethodModel? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentMethodsScreen(
                              selectMode: true,
                              onPaymentMethodSelected: (method) {
                                setState(() {
                                  _selectedPaymentMethod = method;
                                });
                              },
                            ),
                          ),
                        );
                        
                        if (result != null) {
                          setState(() {
                            _selectedPaymentMethod = result;
                          });
                        }
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _getPaymentIcon(_selectedPaymentMethod!),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedPaymentMethod!.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _selectedPaymentMethod!.displayName,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () async {
                        final PaymentMethodModel? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentMethodsScreen(
                              selectMode: true,
                              onPaymentMethodSelected: (method) {
                                setState(() {
                                  _selectedPaymentMethod = method;
                                });
                              },
                            ),
                          ),
                        );
                        
                        if (result != null) {
                          setState(() {
                            _selectedPaymentMethod = result;
                          });
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Select Payment Method'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Pay button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing || _selectedPaymentMethod == null
                          ? null
                          : _processPayment,
                      child: _isProcessing
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : Text(
                              'Pay \$${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Secure payment notice
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Secure Payment',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
