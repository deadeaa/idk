import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'product_detail.dart';
import '../providers/cart_provider.dart';
import '../favorite_service.dart';
import 'cart_item.dart';

class SearchResultsPage extends StatefulWidget {
  final String searchQuery;

  const SearchResultsPage({super.key, required this.searchQuery});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final Map<String, bool> _favAnimating = {};
  final Map<String, bool> _cartAnimating = {};
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    if (widget.searchQuery.isEmpty) {
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('products')
          .where('active', isEqualTo: true)
          .get();

      final results = snapshot.docs.where((doc) {
        final data = doc.data();
        final name = (data['name'] as String? ?? '').toLowerCase();
        final brand = (data['brand'] as String? ?? '').toLowerCase();
        final category = (data['category'] as String? ?? '').toLowerCase();
        final queryLower = widget.searchQuery.toLowerCase();

        return name.contains(queryLower) ||
            brand.contains(queryLower) ||
            category.contains(queryLower);
      }).toList();

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
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
            'Searching for "${widget.searchQuery}"...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
          const SizedBox(height: 16),
          const Text(
            'Search Failed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage.length > 100
                  ? '${_errorMessage.substring(0, 100)}...'
                  : _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _performSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink[400],
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'We couldn\'t find any products matching "${widget.searchQuery}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
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
            icon: const Icon(Icons.arrow_back, size: 20),
            label: const Text('Back to Home'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Try a different search',
              style: TextStyle(
                color: Colors.pink[600],
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final screenWidth = MediaQuery.of(context).size.width;

    double maxCrossAxisExtent;
    double childAspectRatio;
    double mainAxisSpacing;
    double crossAxisSpacing;

    if (screenWidth > 1200) {
      maxCrossAxisExtent = 280;
      childAspectRatio = 0.58;
      mainAxisSpacing = 16;
      crossAxisSpacing = 16;
    } else if (screenWidth > 900) {
      maxCrossAxisExtent = 240;
      childAspectRatio = 0.58;
      mainAxisSpacing = 14;
      crossAxisSpacing = 14;
    } else if (screenWidth > 600) {
      maxCrossAxisExtent = 200;
      childAspectRatio = 0.52;
      mainAxisSpacing = 12;
      crossAxisSpacing = 12;
    } else {
      maxCrossAxisExtent = 200;
      childAspectRatio = 0.52;
      mainAxisSpacing = 10;
      crossAxisSpacing = 10;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.pink[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.pink[100]!),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Results',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Showing ${_searchResults.length} results for "${widget.searchQuery}"',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                color: Colors.pink[600],
                tooltip: 'Refresh search',
                onPressed: _performSearch,
              ),
            ],
          ),
        ),

        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 120,
            ),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxCrossAxisExtent,
              childAspectRatio: childAspectRatio,
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              final productData = product.data() as Map<String, dynamic>;
              final pid = product.id;
              final price = (productData['price'] ?? 0).toInt();
              final salePrice = (productData['salePrice'] ?? 0).toInt();
              final images = List<String>.from(productData['images'] ?? []);
              final mainImage = images.isNotEmpty ? images[0] : '';
              final isTrending = productData['isTrending'] == true;
              final isNew = productData['isNew'] == true;
              final isMustHave = productData['isMustHave'] == true;
              final isBestSeller = productData['isBestSeller'] == true;

              final hasDiscount = salePrice > 0 && salePrice < price;
              final displayPrice = hasDiscount ? salePrice : price;
              final discount = hasDiscount ? ((1 - (salePrice / price)) * 100).round() : 0;

              final favoriteService = context.watch<FavoriteService>();
              final isFavorite = favoriteService.isFavorite(pid);

              return GestureDetector(
                onTap: () => _navigateToProductDetail(pid, productData),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                color: Colors.grey[100],
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: _buildImage(mainImage),
                              ),
                            ),

                            Positioned(
                              top: 8,
                              left: 8,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasDiscount)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red[400],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '-$discount%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                  if (isTrending)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'TREND',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                  if (isNew)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'NEW',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                  if (isBestSeller)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'BEST',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                  if (isMustHave)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'MUST',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () async {
                                  if (user == null) {
                                    _requireLoginPrompt();
                                    return;
                                  }

                                  setState(() => _favAnimating[pid] = true);
                                  final success = await favoriteService.toggleFavorite(pid, productData);

                                  if (!success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to update favorite'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }

                                  Future.delayed(const Duration(milliseconds: 250), () {
                                    if (mounted) {
                                      setState(() => _favAnimating[pid] = false);
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: AnimatedScale(
                                    scale: (_favAnimating[pid] ?? false) ? 1.2 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorite ? Colors.red : Colors.grey[600],
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 36,
                                    child: Text(
                                      productData['name'] ?? 'No Name',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${productData['brand'] ?? ''} • ${productData['category'] ?? ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Rp ${_formatPrice(displayPrice)}',
                                    style: TextStyle(
                                      color: hasDiscount ? Colors.pink[500] : Colors.grey[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),

                                  if (hasDiscount) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          'Rp ${_formatPrice(price)}',
                                          style: const TextStyle(
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.grey,
                                            fontSize: 9,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            'Save ${((price - salePrice) / 1000).toStringAsFixed(0)}k',
                                            style: TextStyle(
                                              color: Colors.red[600],
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),

                              const SizedBox(height: 4),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _addToCartFirestore(pid, productData),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink[50],
                                    foregroundColor: Colors.pink[700],
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      side: BorderSide(color: Colors.pink[300]!),
                                    ),
                                    elevation: 0,
                                    minimumSize: Size.zero,
                                  ),
                                  icon: AnimatedScale(
                                    scale: (_cartAnimating[pid] ?? false) ? 1.2 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: const Icon(
                                      Icons.shopping_cart,
                                      size: 14,
                                    ),
                                  ),
                                  label: const Text(
                                    'Add to Cart',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
              color: Colors.pink[400],
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search: "${widget.searchQuery}"',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pink.shade50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading && _searchResults.isNotEmpty)
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
                    '${_searchResults.length} results',
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFCE4EC),
              Color(0xFFEDF5FB),
            ],
          ),
        ),
        child: _isLoading
            ? _buildLoadingState()
            : _hasError
            ? _buildErrorState()
            : _searchResults.isEmpty
            ? _buildNoResultsState()
            : _buildProductGrid(),
      ),
    );
  }
}