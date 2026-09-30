class Product {
  final String id;
  final String name;
  final String sku;
  final String? barcode;
  final String categoryId;
  final String? brand;
  final double purchasePrice;
  final double sellingPrice;
  final int stockQuantity;
  final int minimumStock;
  final String unit;
  final double tax;
  final double discount;
  final String? supplierId;
  final String? imagePath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    required this.categoryId,
    this.brand,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stockQuantity,
    this.minimumStock = 0,
    this.unit = 'pcs',
    this.tax = 0.0,
    this.discount = 0.0,
    this.supplierId,
    this.imagePath,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    String? barcode,
    String? categoryId,
    String? brand,
    double? purchasePrice,
    double? sellingPrice,
    int? stockQuantity,
    int? minimumStock,
    String? unit,
    double? tax,
    double? discount,
    String? supplierId,
    String? imagePath,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      brand: brand ?? this.brand,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minimumStock: minimumStock ?? this.minimumStock,
      unit: unit ?? this.unit,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      supplierId: supplierId ?? this.supplierId,
      imagePath: imagePath ?? this.imagePath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
