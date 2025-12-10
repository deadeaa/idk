import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navbar.dart';
import '../bottom_navbar.dart';
import 'all_product.dart';
import 'category_product.dart';
import 'product_detail.dart';
import 'profile.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../favorite_service.dart';
import 'delivery.dart';
import 'history_payment.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int trendingTab = 0;
  int _currentPageIndex = 0;
  final ScrollController _scrollController = ScrollController();

  User? get user => FirebaseAuth.instance.currentUser;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final bannersRef = FirebaseFirestore.instance.collection('banners');
  final categoriesRef = FirebaseFirestore.instance.collection('categoryIcons');

  final Map<String, bool> _favAnimating = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final favoriteService = context.read<FavoriteService>();
      final cartProvider = context.read<CartProvider>();

      if (user != null) {
        favoriteService.loadFavorites();
        cartProvider.loadUserCart();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;

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

  int discountPercent(int price, int sale) {
    if (price <= 0 || sale >= price) return 0;
    return ((price - sale) / price * 100).round();
  }

  Widget categoryTab(String title, int index) {
    final active = trendingTab == index;
    final isLargeScreen = screenWidth > 768;

    return GestureDetector(
      onTap: () => setState(() => trendingTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 20 : 16,
          vertical: isLargeScreen ? 10 : 10,
        ),
        decoration: BoxDecoration(
          color: active ? Colors.pink[400] : Colors.blue[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? Colors.pink[400]! : Colors.blue[200]!,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : Colors.pink[700],
            fontWeight: FontWeight.w600,
            fontSize: isLargeScreen ? 14.0 : 13.0,
          ),
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

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  Widget _getCurrentPage() {
    switch (_currentPageIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const DeliveryPage();
      case 2:
        return const AllProductsPage(filter: "all");
      case 3:
        return const PaymentHistoryPage();
      case 4:
        return const ProfilePage();
      default:
        return _buildHomeContent();
    }
  }

  Stream<List<DocumentSnapshot>> getOnSaleProducts() {
    return _firestore
        .collection('products')
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final price = data['price'] ?? 0;
        final salePrice = data['salePrice'] ?? 0;
        return salePrice > 0 && salePrice < price;
      }).toList();
    });
  }

  Stream<List<DocumentSnapshot>> getFeaturedProducts(String type) {
    String field = '';
    switch (type) {
      case 'trending':
        field = 'isTrending';
        break;
      case 'new':
        field = 'isNew';
        break;
      case 'mustHave':
        field = 'isMustHave';
        break;
      case 'bestSeller':
        field = 'isBestSeller';
        break;
      default:
        field = 'isTrending';
    }

    return _firestore
        .collection('products')
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data[field] == true;
      }).toList();
    });
  }

  Widget buildProductCard(DocumentSnapshot doc, double cardWidth) {
    final d = doc.data() as Map<String, dynamic>;
    final pid = doc.id;
    final price = (d['price'] ?? 0).toInt();
    final salePrice = (d['salePrice'] ?? 0).toInt();
    final images = List<String>.from(d['images'] ?? []);
    final mainImage = images.isNotEmpty ? images[0] : '';

    final hasDiscount = salePrice > 0 && salePrice < price;
    final displayPrice = hasDiscount ? salePrice : price;
    final discount = hasDiscount ? discountPercent(price, salePrice) : 0;

    final favoriteService = context.watch<FavoriteService>();
    final isFavorite = favoriteService.isFavorite(pid);

    final fontSizeTitle = cardWidth > 180 ? 14.0 : 12.0;
    final fontSizePrice = cardWidth > 180 ? 15.0 : 13.0;
    final fontSizeSmall = cardWidth > 180 ? 11.0 : 10.0;

    return GestureDetector(
      onTap: () => _navigateToProductDetail(pid, d),
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 16),
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
                children: [
                  Container(
                    width: double.infinity,
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
                  // BADGE DISKON
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
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
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d['name'] ?? 'No Name',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: fontSizeTitle,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rp ${displayPrice.toStringAsFixed(0).replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]}.',
                        )}',
                        style: TextStyle(
                          color:
                          hasDiscount ? Colors.pink[500] : Colors.grey[800],
                          fontWeight: FontWeight.bold,
                          fontSize: fontSizePrice,
                        ),
                      ),

                      if (hasDiscount) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Rp ${price.toStringAsFixed(0).replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]}.',
                              )}',
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: fontSizeSmall,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Save ${((price - salePrice) / 1000).toStringAsFixed(0)}k',
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: fontSizeSmall - 1,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHorizontalProductList(List<DocumentSnapshot> docs) {
    double cardWidth;

    if (screenWidth > 1200) {
      cardWidth = 220;
    } else if (screenWidth > 900) {
      cardWidth = 200;
    } else if (screenWidth > 600) {
      cardWidth = 180;
    } else {
      cardWidth = 160;
    }

    final imageHeight = cardWidth;
    final infoHeight = 90;
    final totalCardHeight = imageHeight + infoHeight;

    return SizedBox(
      height: totalCardHeight + 20,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          return buildProductCard(docs[index], cardWidth);
        },
      ),
    );
  }

  Widget onSaleSection() {
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: getOnSaleProducts(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 250,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.pink[400],
              ),
            ),
          );
        }

        if (snap.hasError) {
          return SizedBox(
            height: 180,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red[400], size: 40),
                  const SizedBox(height: 10),
                  Text(
                    'Error loading sale products',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snap.hasData || snap.data!.isEmpty) {
          return Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'No sale products available',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snap.data!;
        return buildHorizontalProductList(docs);
      },
    );
  }

  Widget _buildFeaturedProductsSection() {
    String queryType = '';
    switch (trendingTab) {
      case 0:
        queryType = 'trending';
        break;
      case 1:
        queryType = 'new';
        break;
      case 2:
        queryType = 'mustHave';
        break;
      case 3:
        queryType = 'bestSeller';
        break;
    }

    return StreamBuilder<List<DocumentSnapshot>>(
      stream: getFeaturedProducts(queryType),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 250,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.pink[400],
              ),
            ),
          );
        }

        if (snap.hasError) {
          return SizedBox(
            height: 180,
            child: Center(
              child: Text(
                'Error loading products',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        if (!snap.hasData || snap.data!.isEmpty) {
          return Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'No ${['Trending', 'New', 'Must Have', 'Best Seller'][trendingTab]} products',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snap.data!;
        return buildHorizontalProductList(docs);
      },
    );
  }

  Widget _buildSingleBanner() {
    final isLargeScreen = screenWidth > 768;

    return StreamBuilder<QuerySnapshot>(
      stream: bannersRef.snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            height: isLargeScreen ? 360 : 180,
            margin: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 32 : 16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isLargeScreen ? 20 : 16),
              color: Colors.grey[200],
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.pink[400],
              ),
            ),
          );
        }

        if (snap.hasError) {
          return Container(
            height: isLargeScreen ? 360 : 180,
            margin: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 32 : 16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isLargeScreen ? 20 : 16),
              color: Colors.grey[200],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: isLargeScreen ? 48 : 32),
                  SizedBox(height: isLargeScreen ? 16 : 8),
                  Text(
                    'Failed to load banner',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isLargeScreen ? 16 : 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];
        final activeBanners = docs
            .where((doc) =>
        (doc.data() as Map<String, dynamic>)['active'] == true)
            .toList()
          ..sort((a, b) {
            final aOrder = (a.data() as Map<String, dynamic>)['order'] ?? 0;
            final bOrder = (b.data() as Map<String, dynamic>)['order'] ?? 0;
            return aOrder.compareTo(bOrder);
          });

        if (activeBanners.isEmpty) {
          return Container(
            height: isLargeScreen ? 360 : 180,
            margin: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 32 : 16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isLargeScreen ? 20 : 16),
              color: Colors.pink[50],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image,
                      color: Colors.pink[300],
                      size: isLargeScreen ? 56 : 40
                  ),
                  SizedBox(height: isLargeScreen ? 16 : 8),
                  Text(
                    'No banner available',
                    style: TextStyle(
                      color: Colors.pink[300],
                      fontSize: isLargeScreen ? 18 : 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final banner = activeBanners.first;
        final data = banner.data() as Map<String, dynamic>;
        final imageUrl = data['image'] as String?;

        return Container(
          height: isLargeScreen ? 360 : 180,
          margin: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 32 : 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isLargeScreen ? 20 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isLargeScreen ? 0.15 : 0.1),
                blurRadius: isLargeScreen ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isLargeScreen ? 20 : 16),
            child: buildImage(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),

                _buildSingleBanner(),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Shop by Category',
                    style: TextStyle(
                      fontSize: screenWidth > 768 ? 22.0 : 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: categoriesRef.snapshots(),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.pink[400],
                          ),
                        ),
                      );
                    }

                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return SizedBox(
                        height: 80,
                        child: Center(
                          child: Text(
                            'No categories',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (ctx, idx) {
                          final doc = docs[idx];
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['category'] ?? 'Unnamed';
                          final icon = data['icon'] ?? '';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CategoryProductsPage(category: name),
                                ),
                              );
                            },
                            child: Container(
                              width: 80,
                              margin: EdgeInsets.only(
                                  right: idx == docs.length - 1 ? 0 : 12),
                              child: Column(
                                children: [
                                  Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.pink[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.pink[100]!,
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: buildImage(icon, fit: BoxFit.contain),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    name,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue[50]!,
                        Colors.pink[50]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_fire_department,
                                  color: Colors.red[400], size: 22),
                              const SizedBox(width: 6),
                              Text(
                                'Hot Deals 🔥',
                                style: TextStyle(
                                  fontSize: screenWidth > 768 ? 22.0 : 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[500],
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const AllProductsPage(filter: "sale"),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'View All',
                                  style: TextStyle(
                                      fontSize: screenWidth > 768 ? 14 : 12),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward,
                                    size: screenWidth > 768 ? 16 : 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      onSaleSection(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Featured Products',
                                  style: TextStyle(
                                    fontSize: screenWidth > 768 ? 20.0 : 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  categoryTab("Trending", 0),
                                  const SizedBox(width: 8),
                                  categoryTab("New", 1),
                                  const SizedBox(width: 8),
                                  categoryTab("Must Have", 2),
                                  const SizedBox(width: 8),
                                  categoryTab("Best Seller", 3),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFeaturedProductsSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _getCurrentPage(),

          if (_currentPageIndex == 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: const Navbar(),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavbar(
              currentIndex: _currentPageIndex,
              onTap: _onBottomNavTapped,
              deliveryCount: 0,
              isLoggedIn: userProvider.isLoggedIn,
            ),
          ),
        ],
      ),
    );
  }
}