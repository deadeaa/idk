import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  bool _addingToCart = false;
  int _quantity = 1;
  bool _showDescription = false;
  bool _showIngredients = false;

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFavorite() async {
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(widget.productId);

    final snap = await docRef.get();
    if (mounted) {
      setState(() {
        _isFavorite = snap.exists;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (user == null) {
      _showLoginPrompt();
      return;
    }

    setState(() => _isFavorite = !_isFavorite);

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(widget.productId);

    try {
      if (_isFavorite) {
        await docRef.set({
          'productId': widget.productId,
          'name': widget.productData['name'],
          'img': widget.productData['images'] != null &&
              (widget.productData['images'] as List).isNotEmpty
              ? (widget.productData['images'] as List)[0]
              : '',
          'price': widget.productData['price'],
          'salePrice': widget.productData['salePrice'] ?? widget.productData['price'],
          'addedAt': FieldValue.serverTimestamp(),
        });
        _showSuccess('${widget.productData['name']} added to favorites! ❤️');
      } else {
        await docRef.delete();
        _showSuccess('${widget.productData['name']} removed from favorites');
      }
    } catch (e) {
      setState(() => _isFavorite = !_isFavorite);
      _showError('Failed to update favorites');
    }
  }

  Future<void> _addToCart() async {
    if (user == null) {
      _showLoginPrompt();
      return;
    }

    setState(() => _addingToCart = true);

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart')
        .doc(widget.productId);

    try {
      final snap = await docRef.get();
      if (snap.exists) {
        await docRef.update({
          'qty': (snap['qty'] ?? 1) + _quantity,
          'updatedAt': FieldValue.serverTimestamp()
        });
      } else {
        await docRef.set({
          'productId': widget.productId,
          'name': widget.productData['name'],
          'img': widget.productData['images'] != null &&
              (widget.productData['images'] as List).isNotEmpty
              ? (widget.productData['images'] as List)[0]
              : '',
          'price': widget.productData['price'],
          'salePrice': widget.productData['salePrice'] ?? widget.productData['price'],
          'qty': _quantity,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      _showSuccess('${widget.productData['name']} added to cart! 🛒');
    } catch (e) {
      _showError('Failed to add to cart');
    } finally {
      setState(() => _addingToCart = false);
    }
  }

  void _showLoginPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please login first to use this feature.'),
        action: SnackBarAction(
          label: 'Login',
          onPressed: () => Navigator.pushNamed(context, '/login'),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildImage(String? src) {
    if (src == null || src.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
              SizedBox(height: 8),
              Text('No image', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (src.startsWith('http')) {
      return Image.network(
        src,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.asset(
        src,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(widget.productData['images'] ?? []);
    final price = widget.productData['price'] ?? 0;
    final salePrice = widget.productData['salePrice'] ?? 0;
    final hasSale = salePrice > 0 && salePrice < price;
    final discountPercent =
    hasSale ? ((1 - (salePrice / price)) * 100).round() : 0;

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: Colors.pink.shade50,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.grey,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: screenWidth,
              color: Colors.grey.shade50,
              child: Stack(
                children: [
                  images.isNotEmpty
                      ? PageView.builder(
                    controller: _imageController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildImage(images[index]);
                    },
                  )
                      : _buildImage(null),

                  if (images.length > 1 && _currentImageIndex > 0)
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            _imageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (images.length > 1 && _currentImageIndex < images.length - 1)
                    Positioned(
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            _imageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (images.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (index) {
                          return Container(
                            width: _currentImageIndex == index ? 10 : 8,
                            height: _currentImageIndex == index ? 10 : 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? Colors.pink.shade400
                                  : Colors.white.withOpacity(0.7),
                              border: _currentImageIndex == index
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ),

                  if (hasSale)
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '-$discountPercent%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                  if (images.length > 1)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.productData['name'] ?? 'Product Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Text(
                        widget.productData['brand'] ?? 'Brand',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.productData['category'] ?? 'Category',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.pink.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      if (hasSale) ...[
                        Text(
                          'Rp ${_formatPrice(salePrice)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Rp ${_formatPrice(price)}',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else
                        Text(
                          'Rp ${_formatPrice(price)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (_quantity > 1) {
                              setState(() => _quantity--);
                            }
                          },
                        ),
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() => _quantity++);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showDescription = !_showDescription;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  _showDescription
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                            if (_showDescription) ...[
                              const SizedBox(height: 12),
                              Text(
                                widget.productData['description'] ??
                                    'No description available.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showIngredients = !_showIngredients;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Ingredients',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  _showIngredients
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                            if (_showIngredients) ...[
                              const SizedBox(height: 12),
                              Text(
                                widget.productData['ingredients'] ??
                                    'No ingredients information.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.grey,
                  size: 28,
                ),
                onPressed: _toggleFavorite,
              ),
            ),
            const SizedBox(width: 8),

            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addingToCart ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: Colors.pink.shade200,
                ),
                icon: _addingToCart
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.8)),
                  ),
                )
                    : const Icon(Icons.shopping_cart_outlined),
                label: Text(
                  _addingToCart ? 'Adding...' : 'Add to Cart',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }
}