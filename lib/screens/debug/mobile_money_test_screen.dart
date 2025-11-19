import 'package:flutter/material.dart';
import 'package:bikex/models/payment_method.dart';
import 'package:bikex/services/mobile_money_service.dart';
import 'package:bikex/models/transaction.dart';

class MobileMoneyTestScreen extends StatefulWidget {
  const MobileMoneyTestScreen({super.key});

  @override
  State<MobileMoneyTestScreen> createState() => _MobileMoneyTestScreenState();
}

class _MobileMoneyTestScreenState extends State<MobileMoneyTestScreen> {
  final MobileMoneyService _mobileMoneyService = MobileMoneyService();
  final TextEditingController _phoneController = TextEditingController(text: '0241234567');
  final TextEditingController _amountController = TextEditingController(text: '50.00');
  
  PaymentMethodTypeModel _selectedProvider = PaymentMethodTypeModel.mtnMobileMoney;
  bool _isProcessing = false;
  String? _lastTransactionId;
  String _statusMessage = '';
  List<String> _debugLogs = [];

  void _addLog(String message) {
    setState(() {
      _debugLogs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    print(message);
  }

  Future<void> _testMobileMoneyPayment() async {
    if (_phoneController.text.isEmpty || _amountController.text.isEmpty) {
      _addLog('ERROR: Phone number and amount are required');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing payment...';
      _debugLogs.clear();
    });

    try {
      _addLog('Starting mobile money payment test');
      _addLog('Phone: ${_phoneController.text}');
      _addLog('Amount: ${_amountController.text}');
      _addLog('Provider: $_selectedProvider');

      // First, add a test payment method
      final paymentMethodId = await _mobileMoneyService.addMobileMoneyMethod(
        provider: _selectedProvider,
        phoneNumber: _phoneController.text,
        accountName: 'Test User',
        title: 'Test ${_getProviderName()}',
        isDefault: false,
      );

      _addLog('Created payment method: $paymentMethodId');

      // Process the payment
      final transaction = await _mobileMoneyService.processMobileMoneyPayment(
        orderId: 'test_order_${DateTime.now().millisecondsSinceEpoch}',
        paymentMethodId: paymentMethodId,
        amount: double.parse(_amountController.text),
      );

      _addLog('Payment initiated: ${transaction.id}');
      _addLog('Transaction status: ${transaction.status}');
      _addLog('Gateway transaction ID: ${transaction.gatewayTransactionId}');

      setState(() {
        _lastTransactionId = transaction.gatewayTransactionId;
        _statusMessage = 'Payment request sent. Check your phone!';
      });

      if (transaction.status == TransactionStatus.processing) {
        _showMobileMoneyPromptDialog(transaction.gatewayTransactionId!);
      }

    } catch (e) {
      _addLog('ERROR: $e');
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_lastTransactionId == null) {
      _addLog('ERROR: No transaction to check');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      _addLog('Checking payment status for: $_lastTransactionId');
      
      final status = await _mobileMoneyService.checkMobileMoneyStatus(_lastTransactionId!);
      
      _addLog('Payment status result: $status');
      
      setState(() {
        _statusMessage = 'Payment status: $status';
      });

    } catch (e) {
      _addLog('ERROR checking status: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showMobileMoneyPromptDialog(String transactionId) {
    bool isWaitingForPayment = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${_getProviderName()} Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getProviderColor(),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_android,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'A payment request has been sent to your phone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your phone and enter your PIN to approve the payment of GHS ${_amountController.text}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (isWaitingForPayment) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  'Waiting for confirmation...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Transaction ID',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      transactionId.substring(0, 12),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addLog('Payment cancelled by user');
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                setDialogState(() {
                  isWaitingForPayment = true;
                });
                
                _addLog('Checking payment status...');
                final status = await _mobileMoneyService.checkMobileMoneyStatus(transactionId);
                _addLog('Status check result: $status');
                
                if (status == TransactionStatus.completed) {
                  Navigator.of(context).pop();
                  _showSuccessDialog();
                } else {
                  setDialogState(() {
                    isWaitingForPayment = false;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment not confirmed. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('CHECK STATUS'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text('Amount: GHS ${_amountController.text}'),
            Text('Provider: ${_getProviderName()}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addLog('Payment completed successfully!');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getProviderName() {
    switch (_selectedProvider) {
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

  Color _getProviderColor() {
    switch (_selectedProvider) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Money Test'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Mobile Money Payment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Provider selection
                    const Text('Select Provider:'),
                    const SizedBox(height: 8),
                    DropdownButton<PaymentMethodTypeModel>(
                      value: _selectedProvider,
                      isExpanded: true,
                      onChanged: (value) {
                        setState(() {
                          _selectedProvider = value!;
                        });
                      },
                      items: const [
                        DropdownMenuItem(
                          value: PaymentMethodTypeModel.mtnMobileMoney,
                          child: Text('MTN Mobile Money'),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethodTypeModel.vodafoneCash,
                          child: Text('Vodafone Cash'),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethodTypeModel.airtelTigoMoney,
                          child: Text('AirtelTigo Money'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone number
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixText: '+233 ',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    
                    // Amount
                    TextField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (GHS)',
                        border: OutlineInputBorder(),
                        prefixText: 'GHS ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    
                    // Status
                    if (_statusMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          _statusMessage,
                          style: TextStyle(color: Colors.blue[800]),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _testMobileMoneyPayment,
                            child: _isProcessing
                                ? const CircularProgressIndicator()
                                : const Text('TEST PAYMENT'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _lastTransactionId == null || _isProcessing
                                ? null
                                : _checkPaymentStatus,
                            child: const Text('CHECK STATUS'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Debug logs
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Debug Logs',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _debugLogs.clear();
                              });
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _debugLogs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                _debugLogs[index],
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}