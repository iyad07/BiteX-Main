import 'package:bikex/components/buttons.dart';
import 'package:bikex/components/checkout/card_widget.dart';
import 'package:flutter/material.dart';
import 'package:bikex/models/payment_method.dart';
import 'package:bikex/models/transaction.dart';
import 'package:bikex/models/order.dart';
import 'package:bikex/services/payment_service.dart';
import 'package:bikex/services/mobile_money_service.dart';
import 'package:bikex/screens/user_pages/payment_pages/payment_methods_screen.dart';
import 'package:bikex/data/restaurant_handler.dart';
import 'package:provider/provider.dart';

class CheckOutPage extends StatefulWidget {
  final bool? hasCard;
  final String? orderId;
  final double? amount;
  final String? restaurantName;
  final VoidCallback? onPaymentSuccess;
  final VoidCallback? onPaymentFailure;
  
  const CheckOutPage({
    super.key, 
    this.hasCard = false,
    this.orderId,
    this.amount,
    this.restaurantName,
    this.onPaymentSuccess,
    this.onPaymentFailure,
  });

  @override
  State<CheckOutPage> createState() => _CheckOutPageState();
}

class _CheckOutPageState extends State<CheckOutPage> {
  final PaymentService _paymentService = PaymentService();
  final MobileMoneyService _mobileMoneyService = MobileMoneyService();
  
  PaymentMethodModel? _selectedPaymentMethod;
  bool _isProcessing = false;
  bool _isLoadingPaymentMethods = true;
  double _tipAmount = 0.0;
  final List<double> _tipPercentages = [0.0, 10.0, 15.0, 20.0];
  int _selectedTipIndex = 0;
  String? _errorMessage;
  TransactionModel? _transaction;
  OrderModel? _createdOrder;

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

  void _updateTipAmount(int tipIndex) {
    setState(() {
      _selectedTipIndex = tipIndex;
      _tipAmount = _getCurrentOrderAmount() * (_tipPercentages[tipIndex] / 100);
    });
  }

  double _getCurrentOrderAmount() {
    final restaurantHandler = Provider.of<RestaurantHandler>(context, listen: false);
    return restaurantHandler.getTotal();
  }

  Widget paymentMethodtile() {
    return Container(
      width: 93,
      height: 85,
      decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.all(Radius.circular(8))),
    );
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
      final currentAmount = widget.amount ?? _getCurrentOrderAmount();
      final currentOrderId = widget.orderId ?? DateTime.now().millisecondsSinceEpoch.toString();
      
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
          orderId: currentOrderId,
          paymentMethodId: _selectedPaymentMethod!.id,
          amount: currentAmount,
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
          orderId: currentOrderId,
          paymentMethodId: _selectedPaymentMethod!.id,
          amount: currentAmount,
          tipAmount: _tipAmount,
        );
      }
      
      setState(() {
        _transaction = transaction;
        _isProcessing = false;
      });
      
      // Show success and navigate
      if (transaction.isSuccessful) {
        // Create order after successful payment
        await _createOrder();
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

  Future<void> _createOrder() async {
    try {
      final restaurantHandler = Provider.of<RestaurantHandler>(context, listen: false);
      
      // Create order with customer details
      _createdOrder = await restaurantHandler.placeOrder(
        deliveryAddress: "123 Main Street, Accra", // TODO: Get from user profile/address
        customerName: "John Doe", // TODO: Get from user profile
        customerPhone: "+233 24 123 4567", // TODO: Get from user profile
        notes: "Please handle with care", // TODO: Get from order form if available
      );
    } catch (e) {
      debugPrint('Error creating order: $e');
      // Handle error appropriately
    }
  }

  void _showMobileMoneyPromptDialog(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mobile Money Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Transaction ID: $transactionId'),
              const SizedBox(height: 8),
              const Text(
                'Please check your phone for a mobile money prompt and enter your PIN to complete the payment.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog() {
    Navigator.of(context).pop(); // Close any existing dialogs
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final totalAmount = (widget.amount ?? _getCurrentOrderAmount()) + _tipAmount;
        return AlertDialog(
          title: const Text('Payment Successful!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text('Amount: \$${totalAmount.toStringAsFixed(2)}'),
              Text('(Including \$${_tipAmount.toStringAsFixed(2)} tip)'),
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
                Navigator.pushNamed(context, '/payment_successful', arguments: _createdOrder);
              },
              child: const Text('DONE'),
            ),
          ],
        );
      },
    );
  }

  Widget _getPaymentIcon(PaymentMethodModel paymentMethod) {
    switch (paymentMethod.type) {
      case PaymentMethodTypeModel.creditCard:
      case PaymentMethodTypeModel.debitCard:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue[700],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.credit_card, color: Colors.white, size: 24),
        );
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
          decoration: BoxDecoration(
            color: Colors.red[700],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.phone_android, color: Colors.white, size: 24),
        );
      case PaymentMethodTypeModel.airtelTigoMoney:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.green[700],
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
      default:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[700],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.payment, color: Colors.white, size: 24),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantHandler>(builder: (context, restaurantHandler, child) {
      final currentAmount = widget.amount ?? restaurantHandler.getTotal();
      final totalAmount = currentAmount + _tipAmount;
      
      return Scaffold(
        backgroundColor: Colors.white,
        bottomSheet: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'TOTAL:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    "\$${totalAmount.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                    ),
                  )
                ],
              ),
              SizedBox(height: 16),
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
                          'PAY \$${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
          ),
          title: Text(
            "Payment",
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal'),
                          Text('\$${currentAmount.toStringAsFixed(2)}'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tip'),
                          Text('\$${_tipAmount.toStringAsFixed(2)}'),
                        ],
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              
              // Tip Options Section
              Text(
                'Tip Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  for (int i = 0; i < _tipPercentages.length; i++)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _updateTipAmount(i),
                        child: Container(
                          margin: EdgeInsets.only(right: i < _tipPercentages.length - 1 ? 8 : 0),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedTipIndex == i
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              i == 0 ? 'No Tip' : '${_tipPercentages[i].toInt()}%',
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20),
              
              // Payment Method Section
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              
              if (_isLoadingPaymentMethods)
                Card(
                  child: ListTile(
                    leading: CircularProgressIndicator(),
                    title: Text('Loading payment methods...'),
                  ),
                )
              else if (_selectedPaymentMethod != null)
                Card(
                  child: ListTile(
                    leading: _getPaymentIcon(_selectedPaymentMethod!),
                    title: Text(_selectedPaymentMethod!.displayName),
                    subtitle: Text(_selectedPaymentMethod!.lastFourDigits ?? ''),
                    trailing: Icon(Icons.check_circle, color: Colors.green),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentMethodsScreen(
                            selectMode: true,
                            onPaymentMethodSelected: (paymentMethod) {
                              setState(() {
                                _selectedPaymentMethod = paymentMethod;
                                _errorMessage = null;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Card(
                  child: ListTile(
                    leading: Icon(Icons.add_circle_outline),
                    title: Text('Add Payment Method'),
                    subtitle: Text('Select a payment method to continue'),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentMethodsScreen(
                            selectMode: true,
                            onPaymentMethodSelected: (paymentMethod) {
                              setState(() {
                                _selectedPaymentMethod = paymentMethod;
                                _errorMessage = null;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              Spacer(),
              
              // Secure Payment Notice
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Secure Payment',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              SizedBox(height: 80), // Space for bottom sheet
            ],
          ),
        ),
    );
  });}}
