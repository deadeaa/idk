import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/cart_provider.dart';
import 'cart_item.dart';
import 'checkout.dart';
import 'all_product.dart';
import 'product_detail.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with WidgetsBindingObserver {
  final Map<String, bool> _selectedItems = {};
  bool _selectAll = false;
  final Map<String, Map<String, dynamic>> _productDetails = {};
  bool _isLoadingProductDetails = false;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialLoad) {
      _loadProductDetails();
      _isInitialLoad = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _selectedItems.clear();
    _productDetails.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadProductDetails(forceRefresh: true);
    }
  }

  Future<void> _loadProductDetails({bool forceRefresh = false}) async {
    if (_isLoadingProductDetails && !forceRefresh) return;

    final cartProvider = context.read<CartProvider>();

    if (cartProvider.items.isEmpty) {
      if (mounted) {
        setState(() {
          _productDetails.clear();
          _selectedItems.clear();
          _selectAll = false;
          _isLoadingProductDetails = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingProductDetails = true;
      });
    }

    try {
      final productIds = cartProvider.items.map((item) => item.productId).toList();

      final uniqueProductIds = productIds.toSet().toList();

      final idsToLoad = forceRefresh
          ? uniqueProductIds
          : uniqueProductIds.where((id) => !_productDetails.containsKey(id)).toList();

      if (idsToLoad.isNotEmpty) {
        final batches = [];
        for (var i = 0; i < idsToLoad.length; i += 10) {
          final end = i + 10 < idsToLoad.length ? i + 10 : idsToLoad.length;
          batches.add(idsToLoad.sublist(i, end));
        }

        for (final batchIds in batches) {
          final productsSnapshot = await FirebaseFirestore.instance
              .collection('products')
              .where(FieldPath.documentId, whereIn: batchIds)
              .get();

          for (var doc in productsSnapshot.docs) {
            final data = doc.data();
            _productDetails[doc.id] = {
              'name': data['name'] ?? '',
              'brand': data['brand'] ?? '',
              'price': (data['price'] ?? 0).toInt(),
              'salePrice': (data['salePrice'] ?? 0).toInt(),
              'description': data['description'] ?? '',
              'category': data['category'] ?? '',
              'images': data['images'] is List ? List<String>.from(data['images'] ?? []) : [],
            };
          }
        }
      }
      _updateSelectedItems(cartProvider);

    } catch (e) {
      print('Error loading product details: $e');
      for (var item in cartProvider.items) {
        if (!_productDetails.containsKey(item.productId)) {
          _productDetails[item.productId] = {
            'name': item.name,
            'brand': item.brand,
            'price': item.price,
            'salePrice': item.salePrice,
            'description': '',
            'category': item.category,
            'images': [item.image],
          };
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProductDetails = false;
        });
      }
    }
  }

  void _updateSelectedItems(CartProvider cart) {
    for (var item in cart.items) {
      if (!_selectedItems.containsKey(item.productId)) {
        _selectedItems[item.productId] = false;
      }
    }

    final cartProductIds = cart.items.map((e) => e.productId).toSet();
    _selectedItems.removeWhere((key, value) => !cartProductIds.contains(key));
    _selectAll = _selectedItems.isNotEmpty &&
        _selectedItems.values.every((selected) => selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white,),
        ),
        backgroundColor: Colors.pink.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue[100],),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.isEmpty) return const SizedBox();

              return PopupMenuButton<String>(
                icon:  Icon(Icons.more_vert, color: Colors.blue[100]),
                onSelected: (value) {
                  if (value == 'clear') {
                    _showClearCartDialog(context);
                  } else if (value == 'refresh') {
                    _loadProductDetails(forceRefresh: true);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 20),
                        SizedBox(width: 8),
                        Text('Refresh Cart'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Clear Cart', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isLoading || _isLoadingProductDetails) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (cart.isEmpty) {
            return _buildEmptyCart(context);
          }

          return Column(
            children: [
              _buildSelectionToolbar(context, cart),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await cart.loadUserCart();
                    await _loadProductDetails(forceRefresh: true);
                  },
                  color: Colors.pink.shade700,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(
                          context,
                          cart.items[index],
                          cart
                      );
                    },
                  ),
                ),
              ),
              _buildCheckoutSection(context, cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectionToolbar(BuildContext context, CartProvider cart) {
    final selectedCount = _selectedItems.values.where((selected) => selected).length;
    final totalCount = cart.items.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _selectAll = !_selectAll;
                for (var item in cart.items) {
                  _selectedItems[item.productId] = _selectAll;
                }
              });
            },
            child: Row(
              children: [
                Checkbox(
                  value: _selectAll,
                  onChanged: (value) {
                    setState(() {
                      _selectAll = value ?? false;
                      for (var item in cart.items) {
                        _selectedItems[item.productId] = _selectAll;
                      }
                    });
                  },
                  activeColor: Colors.pink.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Select All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Selected: $selectedCount/$totalCount',
            style: TextStyle(
              fontSize: 14,
              color: Colors.pink.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add some skincare products to get started!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllProductsPage(filter: "all")),
              );
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Browse Products'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, CartProvider cart) {
    final isSelected = _selectedItems[item.productId] ?? false;
    final hasSale = item.salePrice > 0 && item.salePrice < item.price;
    final actualPrice = hasSale ? item.salePrice : item.price;
    final savings = hasSale ? (item.price - item.salePrice) * item.quantity : 0;

    final productData = _productDetails[item.productId];
    final brand = productData?['brand'] ?? item.brand;
    final brandName = brand.isNotEmpty ? brand : 'No Brand';

    final productDetailData = productData ?? {
      'name': item.name,
      'brand': item.brand,
      'price': item.price,
      'salePrice': item.salePrice,
      'description': '',
      'category': item.category,
      'images': [item.image],
    };

    return Dismissible(
      key: ValueKey('${item.id}_${item.quantity}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 30,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showRemoveDialog(context, item);
      },
      onDismissed: (direction) async {
        await cart.removeFromCart(item.productId);
        setState(() {
          _selectedItems.remove(item.productId);
          _productDetails.remove(item.productId);
        });
      },
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(
                productId: item.productId,
                productData: productDetailData,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.pink.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.pink.shade700 : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedItems[item.productId] = !isSelected;
                    _selectAll = _selectedItems.values.every((selected) => selected);
                  });
                },
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      _selectedItems[item.productId] = value ?? false;
                      _selectAll = _selectedItems.values.every((selected) => selected);
                    });
                  },
                  activeColor: Colors.pink.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: _getImageProvider(item.image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            productData?['name'] ?? item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasSale)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${((item.price - item.salePrice) * 100 / item.price).round()}%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      brandName,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rp ${_formatPrice(actualPrice)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink.shade700,
                              ),
                            ),
                            if (hasSale)
                              Text(
                                'Rp ${_formatPrice(item.price)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            if (hasSale)
                              Text(
                                'Save Rp ${_formatPrice(item.price - item.salePrice)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),

                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: () => cart.decrementQuantity(item.productId),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  item.quantity.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: () => cart.incrementQuantity(item.productId),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, CartProvider cart) {
    final selectedItems = cart.items.where((item) => _selectedItems[item.productId] == true).toList();
    final hasSelectedItems = selectedItems.isNotEmpty;
    final totals = _calculateSelectedTotals(selectedItems);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          if (hasSelectedItems) ...[
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.pink.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${selectedItems.length} item${selectedItems.length > 1 ? 's' : ''} selected',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.pink.shade700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      for (var item in cart.items) {
                        _selectedItems[item.productId] = false;
                      }
                      _selectAll = false;
                    });
                  },
                  child: const Text(
                    'Clear Selection',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (hasSelectedItems) ...[
            _buildSummaryRow('Subtotal', 'Rp ${_formatPrice(totals['subtotal']!)}'),
            if (totals['savings']! > 0)
              _buildSummaryRow('Savings', '-Rp ${_formatPrice(totals['savings']!)}', isSavings: true),
            _buildSummaryRow('Shipping', totals['shipping']! == 0 ? 'FREE' : 'Rp ${_formatPrice(totals['shipping']!)}'),
            _buildSummaryRow('Tax', 'Rp ${_formatPrice(totals['tax']!)}'),
            const Divider(height: 20),
            _buildSummaryRow(
              'Total',
              'Rp ${_formatPrice(totals['grandTotal']!)}',
              isTotal: true,
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Select items to checkout',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AllProductsPage(filter: "all"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_bag, size: 20),
                  label: const Text('Continue Shopping'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.pink.shade700,
                    side: BorderSide(color: Colors.pink.shade700),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasSelectedItems
                      ? () => _navigateToCheckout(context, selectedItems)
                      : null,
                  icon: const Icon(Icons.payment, size: 20),
                  label: const Text('Checkout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateSelectedTotals(List<CartItem> selectedItems) {
    int subtotal = 0;
    int savings = 0;

    for (var item in selectedItems) {
      final price = item.salePrice > 0 ? item.salePrice : item.price;
      subtotal += price * item.quantity;

      if (item.salePrice > 0) {
        savings += (item.price - item.salePrice) * item.quantity;
      }
    }

    final shipping = subtotal >= 100000 ? 0 : 10000;
    final tax = (subtotal * 0.1).round();
    final grandTotal = subtotal + shipping + tax;

    return {
      'subtotal': subtotal,
      'savings': savings,
      'shipping': shipping,
      'tax': tax,
      'grandTotal': grandTotal,
    };
  }

  Widget _buildSummaryRow(String label, String value, {bool isSavings = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isSavings ? Colors.green : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isSavings ? Colors.green : isTotal ? Colors.pink.shade700 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCheckout(BuildContext context, List<CartItem> selectedItems) {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select items to checkout!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutFormPage(selectedItems: selectedItems),
      ),
    );
  }

  Future<bool> _showRemoveDialog(BuildContext context, CartItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Are you sure you want to remove "${item.name}" from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final cart = context.read<CartProvider>();
              await cart.clearCart();
              setState(() {
                _selectedItems.clear();
                _selectAll = false;
                _productDetails.clear();
              });
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart cleared'),
                  backgroundColor: Colors.pink,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider(String imagePath) {
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    } else if (imagePath.isNotEmpty) {
      return AssetImage(imagePath);
    } else {
      return const AssetImage('assets/images/placeholder.png');
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }
}