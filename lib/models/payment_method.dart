import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethodTypeModel {
  creditCard,
  debitCard,
  paypal,
  applePay,
  googlePay,
  cashOnDelivery,
  mtnMobileMoney,
  vodafoneCash,
  airtelTigoMoney,
  mobileMoney, // Generic mobile money option
  paystack, // Paystack payment gateway
}

class PaymentMethodModel {
  final String id;
  final String userId;
  final PaymentMethodTypeModel type;
  final String title; // E.g. "My Visa Card", "Work Card"
  final String lastFourDigits; // For cards only
  final String? cardHolderName; // For cards only
  final String? expiryDate; // For cards only, format: MM/YY
  final String? brand; // Visa, Mastercard, etc.
  final bool isDefault;
  final String? billingAddressId; // Reference to an Address
  final String? paymentTokenId; // Token from payment gateway
  final Map<String, dynamic>? gatewayData; // Additional data from payment gateway
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentMethodModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.lastFourDigits,
    this.cardHolderName,
    this.expiryDate,
    this.brand,
    required this.isDefault,
    this.billingAddressId,
    this.paymentTokenId,
    this.gatewayData,
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentMethodModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PaymentMethodModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: PaymentMethodTypeModel.values.firstWhere(
        (e) => e.toString() == 'PaymentMethodTypeModel.${data['type']}',
        orElse: () => PaymentMethodTypeModel.creditCard,
      ),
      title: data['title'] ?? '',
      lastFourDigits: data['lastFourDigits'] ?? '',
      cardHolderName: data['cardHolderName'],
      expiryDate: data['expiryDate'],
      brand: data['brand'],
      isDefault: data['isDefault'] ?? false,
      billingAddressId: data['billingAddressId'],
      paymentTokenId: data['paymentTokenId'],
      gatewayData: data['gatewayData'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'lastFourDigits': lastFourDigits,
      'cardHolderName': cardHolderName,
      'expiryDate': expiryDate,
      'brand': brand,
      'isDefault': isDefault,
      'billingAddressId': billingAddressId,
      'paymentTokenId': paymentTokenId,
      'gatewayData': gatewayData,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  PaymentMethodModel copyWith({
    String? title,
    bool? isDefault,
    String? billingAddressId,
    String? paymentTokenId,
    Map<String, dynamic>? gatewayData,
  }) {
    return PaymentMethodModel(
      id: id,
      userId: userId,
      type: type,
      title: title ?? this.title,
      lastFourDigits: lastFourDigits,
      cardHolderName: cardHolderName,
      expiryDate: expiryDate,
      brand: brand,
      isDefault: isDefault ?? this.isDefault,
      billingAddressId: billingAddressId ?? this.billingAddressId,
      paymentTokenId: paymentTokenId ?? this.paymentTokenId,
      gatewayData: gatewayData ?? this.gatewayData,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get displayName {
    switch (type) {
      case PaymentMethodTypeModel.creditCard:
      case PaymentMethodTypeModel.debitCard:
        return '${brand ?? 'Card'} •••• $lastFourDigits';
      case PaymentMethodTypeModel.paypal:
        return 'PayPal';
      case PaymentMethodTypeModel.applePay:
        return 'Apple Pay';
      case PaymentMethodTypeModel.googlePay:
        return 'Google Pay';
      case PaymentMethodTypeModel.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethodTypeModel.mtnMobileMoney:
        return 'MTN Mobile Money';
      case PaymentMethodTypeModel.vodafoneCash:
        return 'Vodafone Cash';
      case PaymentMethodTypeModel.airtelTigoMoney:
        return 'AirtelTigo Money';
      case PaymentMethodTypeModel.mobileMoney:
        return 'Mobile Money';
      case PaymentMethodTypeModel.paystack:
        return 'Paystack';
      default:
        return title;
    }
  }

  String get cardTypeIcon {
    if (type == PaymentMethodTypeModel.mtnMobileMoney) {
      return 'assets/icons/mtn_mobile_money.png';
    } else if (type == PaymentMethodTypeModel.vodafoneCash) {
      return 'assets/icons/vodafone_cash.png';
    } else if (type == PaymentMethodTypeModel.airtelTigoMoney) {
      return 'assets/icons/airtel_tigo_money.png';
    } else if (type == PaymentMethodTypeModel.mobileMoney) {
      return 'assets/icons/mobile_money.png';
    } else if (type == PaymentMethodTypeModel.paystack) {
      return 'assets/icons/paystack.png';
    }
    
    if (brand == null) return 'assets/icons/generic_card.png';
    
    switch (brand!.toLowerCase()) {
      case 'visa':
        return 'assets/icons/visa.png';
      case 'mastercard':
        return 'assets/icons/mastercard.png';
      case 'amex':
      case 'american express':
        return 'assets/icons/amex.png';
      case 'discover':
        return 'assets/icons/discover.png';
      default:
        return 'assets/icons/generic_card.png';
    }
  }
}
