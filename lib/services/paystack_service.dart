import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikex/models/payment_method.dart';
import 'package:bikex/models/transaction.dart';

class PaystackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Paystack API endpoints
  // Note: In a production app, these API calls should be made from your backend server
  final String _paystackApiUrl = 'https://api.paystack.co';
  
  // Paystack test secret key - DO NOT use in production
  final String _secretKey = 'sk_test_0b706e31338de3d46ec5cd51fee72a1cecbad9a7';

  static final PaystackService _instance = PaystackService._internal();
  factory PaystackService() => _instance;
  
  PaystackService._internal();

  // Initialize a Paystack transaction
  Future<Map<String, dynamic>> initializeTransaction({
    required String email,
    required double amount, 
    required String reference,
    String? callbackUrl,
  }) async {
    final url = Uri.parse('$_paystackApiUrl/transaction/initialize');
    
    // Convert amount to kobo (Paystack accepts amount in smallest currency unit)
    final amountInKobo = (amount * 100).toInt();
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'amount': amountInKobo,
        'reference': reference,
        'callback_url': callbackUrl,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['status'] == true) {
        return responseData['data'];
      } else {
        throw Exception('Paystack Error: ${responseData['message']}');
      }
    } else {
      throw Exception('Failed to initialize Paystack transaction. Status: ${response.statusCode}');
    }
  }

  // Verify a Paystack transaction
  Future<Map<String, dynamic>> verifyTransaction(String reference) async {
    final url = Uri.parse('$_paystackApiUrl/transaction/verify/$reference');
    
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['status'] == true) {
        return responseData['data'];
      } else {
        throw Exception('Paystack Error: ${responseData['message']}');
      }
    } else {
      throw Exception('Failed to verify Paystack transaction. Status: ${response.statusCode}');
    }
  }

  // Add a Paystack payment method
  Future<String> addPaystackMethod({
    required String email,
    required String authorizationCode,
    required String cardType,
    required String lastFourDigits,
    required String expiryDate,
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

      // Create new payment method document
      final docRef = await _firestore.collection('payment_methods').add({
        'userId': user.uid,
        'type': PaymentMethodTypeModel.paystack.toString().split('.').last,
        'title': title,
        'lastFourDigits': lastFourDigits,
        'brand': cardType,
        'expiryDate': expiryDate,
        'paymentTokenId': authorizationCode,
        'gatewayData': {
          'email': email,
          'authorizationCode': authorizationCode,
        },
        'isDefault': isDefault,
        'createdAt': Timestamp.now(),
      });

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Process a Paystack payment
  Future<TransactionModel> processPaystackPayment({
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
      
      // Check if gatewayData exists and has required Paystack fields
      if (paymentMethodData['gatewayData'] == null) {
        throw Exception('Payment method does not have gateway data');
      }
      
      final gatewayData = paymentMethodData['gatewayData'] as Map<String, dynamic>;
      
      if (gatewayData['email'] == null || gatewayData['authorizationCode'] == null) {
        throw Exception('Payment method missing required Paystack authorization data');
      }
      
      final email = gatewayData['email'] as String;
      final authorizationCode = gatewayData['authorizationCode'] as String;

      // Generate a unique reference for this transaction
      final reference = 'bikex-${DateTime.now().millisecondsSinceEpoch}-${user.uid.substring(0, 5)}';
      
      // Total amount including tip
      final totalAmount = amount + (tipAmount ?? 0.0);

      // In a real app with Paystack, we would now:
      // 1. Charge the authorization directly using Paystack's charge authorization API
      // 2. This would typically be done from a secure backend

      // For now, we'll simulate a successful Paystack charge with a mock response
      final paystackResponse = {
        'status': 'success',
        'reference': reference,
        'amount': totalAmount,
        'authorization': {
          'authorization_code': authorizationCode,
          'card_type': paymentMethodData['brand'],
          'last4': paymentMethodData['lastFourDigits'],
          'exp_month': paymentMethodData['expiryDate']?.substring(0, 2),
          'exp_year': paymentMethodData['expiryDate']?.substring(3, 5),
        },
      };

      // Record transaction
      final transaction = await _recordTransaction(
        userId: user.uid,
        orderId: orderId,
        paymentMethodId: paymentMethodId,
        type: TransactionType.payment,
        status: TransactionStatus.completed, // Paystack payments are typically immediately completed
        amount: totalAmount,
        currency: currency,
        gatewayTransactionId: reference,
        gatewayResponse: paystackResponse,
      );

      return transaction;
    } catch (e) {
      // If there's an error, record a failed transaction
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
