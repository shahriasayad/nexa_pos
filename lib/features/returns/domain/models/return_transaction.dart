import '../../../pos/domain/models/sale_transaction.dart';

enum ReturnReason { changedMind, damaged, wrongProduct, defective, other }

class ReturnItem {
  final String productId;
  final String productName;
  final double unitPrice; // from original sale
  final int quantity;
  final double refundAmount;

  ReturnItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.refundAmount,
  });
}

class ReturnTransaction {
  final String id;
  final String originalTransactionId;
  final DateTime timestamp;
  final List<ReturnItem> items;
  final double totalRefund;
  final PaymentMethod refundMethod;
  final ReturnReason reason;
  final String? note;

  ReturnTransaction({
    required this.id,
    required this.originalTransactionId,
    required this.timestamp,
    required this.items,
    required this.totalRefund,
    required this.refundMethod,
    required this.reason,
    this.note,
  });
}
