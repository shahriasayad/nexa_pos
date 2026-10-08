import 'package:flutter/material.dart';
import '../../domain/models/purchase_order.dart';
import '../../data/repositories/mock_purchase_repository.dart';
import '../../../products/data/repositories/mock_product_repository.dart';
import '../../../inventory/data/repositories/mock_inventory_repository.dart';
import '../controllers/purchase_controller.dart';
import '../../../products/domain/models/product.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class PurchaseFormScreen extends StatefulWidget {
  final PurchaseOrder? purchase;

  const PurchaseFormScreen({super.key, this.purchase});

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  late PurchaseController _controller;
  final _productRepo = MockProductRepository();
  
  List<Product> _allProducts = [];
  List<PurchaseItem> _items = [];
  String _supplierName = ''; // Simplification for prototype: just type it, or would normally select from supplier list.
  
  @override
  void initState() {
    super.initState();
    _controller = PurchaseController(
      purchaseRepo: MockPurchaseRepository(),
      inventoryRepo: MockInventoryRepository(),
      productRepo: _productRepo,
    );
    if (widget.purchase != null) {
      _items = List.from(widget.purchase!.items);
      _supplierName = widget.purchase!.supplierName;
    }
    _loadProducts();
  }
  
  Future<void> _loadProducts() async {
    final products = await _productRepo.getProducts();
    setState(() {
      _allProducts = products;
    });
  }

  void _addItem(Product product) {
    setState(() {
      final existingIndex = _items.indexWhere((i) => i.productId == product.id);
      if (existingIndex >= 0) {
        _items[existingIndex] = _items[existingIndex].copyWith(
          quantity: _items[existingIndex].quantity + 1
        );
      } else {
        _items.add(PurchaseItem(
          productId: product.id,
          productName: product.name,
          quantity: 1,
          unitCost: product.purchasePrice,
        ));
      }
    });
  }

  void _updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      setState(() => _items.removeAt(index));
    } else {
      setState(() {
        _items[index] = _items[index].copyWith(quantity: quantity);
      });
    }
  }

  void _saveDraft() async {
    _save(PurchaseStatus.draft);
  }

  void _placeOrder() async {
    _save(PurchaseStatus.ordered);
  }

  void _save(PurchaseStatus status) async {
    if (_supplierName.isEmpty || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier name and at least one item are required.')),
      );
      return;
    }
    
    final totalAmount = _items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    
    final purchase = PurchaseOrder(
      id: widget.purchase?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      supplierId: widget.purchase?.supplierId ?? 'sup-manual',
      supplierName: _supplierName,
      status: status,
      items: _items,
      totalAmount: totalAmount,
      orderDate: widget.purchase?.orderDate ?? DateTime.now(),
    );
    
    final success = await _controller.savePurchase(purchase);
    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _items.fold<double>(0, (sum, item) => sum + item.lineTotal);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.purchase == null ? 'New Purchase Order' : 'Edit Purchase Order'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomTextField(
                    initialValue: _supplierName,
                    label: 'Supplier Name',
                    onChanged: (val) => _supplierName = val,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        title: Text(item.productName),
                        subtitle: Text('\$${item.unitCost} x ${item.quantity} = \$${item.lineTotal}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => _updateQuantity(index, item.quantity - 1),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _updateQuantity(index, item.quantity + 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('\$$totalAmount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          onPressed: _saveDraft,
                          label: 'Save as Draft',
                          variant: CustomButtonVariant.outline,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          onPressed: _placeOrder,
                          label: 'Place Order',
                          variant: CustomButtonVariant.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _allProducts.length,
                    itemBuilder: (context, index) {
                      final product = _allProducts[index];
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text('\$${product.purchasePrice}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: () => _addItem(product),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
