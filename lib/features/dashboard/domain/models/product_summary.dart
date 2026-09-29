class ProductSummary {
  final String id;
  final String name;
  final int stockQuantity;
  final double price;
  final int soldQuantity;

  ProductSummary({
    required this.id,
    required this.name,
    required this.stockQuantity,
    required this.price,
    this.soldQuantity = 0,
  });
}
