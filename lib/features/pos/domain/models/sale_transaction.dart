enum PaymentMethod { cash, card, other }
enum SaleStatus { completed, refunded, cancelled }

class SaleItem {
  final String productId;
  final String productName;
  final String productSku;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });
}

class SaleTransaction {
  final String id;
  final DateTime timestamp;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final PaymentMethod paymentMethod;
  final double amountReceived;
  final double change;
  final SaleStatus status;

  SaleTransaction({
    required this.id,
    required this.timestamp,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.amountReceived,
    required this.change,
    required this.status,
  });
}
