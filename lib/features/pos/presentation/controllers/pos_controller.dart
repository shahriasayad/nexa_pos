import 'package:flutter/material.dart';
import '../../../../core/state/view_state.dart';
import '../../../products/domain/models/product.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../inventory/domain/models/stock_movement.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/sale_transaction.dart';
import '../../domain/repositories/sales_repository.dart';

class PosController extends ChangeNotifier {
  final ProductRepository productRepo;
  final InventoryRepository inventoryRepo;
  final SalesRepository salesRepo;

  PosController({
    required this.productRepo,
    required this.inventoryRepo,
    required this.salesRepo,
  });

  ViewState state = ViewState.initial;
  String? errorMessage;
  
  List<Product> searchResults = [];
  String? searchQuery;
  String? categoryId;
  
  List<CartItem> cart = [];
  
  bool isProcessingCheckout = false;
  SaleTransaction? lastCompletedSale;

  double get subtotal => cart.fold(0, (sum, item) => sum + item.lineTotal);
  double get discount => 0.0; // Phase 5 doesn't specify complex discount rules
  double get tax => 0.0; // Phase 5 doesn't specify complex tax rules
  double get grandTotal => subtotal - discount + tax;

  Future<void> searchProducts(String? query, {String? category}) async {
    searchQuery = query;
    categoryId = category;
    
    try {
      final results = await productRepo.getProducts(
        search: query,
        categoryId: category,
      );
      // Filter out inactive products and out of stock
      searchResults = results.where((p) => p.isActive && p.stockQuantity > 0).toList();
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to search products.';
      notifyListeners();
    }
  }

  void addToCart(Product product) {
    if (product.stockQuantity <= 0) {
      _setError('Product is out of stock.');
      return;
    }
    
    final existingIndex = cart.indexWhere((i) => i.product.id == product.id);
    if (existingIndex >= 0) {
      final existingItem = cart[existingIndex];
      if (existingItem.quantity + 1 > product.stockQuantity) {
        _setError('Cannot exceed available stock (${product.stockQuantity}).');
        return;
      }
      cart[existingIndex] = existingItem.copyWith(quantity: existingItem.quantity + 1);
    } else {
      cart.add(CartItem(product: product, quantity: 1));
    }
    notifyListeners();
  }
  
  void updateQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      removeFromCart(product);
      return;
    }
    if (quantity > product.stockQuantity) {
      _setError('Cannot exceed available stock (${product.stockQuantity}).');
      return;
    }
    final existingIndex = cart.indexWhere((i) => i.product.id == product.id);
    if (existingIndex >= 0) {
      cart[existingIndex] = cart[existingIndex].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void removeFromCart(Product product) {
    cart.removeWhere((i) => i.product.id == product.id);
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  Future<bool> checkout(PaymentMethod method, double amountReceived) async {
    if (cart.isEmpty) {
      _setError('Cart is empty.');
      return false;
    }
    
    if (amountReceived < grandTotal) {
      _setError('Insufficient payment amount.');
      return false;
    }

    if (isProcessingCheckout) return false;

    isProcessingCheckout = true;
    notifyListeners();

    try {
      // 1. Revalidate stock for all items
      for (final item in cart) {
        final currentProduct = await productRepo.getProductById(item.product.id);
        if (currentProduct == null || !currentProduct.isActive) {
          throw Exception('Product ${item.product.name} is no longer available.');
        }
        if (currentProduct.stockQuantity < item.quantity) {
          throw Exception('Insufficient stock for ${item.product.name}. Available: ${currentProduct.stockQuantity}.');
        }
      }

      // 2. Create Transaction
      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
      final saleItems = cart.map((i) => SaleItem(
        productId: i.product.id,
        productName: i.product.name,
        productSku: i.product.sku,
        unitPrice: i.product.sellingPrice,
        quantity: i.quantity,
        lineTotal: i.lineTotal,
      )).toList();

      final sale = SaleTransaction(
        id: transactionId,
        timestamp: DateTime.now(),
        items: saleItems,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        total: grandTotal,
        paymentMethod: method,
        amountReceived: amountReceived,
        change: amountReceived - grandTotal,
        status: SaleStatus.completed,
      );

      // 3. Deduct inventory and log movements
      for (final item in cart) {
        final currentProduct = (await productRepo.getProductById(item.product.id))!;
        final newStock = currentProduct.stockQuantity - item.quantity;
        
        await productRepo.updateProduct(currentProduct.copyWith(
          stockQuantity: newStock, 
          updatedAt: DateTime.now(),
        ));
        
        await inventoryRepo.logMovement(StockMovement(
          id: DateTime.now().millisecondsSinceEpoch.toString() + item.product.id,
          productId: item.product.id,
          quantityChange: -item.quantity,
          type: StockMovementType.sale,
          previousStock: currentProduct.stockQuantity,
          newStock: newStock,
          reason: 'Sale transaction',
          referenceId: transactionId,
          timestamp: DateTime.now(),
        ));
      }

      // 4. Save sale transaction
      await salesRepo.createSale(sale);

      lastCompletedSale = sale;
      clearCart();
      isProcessingCheckout = false;
      notifyListeners();
      return true;

    } catch (e) {
      isProcessingCheckout = false;
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  void _setError(String msg) {
    errorMessage = msg;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
