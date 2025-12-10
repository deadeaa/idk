import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoriteService with ChangeNotifier {
  final Map<String, Map<String, dynamic>> _favorites = {};
  bool _isLoading = false;
  String? _error;

  Map<String, Map<String, dynamic>> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _favorites.length;

  Future<void> loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'User not logged in';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Loading favorites for user: ${user.uid}');

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();

      print('📊 Found ${snapshot.docs.length} favorite items');

      _favorites.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final productId = data['productId'] as String?;

        if (productId != null) {
          _favorites[productId] = {
            ...data,
            'id': productId,
            'favoriteId': doc.id,
          };
        }
      }

      print('✅ Loaded ${_favorites.length} favorite products');

    } catch (e) {
      print('❌ Error loading favorites: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavorite(String productId, Map<String, dynamic> productData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'Please login to save favorites';
      notifyListeners();
      return false;
    }

    final isFavorite = _favorites.containsKey(productId);
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(productId);

    try {
      if (isFavorite) {

        await docRef.delete();
        _favorites.remove(productId);
        print('✅ Removed from favorites: $productId');
      } else {

        await docRef.set({
          'productId': productId,
          'name': productData['name'] ?? 'Unknown Product',
          'images': productData['images'] ?? [],
          'price': productData['price'] ?? 0,
          'salePrice': productData['salePrice'] ?? productData['price'] ?? 0,
          'brand': productData['brand'] ?? 'Unknown Brand',
          'category': productData['category'] ?? 'Unknown Category',
          'addedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _favorites[productId] = {
          'productId': productId,
          'name': productData['name'],
          'images': productData['images'] ?? [],
          'price': productData['price'],
          'salePrice': productData['salePrice'] ?? productData['price'],
          'brand': productData['brand'],
          'category': productData['category'],
          'addedAt': Timestamp.now(),
        };
        print('✅ Added to favorites: $productId');
      }

      notifyListeners();
      return true;

    } catch (e) {
      print('❌ Error toggling favorite: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  bool isFavorite(String productId) {
    return _favorites.containsKey(productId);
  }

  Map<String, dynamic>? getFavorite(String productId) {
    return _favorites[productId];
  }

  void clear() {
    _favorites.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadFavorites();
  }
}