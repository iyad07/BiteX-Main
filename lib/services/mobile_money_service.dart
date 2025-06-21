import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikex/models/payment_method.dart';
import 'package:bikex/models/transaction.dart';

class MobileMoneyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // This would normally be your payment gateway endpoint, e.g., Paystack, Flutterwave, etc.
  final String _gatewayApiUrl = 'https://api.example.com/mobile-money';
  
  static final MobileMoneyService _instance = MobileMoneyService._internal();
  factory MobileMoneyService() => _instance;
  
  MobileMoneyService._internal();

  // Add a new mobile money payment method
  Future<String> addMobileMoneyMethod({
    required PaymentMethodTypeModel provider, // MTN, Vodafone, AirtelTigo, etc.
    required String phoneNumber,
    required String accountName,
    required String title,
    bool isDefault = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to add a payment method');
      }

      // If this is set as default, unset any existing default
      if (isDefault) {
        await _unsetCurrentDefaultPaymentMethod(user.uid);
      }

      // Format the phone number for display
      final lastFourDigits = phoneNumber.substring(phoneNumber.length - 4);
      
      String providerName;
      switch (provider) {
        case PaymentMethodTypeModel.mtnMobileMoney:
          providerName = 'MTN Mobile Money';
          break;
        case PaymentMethodTypeModel.vodafoneCash:
          providerName = 'Vodafone Cash';
          break;
        case PaymentMethodTypeModel.airtelTigoMoney:
          providerName = 'AirtelTigo Money';
          break;
        default:
          providerName = 'Mobile Money';
      }

      // Create new payment method document
      final docRef = await _firestore.collection('payment_methods').add({
        'userId': user.uid,
        'type': provider.toString().split('.').last,
        'title': title,
        'lastFourDigits': lastFourDigits,
        'phoneNumber': phoneNumber,
        'accountName': accountName,
        'brand': providerName,
        'isDefault': isDefault,
        'createdAt': Timestamp.now(),
      });

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Process a mobile money payment
  Future<TransactionModel> processMobileMoneyPayment({
    required String orderId,
    required String paymentMethodId,
    required double amount,
    String currency = 'GHS',
    double? tipAmount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to process a payment');
      }

      // Get payment method
      final paymentMethodDoc = await _firestore.collection('payment_methods').doc(paymentMethodId).get();
      if (!paymentMethodDoc.exists) {
        throw Exception('Payment method not found');
      }

      final paymentMethodData = paymentMethodDoc.data()!;
      final phoneNumber = paymentMethodData['phoneNumber'] as String;
      final providerType = paymentMethodData['type'] as String;

      // In a real app, this would be an API call to a mobile money payment processor
      final mobileMoneyResponse = await _processMobileMoneyRequest(
        phoneNumber: phoneNumber,
        amount: amount + (tipAmount ?? 0.0),
        provider: providerType,
        orderId: orderId,
      );

      // Record transaction
      final totalAmount = amount + (tipAmount ?? 0.0);
      final transaction = await _recordTransaction(
        userId: user.uid,
        orderId: orderId,
        paymentMethodId: paymentMethodId,
        type: TransactionType.payment,
        status: TransactionStatus.processing, // Mobile money starts as processing
        amount: totalAmount,
        currency: currency,
        gatewayTransactionId: mobileMoneyResponse['transactionId'],
        gatewayResponse: mobileMoneyResponse,
      );

      // If tip amount is included, record as separate transaction
      if (tipAmount != null && tipAmount > 0) {
        await _recordTransaction(
          userId: user.uid,
          orderId: orderId,
          paymentMethodId: paymentMethodId,
          type: TransactionType.tip,
          status: TransactionStatus.processing,
          amount: tipAmount,
          currency: currency,
          gatewayTransactionId: mobileMoneyResponse['transactionId'],
        );
      }

      return transaction;
    } catch (e) {
      // Record failed transaction
      final user = _auth.currentUser;
      if (user != null) {
        await _recordTransaction(
          userId: user.uid,
          orderId: orderId,
          paymentMethodId: paymentMethodId,
          type: TransactionType.payment,
          status: TransactionStatus.failed,
          amount: amount + (tipAmount ?? 0.0),
          currency: 'GHS',
          errorMessage: e.toString(),
        );
      }
      rethrow;
    }
  }

  // Simulate mobile money payment processing
  // In a real app, this would call an actual payment gateway API
  Future<Map<String, dynamic>> _processMobileMoneyRequest({
    required String phoneNumber,
    required double amount,
    required String provider,
    required String orderId,
  }) async {
    // In a real application, this would be an API call to a payment gateway
    // For this demo, we'll simulate the process
    await Future.delayed(const Duration(seconds: 2)); // Simulate API processing time
    
    // Simulate a transaction ID from the payment gateway
    final transactionId = 'mm_${DateTime.now().millisecondsSinceEpoch}';
    
    // Simulated response from payment gateway
    return {
      'success': true,
      'transactionId': transactionId,
      'status': 'pending',
      'message': 'Please check your phone and confirm the payment',
      'provider': provider,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Record a transaction in Firestore
  Future<TransactionModel> _recordTransaction({
    required String userId,
    required String orderId,
    required String paymentMethodId,
    required TransactionType type,
    required TransactionStatus status,
    required double amount,
    required String currency,
    String? gatewayTransactionId,
    Map<String, dynamic>? gatewayResponse,
    String? errorMessage,
    String? refundReason,
  }) async {
    final now = DateTime.now();
    
    // Create transaction document
    final docRef = await _firestore.collection('transactions').add({
      'userId': userId,
      'orderId': orderId,
      'paymentMethodId': paymentMethodId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'amount': amount,
      'currency': currency,
      'gatewayTransactionId': gatewayTransactionId,
      'gatewayResponse': gatewayResponse,
      'errorMessage': errorMessage,
      'createdAt': Timestamp.fromDate(now),
      'completedAt': status == TransactionStatus.completed ? Timestamp.fromDate(now) : null,
      'refundReason': refundReason,
    });
    
    // Fetch the complete transaction
    final doc = await _firestore.collection('transactions').doc(docRef.id).get();
    return TransactionModel.fromFirestore(doc);
  }

  // Check payment status
  Future<TransactionStatus> checkMobileMoneyStatus(String transactionId) async {
    try {
      // In a real app, you would call the payment gateway API to check the status
      // For this demo, we'll simulate a successful response after some time
      await Future.delayed(const Duration(seconds: 2));
      
      // Random success/failure for demonstration (in a real app, this would come from the API)
      final randomSuccess = DateTime.now().millisecond % 10 != 0;
      
      if (randomSuccess) {
        // Update transaction status in Firestore
        final snapshot = await _firestore
            .collection('transactions')
            .where('gatewayTransactionId', isEqualTo: transactionId)
            .get();
            
        if (snapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in snapshot.docs) {
            batch.update(doc.reference, {
              'status': TransactionStatus.completed.toString().split('.').last,
              'completedAt': Timestamp.now(),
            });
          }
          await batch.commit();
        }
        
        return TransactionStatus.completed;
      } else {
        // Update transaction status in Firestore
        final snapshot = await _firestore
            .collection('transactions')
            .where('gatewayTransactionId', isEqualTo: transactionId)
            .get();
            
        if (snapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in snapshot.docs) {
            batch.update(doc.reference, {
              'status': TransactionStatus.failed.toString().split('.').last,
              'errorMessage': 'Payment not confirmed by customer',
            });
          }
          await batch.commit();
        }
        
        return TransactionStatus.failed;
      }
    } catch (e) {
      return TransactionStatus.failed;
    }
  }

  // Private: Unset current default payment method
  Future<void> _unsetCurrentDefaultPaymentMethod(String userId) async {
    final snapshot = await _firestore
        .collection('payment_methods')
        .where('userId', isEqualTo: userId)
        .where('isDefault', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isDefault': false,
        'updatedAt': Timestamp.now(),
      });
    }

    await batch.commit();
  }
}
