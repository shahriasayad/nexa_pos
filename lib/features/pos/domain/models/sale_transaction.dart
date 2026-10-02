enum PaymentMethod { cash, card, other }
enum SaleStatus { completed, refunded, cancelled }

class SaleItem {
  final String productId;
  final String productName;
  final String productSku;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final int returnedQuantity;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.returnedQuantity = 0,
  });
  
  SaleItem copyWith({int? returnedQuantity}) {
    return SaleItem(
      productId: productId,
      productName: productName,
      productSku: productSku,
      unitPrice: unitPrice,
      quantity: quantity,
      lineTotal: lineTotal,
      returnedQuantity: returnedQuantity ?? this.returnedQuantity,
    );
  }
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
  final List<dynamic> returns; // List<ReturnTransaction> handled at repo/UI level to avoid circular dep
  final String? customerId;
  final String? customerName;

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
    this.returns = const [],
    this.customerId,
    this.customerName,
  });

  SaleTransaction copyWith({
    SaleStatus? status,
    List<SaleItem>? items,
    List<dynamic>? returns,
    String? customerId,
    String? customerName,
  }) {
    return SaleTransaction(
      id: id,
      timestamp: timestamp,
      items: items ?? this.items,
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      total: total,
      paymentMethod: paymentMethod,
      amountReceived: amountReceived,
      change: change,
      status: status ?? this.status,
      returns: returns ?? this.returns,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
    );
  }
}
