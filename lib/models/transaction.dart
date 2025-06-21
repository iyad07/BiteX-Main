import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
  partiallyRefunded,
}

enum TransactionType {
  payment,
  refund,
  tip,
  serviceFee,
  deliveryFee,
  tax,
}

class TransactionModel {
  final String id;
  final String userId;
  final String? orderId;
  final String? paymentMethodId;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String currency; // USD, EUR, etc.
  final Map<String, dynamic>? gatewayResponse;
  final String? gatewayTransactionId;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? refundReason;
  final String? receiptUrl;

  TransactionModel({
    required this.id,
    required this.userId,
    this.orderId,
    this.paymentMethodId,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    this.gatewayResponse,
    this.gatewayTransactionId,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
    this.refundReason,
    this.receiptUrl,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      orderId: data['orderId'],
      paymentMethodId: data['paymentMethodId'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${data['type']}',
        orElse: () => TransactionType.payment,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${data['status']}',
        orElse: () => TransactionStatus.pending,
      ),
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      gatewayResponse: data['gatewayResponse'],
      gatewayTransactionId: data['gatewayTransactionId'],
      errorMessage: data['errorMessage'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      refundReason: data['refundReason'],
      receiptUrl: data['receiptUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'orderId': orderId,
      'paymentMethodId': paymentMethodId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'amount': amount,
      'currency': currency,
      'gatewayResponse': gatewayResponse,
      'gatewayTransactionId': gatewayTransactionId,
      'errorMessage': errorMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'refundReason': refundReason,
      'receiptUrl': receiptUrl,
    };
  }

  bool get isSuccessful =>
      status == TransactionStatus.completed;

  bool get isInProgress =>
      status == TransactionStatus.pending || status == TransactionStatus.processing;

  bool get isFailed =>
      status == TransactionStatus.failed || status == TransactionStatus.cancelled;

  String get statusText {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.processing:
        return 'Processing';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.refunded:
        return 'Refunded';
      case TransactionStatus.partiallyRefunded:
        return 'Partially Refunded';
      default:
        return 'Unknown';
    }
  }

  String get formattedAmount => '\$${amount.toStringAsFixed(2)} $currency';

  String get formattedDate =>
      '${createdAt.month}/${createdAt.day}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
}
