import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:skincare/pages/product_detail.dart';
import 'package:skincare/providers/cart_provider.dart';
import '../favorite_service.dart';
import 'cart_item.dart';

class CategoryProductsPage extends StatefulWidget {
  final String category;

  const CategoryProductsPage({super.key, required this.category});

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final Map<String, bool> _favAnimating = {};
  final Map<String, bool> _cartAnimating = {};
  User? get user => FirebaseAuth.instance.currentUser;

  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF5FB),
      appBar: AppBar(
        title: Text(
          widget.category,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFB3A80),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
        child: _buildProductGrid(),
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

  Future<void> _addToCartFirestore(String pid, Map<String, dynamic> data) async {
    final u = user;
    if (u == null) {
      _requireLoginPrompt();
      return;
    }

    final cartProvider = context.read<CartProvider>();

    if (cartProvider.isInCart(pid)) {
      cartProvider.incrementQuantity(pid);
    } else {
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
    }

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

  int discountPercent(int price, int sale) {
    if (price <= 0 || sale >= price) return 0;
    return ((price - sale) / price * 100).round();
  }

  String formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  Widget buildImage(String? src,
      {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (src == null || src.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }

    final isNetwork = src.startsWith('http://') || src.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        src,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.pink[400],
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else {
      return Image.asset(
        src,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );
    }
  }

  Widget buildProductCard(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final pid = doc.id;
    final price = (d['price'] ?? 0).toInt();
    final salePrice = (d['salePrice'] ?? 0).toInt();
    final images = List<String>.from(d['images'] ?? []);
    final mainImage = images.isNotEmpty ? images[0] : '';
    final isTrending = d['isTrending'] == true;
    final isNew = d['isNew'] == true;
    final isMustHave = d['isMustHave'] == true;
    final isBestSeller = d['isBestSeller'] == true;

    final hasDiscount = salePrice > 0 && salePrice < price;
    final displayPrice = hasDiscount ? salePrice : price;
    final discount = hasDiscount ? discountPercent(price, salePrice) : 0;

    final favoriteService = context.watch<FavoriteService>();
    final isFavorite = favoriteService.isFavorite(pid);

    return GestureDetector(
      onTap: () => _navigateToProductDetail(pid, d),
      behavior: HitTestBehavior.opaque,
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
                      child: buildImage(mainImage, fit: BoxFit.cover),
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
                        final success = await favoriteService.toggleFavorite(pid, d);

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
                      behavior: HitTestBehavior.translucent,
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
                            d['name'] ?? 'No Name',
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
                          '${d['brand'] ?? ''} • ${d['category'] ?? ''}',
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
                          'Rp ${formatPrice(displayPrice)}',
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
                                'Rp ${formatPrice(price)}',
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
                        onPressed: () => _addToCartFirestore(pid, d),
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
  }

  void _navigateToProductDetail(
      String productId, Map<String, dynamic> productData) {
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

  Widget _buildProductGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("products")
          .where("category", isEqualTo: widget.category)
          .where("active", isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final items = snapshot.data!.docs;
        return _buildProductGridView(items);
      },
    );
  }

  Widget _buildProductGridView(List<QueryDocumentSnapshot> items) {
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

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
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
      itemCount: items.length,
      itemBuilder: (context, index) {
        final p = items[index];
        return buildProductCard(p);
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFFB3A80),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Loading products...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to load products',
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
              error.length > 100 ? '${error.substring(0, 100)}...' : error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFB3A80),
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No products in ${widget.category}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back soon!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFB3A80),
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}