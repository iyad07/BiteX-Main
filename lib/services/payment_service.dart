import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikex/models/payment_method.dart';
import 'package:bikex/models/transaction.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
 

  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;

  final String _stripePublishableKey = 'pk_test_51RPLReD59vYutkQcMxs8ZQvmiQA8AaZOKOp89yK5f5MyOlwWoilzZLPM0VeYC99u1ZHRovFLmcolNzVmL86Rf3u200Xl89OqAz';

  PaymentService._internal() {
    _initStripe();
  }

  void _initStripe() {
    Stripe.publishableKey = _stripePublishableKey;
    Stripe.merchantIdentifier = 'Test'; // iOS only, can be empty for Android
    Stripe.stripeAccountId = null; // optional, if you use Stripe Connect

    // If you want to enable Apple Pay / Google Pay, configure here as well
    // But this is optional and depends on your use case
  }

  // PAYMENT METHODS MANAGEMENT

  // Get all payment methods for current user
  Stream<List<PaymentMethodModel>> getUserPaymentMethods() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('payment_methods')
        .where('userId', isEqualTo: user.uid)
        .orderBy('isDefault', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PaymentMethodModel.fromFirestore(doc)).toList();
    });
  }

  // Get default payment method for current user
  Future<PaymentMethodModel?> getDefaultPaymentMethod() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final snapshot = await _firestore
        .collection('payment_methods')
        .where('userId', isEqualTo: user.uid)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      // If no default payment method, try to get any payment method
      final anyMethodSnapshot = await _firestore
          .collection('payment_methods')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
          
      if (anyMethodSnapshot.docs.isEmpty) {
        return null;
      }
      
      return PaymentMethodModel.fromFirestore(anyMethodSnapshot.docs.first);
    }

    return PaymentMethodModel.fromFirestore(snapshot.docs.first);
  }

  // Add a new credit/debit card
 Future<String> addNewCard({
  required String cardNumber,
  required String expiryDate,
  required String cvv,
  required String cardHolderName,
  required String title,
  String? billingAddressId,
  bool isDefault = false,
}) async {
  try {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to add a payment method');
    }

    // Extract expiration month and year
    final expMonth = int.parse(expiryDate.split('/')[0]);
    final expYear = int.parse(expiryDate.split('/')[1]);

    // Create PaymentMethodParams with raw card data (only allowed in test/dev environments)
    final paymentMethod = await Stripe.instance.createPaymentMethod(params:
      PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(
          billingDetails: BillingDetails(
            name: cardHolderName,
          ),
        ),
      ),
    );

    // Unset existing default if needed
    if (isDefault) {
      await _unsetCurrentDefaultPaymentMethod(user.uid);
    }

    // Extract card details for display
    final lastFourDigits = cardNumber.substring(cardNumber.length - 4);
    final brand = _determineBrand(cardNumber); // Assume this is your own logic

    // Save to Firestore
    final docRef = await _firestore.collection('payment_methods').add({
      'userId': user.uid,
      'type': PaymentMethodTypeModel.creditCard.toString().split('.').last,
      'title': title,
      'lastFourDigits': lastFourDigits,
      'cardHolderName': cardHolderName,
      'expiryDate': expiryDate,
      'brand': brand,
      'isDefault': isDefault,
      'billingAddressId': billingAddressId,
      'paymentTokenId': paymentMethod.id,
      'gatewayData': {
        'stripe': {
          'paymentMethodId': paymentMethod.id,
          //'type': paymentMethod.type,
        },
      },
      'createdAt': Timestamp.now(),
    });

    return docRef.id;
  } catch (e) {
    rethrow;
  }
}

  // Delete a payment method
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      final doc = await _firestore.collection('payment_methods').doc(paymentMethodId).get();
      
      // If this was a default payment method, make another payment method the default
      if (doc.exists && doc.data()?['isDefault'] == true) {
        final user = _auth.currentUser;
        if (user != null) {
          await _setNewDefaultPaymentMethod(user.uid, paymentMethodId);
        }
      }
      
      await _firestore.collection('payment_methods').doc(paymentMethodId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Set payment method as default
  Future<void> setPaymentMethodAsDefault(String paymentMethodId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to set a default payment method');
      }

      // Unset current default payment method
      await _unsetCurrentDefaultPaymentMethod(user.uid);

      // Set new default payment method
      await _firestore.collection('payment_methods').doc(paymentMethodId).update({
        'isDefault': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
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

  // Private: Set a new default payment method when current default is deleted
  Future<void> _setNewDefaultPaymentMethod(String userId, String excludePaymentMethodId) async {
    final snapshot = await _firestore
        .collection('payment_methods')
        .where('userId', isEqualTo: userId)
        .where(FieldPath.documentId, isNotEqualTo: excludePaymentMethodId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await _firestore.collection('payment_methods').doc(snapshot.docs.first.id).update({
        'isDefault': true,
        'updatedAt': Timestamp.now(),
      });
    }
  }

  // Determine credit card brand based on card number
  String _determineBrand(String cardNumber) {
    // Visa: Starts with 4
    if (cardNumber.startsWith('4')) {
      return 'Visa';
    }
    // Mastercard: Starts with 51-55 or 2221-2720
    else if ((cardNumber.startsWith('5') && 
              int.parse(cardNumber.substring(1, 2)) >= 1 && 
              int.parse(cardNumber.substring(1, 2)) <= 5) ||
            (cardNumber.startsWith('2') && 
             int.parse(cardNumber.substring(0, 4)) >= 2221 && 
             int.parse(cardNumber.substring(0, 4)) <= 2720)) {
      return 'Mastercard';
    }
    // American Express: Starts with 34 or 37
    else if (cardNumber.startsWith('34') || cardNumber.startsWith('37')) {
      return 'American Express';
    }
    // Discover: Starts with 6011, 622126-622925, 644-649, or 65
    else if (cardNumber.startsWith('6011') || 
            (cardNumber.startsWith('622') && 
             int.parse(cardNumber.substring(3, 6)) >= 126 && 
             int.parse(cardNumber.substring(3, 6)) <= 925) ||
            (cardNumber.startsWith('64') && 
             int.parse(cardNumber.substring(2, 3)) >= 4 && 
             int.parse(cardNumber.substring(2, 3)) <= 9) || 
            cardNumber.startsWith('65')) {
      return 'Discover';
    }
    // Default to generic
    return 'Card';
  }

  // TRANSACTION PROCESSING

  // Process a payment
  Future<TransactionModel> processPayment({
    required String orderId,
    required String paymentMethodId,
    required double amount,
    String currency = 'USD',
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
      
      // Check if this is a card payment method with Stripe gateway data
      String? stripePaymentMethodId;
      if (paymentMethodData['gatewayData'] != null && 
          paymentMethodData['gatewayData']['stripe'] != null) {
        stripePaymentMethodId = paymentMethodData['gatewayData']['stripe']['paymentMethodId'];
      } else {
        // For non-card payment methods (like mobile money), we don't need Stripe payment method ID
        // We'll use the payment method ID directly
        stripePaymentMethodId = paymentMethodId;
      }

      // In a real app, this should be a backend API call to process the payment securely
      // For demonstration, we're simulating a payment process
      
      final transactionId = await _simulateStripePayment(
        stripePaymentMethodId!, 
        amount, 
        currency, 
        orderId
      );

      // Record transaction
      final totalAmount = amount + (tipAmount ?? 0.0);
      final transaction = await _recordTransaction(
        userId: user.uid,
        orderId: orderId,
        paymentMethodId: paymentMethodId,
        type: TransactionType.payment,
        status: TransactionStatus.completed,
        amount: totalAmount,
        currency: currency,
        gatewayTransactionId: transactionId,
      );

      // If tip amount is included, record as separate transaction
      if (tipAmount != null && tipAmount > 0) {
        await _recordTransaction(
          userId: user.uid,
          orderId: orderId,
          paymentMethodId: paymentMethodId,
          type: TransactionType.tip,
          status: TransactionStatus.completed,
          amount: tipAmount,
          currency: currency,
          gatewayTransactionId: transactionId, // Same transaction ID as main payment
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
          currency: currency,
          errorMessage: e.toString(),
        );
      }
      rethrow;
    }
  }

  // Simulate a Stripe payment (in production, this would be a server-side API call)
  Future<String> _simulateStripePayment(
    String paymentMethodId, 
    double amount, 
    String currency, 
    String orderId
  ) async {
    // In a real-world scenario, this would be a server call to Stripe API
    // For demo purposes, we'll simulate a successful payment
    
    await Future.delayed(Duration(seconds: 2)); // Simulate processing time
    
    // Generate a fake transaction ID
    final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
    
    return transactionId;
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

  // Process a refund
  Future<TransactionModel> processRefund({
    required String transactionId,
    required double amount,
    required String reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to process a refund');
      }

      // Get original transaction
      final transactionDoc = await _firestore.collection('transactions').doc(transactionId).get();
      if (!transactionDoc.exists) {
        throw Exception('Transaction not found');
      }

      final transactionData = transactionDoc.data()!;
      final originalAmount = transactionData['amount'];
      final currency = transactionData['currency'];
      final orderId = transactionData['orderId'];
      final paymentMethodId = transactionData['paymentMethodId'];
      final gatewayTransactionId = transactionData['gatewayTransactionId'];

      // Validate refund amount
      if (amount > originalAmount) {
        throw Exception('Refund amount cannot exceed original payment amount');
      }

      // In a real app, this would be a backend API call to process the refund
      // For demonstration, we're simulating a refund process
      await Future.delayed(Duration(seconds: 2)); // Simulate processing time

      // Update original transaction status
      final status = amount == originalAmount 
          ? TransactionStatus.refunded 
          : TransactionStatus.partiallyRefunded;
          
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });

      // Record refund transaction
      final refundTransaction = await _recordTransaction(
        userId: user.uid,
        orderId: orderId,
        paymentMethodId: paymentMethodId,
        type: TransactionType.refund,
        status: TransactionStatus.completed,
        amount: amount,
        currency: currency,
        gatewayTransactionId: 'refund_$gatewayTransactionId',
        refundReason: reason,
      );

      return refundTransaction;
    } catch (e) {
      rethrow;
    }
  }

  // Get user's transaction history
  Stream<List<TransactionModel>> getUserTransactions() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
    });
  }

  // Get transactions for a specific order
  Stream<List<TransactionModel>> getOrderTransactions(String orderId) {
    return _firestore
        .collection('transactions')
        .where('orderId', isEqualTo: orderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
    });
  }

  // Generate a receipt for a transaction
  Future<String> generateReceipt(String transactionId) async {
    try {
      // In a real app, this would generate a PDF receipt or similar
      // For demonstration, we're just returning a URL
      await Future.delayed(Duration(seconds: 1)); // Simulate processing time
      
      final receiptUrl = 'https://example.com/receipts/$transactionId';
      
      // Update transaction with receipt URL
      await _firestore.collection('transactions').doc(transactionId).update({
        'receiptUrl': receiptUrl,
      });
      
      return receiptUrl;
    } catch (e) {
      rethrow;
    }
  }



Future<String> addPaymentMethod({
  required PaymentMethodTypeModel type,
  required String title,
  String? cardNumber,
  String? expiryDate,
  String? cvv,
  String? cardHolderName,
  String? billingAddressId,
  bool isDefault = false,
  Map<String, dynamic>? gatewayData,
}) async {
  try {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to add a payment method');
    }

    if (isDefault) {
      await _unsetCurrentDefaultPaymentMethod(user.uid);
    }

    Map<String, dynamic> paymentData = {
      'userId': user.uid,
      'type': type.toString().split('.').last,
      'title': title,
      'isDefault': isDefault,
      'createdAt': Timestamp.now(),
    };

    if (type == PaymentMethodTypeModel.creditCard || type == PaymentMethodTypeModel.debitCard) {
      if (cardNumber == null || expiryDate == null || cvv == null || cardHolderName == null) {
        throw Exception('Card details are required for credit/debit card payment methods');
      }

      // Extract expiry month/year
      final expMonth = int.parse(expiryDate.split('/')[0]);
      final expYear = int.parse(expiryDate.split('/')[1]);

      // Create payment method with Stripe
      final paymentMethod = await Stripe.instance.createPaymentMethod(params: 
        PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              name: cardHolderName,
            ),
          ),
        ),
      );

      paymentData.addAll({
        'lastFourDigits': cardNumber.substring(cardNumber.length - 4),
        'cardHolderName': cardHolderName,
        'expiryDate': expiryDate,
        'brand': _determineBrand(cardNumber),
        'billingAddressId': billingAddressId,
        'paymentTokenId': paymentMethod.id,
        'gatewayData': {
          'stripe': {
            'paymentMethodId': paymentMethod.id,
            //'type': paymentMethod.type,
          },
        },
      });
    } else {
      // Non-card method
      paymentData.addAll({
        'lastFourDigits': '',
        'gatewayData': gatewayData ?? {},
      });
    }

    final docRef = await _firestore.collection('payment_methods').add(paymentData);
    return docRef.id;
  } catch (e) {
    rethrow;
  }
}

}
