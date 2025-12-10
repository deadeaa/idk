import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'product_detail.dart';
import '../providers/cart_provider.dart';
import 'cart_item.dart';
import '../auth/login_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final Map<String, bool> _favAnimating = {};
  final Map<String, bool> _cartAnimating = {};
  final Map<String, Map<String, dynamic>> _favoriteProducts = {};
  bool _isLoading = true;
  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      print('🔄 Loading favorites for user: ${user!.uid}');

      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();

      print('📊 Found ${favoritesSnapshot.docs.length} favorite documents');

      if (favoritesSnapshot.docs.isNotEmpty) {
        final favoriteProducts = <String, Map<String, dynamic>>{};

        for (var favDoc in favoritesSnapshot.docs) {
          final favData = favDoc.data();
          final productId = favData['productId'] as String?;

          if (productId != null) {
            favoriteProducts[productId] = {
              ...favData,
              'id': productId,
              'favoriteDocId': favDoc.id,
            };
          }
        }

        setState(() {
          _favoriteProducts.clear();
          _favoriteProducts.addAll(favoriteProducts);
          _isLoading = false;
        });

        print('✅ Loaded ${_favoriteProducts.length} favorite products');
      } else {
        setState(() {
          _favoriteProducts.clear();
          _isLoading = false;
        });
        print('ℹ️ No favorites found');
      }
    } catch (e) {
      print('❌ Error loading favorites: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading favorites: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeFromFavorites(String productId) async {
    if (user == null) return;

    try {
      final productData = _favoriteProducts[productId];
      final favoriteDocId = productData?['favoriteDocId'] as String?;

      if (favoriteDocId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('favorites')
            .doc(favoriteDocId)
            .delete();
      }

      setState(() {
        _favoriteProducts.remove(productId);
      });

      setState(() => _favAnimating[productId] = true);
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          setState(() => _favAnimating[productId] = false);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Removed from favorites'),
          backgroundColor: Colors.pink[400],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error removing favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to remove from favorites'),
          backgroundColor: Colors.red[400],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addToCartFirestore(String pid, Map<String, dynamic> data) async {
    final u = user;
    if (u == null) {
      _requireLoginPrompt();
      return;
    }

    final cartProvider = context.read<CartProvider>();
    final cartItem = CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: pid,
      name: data['name'] ?? '',
      image: data['images'] != null && (data['images'] as List).isNotEmpty
          ? (data['images'] as List).first
          : '',
      price: (data['price'] ?? 0).toInt(),
      salePrice: (data['salePrice'] ?? data['price'] ?? 0).toInt(),
      quantity: 1,
      brand: data['brand'] ?? '',
      category: data['category'] ?? '',
    );

    cartProvider.addToCart(cartItem);

    setState(() => _cartAnimating[pid] = true);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _cartAnimating[pid] = false);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${data['name']} added to cart!'),
        backgroundColor: Colors.green[400],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _requireLoginPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please login first to use this feature.'),
        backgroundColor: Colors.red[400],
        action: SnackBarAction(
          label: 'Login',
          textColor: Colors.white,
          onPressed: () => Navigator.pushNamed(context, '/login'),
        ),
      ),
    );
  }

  void _navigateToProductDetail(String productId, Map<String, dynamic> productData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          productId: productId,
          productData: productData,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 60,
              color: Colors.pink,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Tap the heart icon on any product to add it to your favorites',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: const Icon(Icons.shopping_bag, size: 20),
            label: const Text(
              'Start Shopping',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.pink[400],
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your favorites...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequiredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 60,
              color: Colors.pink,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Favorite List',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.pink[700],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Login to save products to your favorites and access them anytime',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: 220,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Login Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue Shopping',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(String productId, Map<String, dynamic> productData) {
    final images = List<String>.from(productData['images'] ?? []);
    final firstImage = images.isNotEmpty ? images[0] : 'assets/default_product.jpg';
    final price = productData['price'] ?? 0;
    final salePrice = productData['salePrice'] ?? 0;
    final hasSale = salePrice > 0 && salePrice < price;
    final discountPercent = hasSale ? ((1 - (salePrice / price)) * 100).round() : 0;
    final addedAt = productData['addedAt'] != null
        ? (productData['addedAt'] as Timestamp).toDate()
        : DateTime.now();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToProductDetail(productId, productData),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImage(firstImage),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productData['name'] ?? 'Product Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    Text(
                      '${productData['brand'] ?? 'Brand'} • ${productData['category'] ?? 'Category'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        if (hasSale)
                          Text(
                            'Rp ${_formatPrice(salePrice)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          'Rp ${_formatPrice(price)}',
                          style: TextStyle(
                            fontSize: hasSale ? 13 : 16,
                            fontWeight: hasSale ? FontWeight.normal : FontWeight.bold,
                            color: hasSale ? Colors.grey.shade500 : Colors.black,
                            decoration: hasSale ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (hasSale) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              '-$discountPercent%',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Added ${_formatDate(addedAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _removeFromFavorites(productId),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: AnimatedScale(
                              scale: (_favAnimating[productId] ?? false) ? 1.2 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.favorite, size: 16),
                            ),
                            label: const Text(
                              'Remove',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _addToCartFirestore(productId, productData),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink[50],
                              foregroundColor: Colors.pink[700],
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.pink[300]!),
                              ),
                            ),
                            icon: AnimatedScale(
                              scale: (_cartAnimating[productId] ?? false) ? 1.2 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.shopping_cart, size: 16),
                            ),
                            label: const Text(
                              'Add to Cart',
                              style: TextStyle(fontSize: 13),
                            ),
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

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.pink,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.image, size: 40, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
          );
        },
      );
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Favorites',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pink.shade50,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue[100]!),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_favoriteProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.pink[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_favoriteProducts.length} items',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.pink,
        onRefresh: () async {
          await _loadFavorites();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (_isLoading)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: _buildLoadingState(),
                )
              else if (user == null)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: _buildLoginRequiredState(),
                )
              else if (_favoriteProducts.isEmpty)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: _buildEmptyState(),
                  )
                else
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      ..._favoriteProducts.entries.map((entry) {
                        return _buildFavoriteCard(entry.key, entry.value);
                      }).toList(),
                      const SizedBox(height: 20),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}