enum PurchaseStatus { draft, ordered, received, cancelled }

class PurchaseItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitCost;
  final int receivedQuantity;

  PurchaseItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
    this.receivedQuantity = 0,
  });

  double get lineTotal => quantity * unitCost;

  PurchaseItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? unitCost,
    int? receivedQuantity,
  }) {
    return PurchaseItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
    );
  }
}

class PurchaseOrder {
  final String id;
  final String supplierId;
  final String supplierName;
  final PurchaseStatus status;
  final List<PurchaseItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final DateTime? expectedDate;
  final String? notes;

  PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    this.expectedDate,
    this.notes,
  });

  PurchaseOrder copyWith({
    String? id,
    String? supplierId,
    String? supplierName,
    PurchaseStatus? status,
    List<PurchaseItem>? items,
    double? totalAmount,
    DateTime? orderDate,
    DateTime? expectedDate,
    String? notes,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      status: status ?? this.status,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      orderDate: orderDate ?? this.orderDate,
      expectedDate: expectedDate ?? this.expectedDate,
      notes: notes ?? this.notes,
    );
  }
}
