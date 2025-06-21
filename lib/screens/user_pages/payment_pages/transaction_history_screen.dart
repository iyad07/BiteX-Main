import 'package:flutter/material.dart';
import 'package:bikex/models/transaction.dart';
import 'package:bikex/services/payment_service.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final PaymentService _paymentService = PaymentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _paymentService.getUserTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final transactions = snapshot.data ?? [];

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No transaction history',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your payment history will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Group transactions by date
          final Map<String, List<TransactionModel>> groupedTransactions = {};
          for (final transaction in transactions) {
            final dateKey = DateFormat('yyyy-MM-dd').format(transaction.createdAt);
            if (!groupedTransactions.containsKey(dateKey)) {
              groupedTransactions[dateKey] = [];
            }
            groupedTransactions[dateKey]!.add(transaction);
          }

          final sortedDates = groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final dateKey = sortedDates[index];
              final dateTransactions = groupedTransactions[dateKey]!;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _formatDateHeader(dateKey),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ...dateTransactions.map((transaction) => TransactionCard(transaction: transaction)),
                  if (index < sortedDates.length - 1) const Divider(height: 32),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _formatDateHeader(String dateKey) {
    final now = DateTime.now();
    final date = DateTime.parse(dateKey);
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }
}

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getTransactionColor(transaction).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTransactionIcon(transaction),
                    color: _getTransactionColor(transaction),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTransactionTitle(transaction),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat('h:mm a').format(transaction.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatAmount(transaction),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _getAmountColor(transaction),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(transaction).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        transaction.statusText,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(transaction),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (transaction.refundReason != null && transaction.refundReason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason: ${transaction.refundReason}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${transaction.orderId?.substring(0, 8) ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                if (transaction.receiptUrl != null)
                  GestureDetector(
                    onTap: () {
                      // TODO: Open receipt
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.receipt, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        const Text(
                          'View Receipt',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTransactionTitle(TransactionModel transaction) {
    switch (transaction.type) {
      case TransactionType.payment:
        return 'Order Payment';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.tip:
        return 'Driver Tip';
      case TransactionType.serviceFee:
        return 'Service Fee';
      case TransactionType.deliveryFee:
        return 'Delivery Fee';
      case TransactionType.tax:
        return 'Tax';
      default:
        return 'Transaction';
    }
  }

  IconData _getTransactionIcon(TransactionModel transaction) {
    switch (transaction.type) {
      case TransactionType.payment:
        return Icons.shopping_bag;
      case TransactionType.refund:
        return Icons.reply;
      case TransactionType.tip:
        return Icons.volunteer_activism;
      case TransactionType.serviceFee:
        return Icons.miscellaneous_services;
      case TransactionType.deliveryFee:
        return Icons.delivery_dining;
      case TransactionType.tax:
        return Icons.receipt_long;
      default:
        return Icons.payment;
    }
  }

  Color _getTransactionColor(TransactionModel transaction) {
    switch (transaction.type) {
      case TransactionType.payment:
        return Colors.blue;
      case TransactionType.refund:
        return Colors.green;
      case TransactionType.tip:
        return Colors.purple;
      case TransactionType.serviceFee:
        return Colors.orange;
      case TransactionType.deliveryFee:
        return Colors.teal;
      case TransactionType.tax:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(TransactionModel transaction) {
    switch (transaction.status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return Colors.orange;
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return Colors.red;
      case TransactionStatus.refunded:
      case TransactionStatus.partiallyRefunded:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getAmountColor(TransactionModel transaction) {
    if (transaction.type == TransactionType.refund) {
      return Colors.green;
    } else {
      return Colors.black;
    }
  }

  String _formatAmount(TransactionModel transaction) {
    final prefix = transaction.type == TransactionType.refund ? '+' : '';
    return '$prefix\$${transaction.amount.toStringAsFixed(2)}';
  }
}
