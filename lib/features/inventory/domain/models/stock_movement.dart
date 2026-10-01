enum StockMovementType {
  sale,
  purchase,
  returnItem,
  manualAdjustment,
  damaged,
  correction,
}

class StockMovement {
  final String id;
  final String productId;
  final int quantityChange;
  final StockMovementType type;
  final int previousStock;
  final int newStock;
  final String reason;
  final String? note;
  final DateTime timestamp;
  final String? referenceId;

  StockMovement({
    required this.id,
    required this.productId,
    required this.quantityChange,
    required this.type,
    required this.previousStock,
    required this.newStock,
    required this.reason,
    this.note,
    required this.timestamp,
    this.referenceId,
  });
}
