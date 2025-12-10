import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/cart_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  bool _isLoading = false;
  final StreamController<List<CartItem>> _itemsStreamController =
  StreamController<List<CartItem>>.broadcast();

  List<CartItem> get items => List.unmodifiable(_items);
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  int get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalSavings => _items.fold(0, (sum, item) => sum + item.savings);
  bool get isEmpty => _items.isEmpty;
  bool get isLoading => _isLoading;

  Stream<List<CartItem>> get itemsStream => _itemsStreamController.stream;

  void _emitStream() {
    if (!_itemsStreamController.isClosed) {
      _itemsStreamController.add(List.unmodifiable(_items));
    }
  }

  Future<void> loadUserCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _items.clear();
      _emitStream();
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final cartDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      _items.clear();
      for (var doc in cartDoc.docs) {
        final data = doc.data();

        final cartItem = CartItem(
          id: doc.id,
          productId: data['productId'] ?? '',
          name: data['name'] ?? '',
          image: data['img'] ?? data['image'] ?? '',
          price: (data['price'] ?? 0).toInt(),
          salePrice: (data['salePrice'] ?? 0).toInt(),
          quantity: (data['qty'] ?? data['quantity'] ?? 1).toInt(),
          brand: data['brand'] ?? '',
          category: data['category'] ?? '',
        );
        _items.add(cartItem);
      }

      _emitStream();

      if (kDebugMode) {
        print('✅ Cart loaded: ${_items.length} items, total: Rp ${_formatPrice(totalPrice)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading cart: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCartToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');

      final existingCart = await cartRef.get();
      for (var doc in existingCart.docs) {
        batch.delete(doc.reference);
      }

      for (var item in _items) {
        final docRef = cartRef.doc(item.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : item.id);
        batch.set(docRef, {
          'productId': item.productId,
          'name': item.name,
          'img': item.image,
          'price': item.price,
          'salePrice': item.salePrice,
          'qty': item.quantity,
          'brand': item.brand,
          'category': item.category,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      _emitStream();

      if (kDebugMode) {
        print('✅ Cart saved to Firestore: ${_items.length} items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving cart: $e');
      }
      rethrow;
    }
  }

  Future<void> addToCart(CartItem newItem) async {
    if (newItem.productId.isEmpty) {
      if (kDebugMode) {
        print('❌ Cannot add item with empty productId');
      }
      return;
    }

    final index = _items.indexWhere((item) => item.productId == newItem.productId);

    if (index >= 0) {

      final existingItem = _items[index];
      final newQuantity = existingItem.quantity + newItem.quantity;

      _items[index] = CartItem(
        id: existingItem.id,
        productId: existingItem.productId,
        name: existingItem.name,
        image: existingItem.image,
        price: existingItem.price,
        salePrice: existingItem.salePrice,
        quantity: newQuantity,
        brand: existingItem.brand,
        category: existingItem.category,
      );

      if (kDebugMode) {
        print('🔄 Cart item updated: ${newItem.name}, quantity: $newQuantity');
      }
    } else {

      final itemId = newItem.id.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : newItem.id;

      final itemToAdd = CartItem(
        id: itemId,
        productId: newItem.productId,
        name: newItem.name,
        image: newItem.image,
        price: newItem.price,
        salePrice: newItem.salePrice,
        quantity: newItem.quantity,
        brand: newItem.brand,
        category: newItem.category,
      );

      _items.add(itemToAdd);

      if (kDebugMode) {
        print('🛒 New item added to cart: ${newItem.name}, quantity: ${newItem.quantity}');
      }
    }

    _emitStream();
    notifyListeners();
    await _saveCartToFirestore();
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      final existingItem = _items[index];

      _items[index] = CartItem(
        id: existingItem.id,
        productId: existingItem.productId,
        name: existingItem.name,
        image: existingItem.image,
        price: existingItem.price,
        salePrice: existingItem.salePrice,
        quantity: newQuantity,
        brand: existingItem.brand,
        category: existingItem.category,
      );

      _emitStream();
      notifyListeners();
      await _saveCartToFirestore();

      if (kDebugMode) {
        print('📊 Quantity updated: ${_items[index].name} -> $newQuantity');
      }
    }
  }

  Future<void> incrementQuantity(String productId) async {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      final existingItem = _items[index];
      final newQuantity = existingItem.quantity + 1;

      _items[index] = CartItem(
        id: existingItem.id,
        productId: existingItem.productId,
        name: existingItem.name,
        image: existingItem.image,
        price: existingItem.price,
        salePrice: existingItem.salePrice,
        quantity: newQuantity,
        brand: existingItem.brand,
        category: existingItem.category,
      );

      _emitStream();
      notifyListeners();
      await _saveCartToFirestore();

      if (kDebugMode) {
        print('➕ Incremented: ${_items[index].name}, quantity: $newQuantity');
      }
    }
  }

  Future<void> decrementQuantity(String productId) async {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      final existingItem = _items[index];

      if (existingItem.quantity > 1) {
        final newQuantity = existingItem.quantity - 1;

        _items[index] = CartItem(
          id: existingItem.id,
          productId: existingItem.productId,
          name: existingItem.name,
          image: existingItem.image,
          price: existingItem.price,
          salePrice: existingItem.salePrice,
          quantity: newQuantity,
          brand: existingItem.brand,
          category: existingItem.category,
        );

        _emitStream();
        notifyListeners();
        await _saveCartToFirestore();

        if (kDebugMode) {
          print('➖ Decremented: ${_items[index].name}, quantity: $newQuantity');
        }
      } else {
        await removeFromCart(productId);
      }
    }
  }

  Future<void> removeFromCart(String productId) async {
    final index = _items.indexWhere((item) => item.productId == productId);

    if (index >= 0) {
      final item = _items[index];
      _items.removeAt(index);
      _emitStream();
      notifyListeners();

      await _saveCartToFirestore();

      if (kDebugMode) {
        print('🗑️ Item removed from cart: ${item.name}');
      }
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    _emitStream();
    notifyListeners();
    await _saveCartToFirestore();

    if (kDebugMode) {
      print('🧹 Cart cleared');
    }
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  int getItemQuantity(String productId) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      return _items[index].quantity;
    }
    return 0;
  }

  CartItem? getCartItem(String productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  Future<void> removeMultipleItems(List<String> productIds) async {
    bool changed = false;

    for (var productId in productIds) {
      final index = _items.indexWhere((item) => item.productId == productId);
      if (index >= 0) {
        _items.removeAt(index);
        changed = true;
      }
    }

    if (changed) {
      _emitStream();
      notifyListeners();
      await _saveCartToFirestore();

      if (kDebugMode) {
        print('🗑️ Removed ${productIds.length} items from cart');
      }
    }
  }

  Map<String, int> calculateTotals() {
    const shippingCost = 15000;
    final tax = (totalPrice * 0.1).round();
    final grandTotal = totalPrice + shippingCost + tax;

    return {
      'subtotal': totalPrice,
      'shipping': shippingCost,
      'tax': tax,
      'grandTotal': grandTotal,
    };
  }

  Stream<List<CartItem>> getRealtimeCart() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        return CartItem(
          id: doc.id,
          productId: data['productId'] ?? '',
          name: data['name'] ?? '',
          image: data['img'] ?? data['image'] ?? '',
          price: (data['price'] ?? 0).toInt(),
          salePrice: (data['salePrice'] ?? 0).toInt(),
          quantity: (data['qty'] ?? data['quantity'] ?? 1).toInt(),
          brand: data['brand'] ?? '',
          category: data['category'] ?? '',
        );
      }).toList();

      _items.clear();
      _items.addAll(items);
      _emitStream();
      notifyListeners();

      return items;
    });
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  @override
  void dispose() {
    _itemsStreamController.close();
    super.dispose();
  }
}