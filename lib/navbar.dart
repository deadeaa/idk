import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'admin/product_admin.dart';
import 'admin/iconcat_admin.dart';
import 'admin/banner_admin.dart';
import 'pages/favorite.dart';
import 'pages/cart.dart';
import 'auth/login_page.dart';
import 'providers/user_provider.dart';
import 'pages/product_detail.dart';
import 'pages/search_results.dart';
import 'pages/pairing.dart';
import 'pages/recomment.dart';
import 'pages/about_us.dart';

class AnimatedNavIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String routeName;
  final VoidCallback? onTapCustom;

  const AnimatedNavIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.routeName,
    this.onTapCustom,
  });

  @override
  State<AnimatedNavIcon> createState() => _AnimatedNavIconState();
}

class _AnimatedNavIconState extends State<AnimatedNavIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  void _onTap() async {
    await _controller.forward();
    await _controller.reverse();

    if (widget.onTapCustom != null) {
      widget.onTapCustom!();
    } else if (widget.routeName.isNotEmpty) {
      Navigator.pushNamed(context, widget.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Icon(widget.icon, color: widget.color, size: 28),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  OverlayEntry? _searchOverlayEntry;

  void _navigateToPage(Widget page) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    } catch (e) {
      print('Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigation failed')),
      );
    }
  }

  void _handleAuthAction(VoidCallback action, {String featureName = "this feature"}) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (!userProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login first to use $featureName!')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      action();
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
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
        final queryLower = query.toLowerCase();

        return name.contains(queryLower) ||
            brand.contains(queryLower) ||
            category.contains(queryLower);
      }).toList();

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });

      if (results.isNotEmpty) {
        _showSearchResultsOverlay(results, query);
      } else {
        _showNoResultsOverlay(query);
      }
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error searching products')),
      );
    }
  }

  void _showSearchResultsOverlay(List<QueryDocumentSnapshot> results, String query) {
    _removeSearchOverlay();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    _searchOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: position.dy + 120,
          left: MediaQuery.of(context).size.width * 0.04,
          width: MediaQuery.of(context).size.width * 0.92,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Search results for "$query"',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${results.length} ${results.length == 1 ? 'product' : 'products'} found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final product = results[index];
                        final data = product.data() as Map<String, dynamic>;
                        final images = List<String>.from(data['images'] ?? []);
                        final imageUrl = images.isNotEmpty ? images[0] : '';
                        final name = data['name'] ?? 'No Name';
                        final brand = data['brand'] ?? '';
                        final price = (data['price'] ?? 0).toInt();
                        final salePrice = (data['salePrice'] ?? price).toInt();
                        final hasSale = salePrice > 0 && salePrice < price;

                        return ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[100],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildProductImage(imageUrl),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                brand,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasSale
                                    ? 'Rp ${_formatPrice(salePrice)}'
                                    : 'Rp ${_formatPrice(price)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: hasSale ? Colors.red : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            _removeSearchOverlay();
                            _searchController.clear();
                            setState(() => _isSearchOpen = false);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailPage(
                                  productId: product.id,
                                  productData: data,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            _removeSearchOverlay();
                            _showSearchResultsPage(query);
                          },
                          icon: const Icon(Icons.list, size: 18),
                          label: const Text('View all results'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _removeSearchOverlay();
                            _searchController.clear();
                            setState(() => _isSearchOpen = false);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_searchOverlayEntry!);
  }

  void _showNoResultsOverlay(String query) {
    _removeSearchOverlay();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    _searchOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: position.dy + 120,
          left: MediaQuery.of(context).size.width * 0.04,
          width: MediaQuery.of(context).size.width * 0.92,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No products found',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No products match "$query"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      _removeSearchOverlay();
                      _searchController.clear();
                      setState(() => _isSearchOpen = false);
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_searchOverlayEntry!);
  }

  void _showSearchResultsPage(String query) {
    _removeSearchOverlay();
    _searchController.clear();
    setState(() => _isSearchOpen = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(searchQuery: query),
      ),
    );
  }

  void _removeSearchOverlay() {
    if (_searchOverlayEntry != null) {
      _searchOverlayEntry!.remove();
      _searchOverlayEntry = null;
    }
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
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
            color: Colors.grey[200],
            child: const Icon(Icons.image, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.asset(
        imageUrl,
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
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _removeSearchOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final double navbarWidth = isMobile ? MediaQuery.of(context).size.width * 0.92 : 760;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),

        Center(
          child: Container(
            width: navbarWidth,
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                GestureDetector(
                  onTap: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Container(
                    width: 120,
                    height: 40,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                if (!isMobile)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _navigateToPage(const AboutUsPage());
                        },
                        child: _menuItem("About Me"),
                      ),
                      const SizedBox(width: 15),

                      // PopupMenuButton<String>(
                      //   onSelected: (value) {
                      //     switch (value) {
                      //       case "product":
                      //         _navigateToPage(const AdminProductPage());
                      //         break;
                      //       case "icon":
                      //         _navigateToPage(const AdminCategoryIconPage());
                      //         break;
                      //       case "banner":
                      //         _navigateToPage(const AdminBannerPage());
                      //         break;
                      //     }
                      //   },
                      //   child: Row(
                      //     children: const [
                      //       Text("Admin",
                      //           style: TextStyle(fontSize: 13, color: Colors.black)),
                      //       Icon(Icons.arrow_drop_down, size: 16),
                      //     ],
                      //   ),
                      //   itemBuilder: (context) => const [
                      //     PopupMenuItem(value: "product", child: Text("Product")),
                      //     PopupMenuItem(value: "icon", child: Text("Icon")),
                      //     PopupMenuItem(value: "banner", child: Text("Banner")),
                      //   ],
                      // ),

                      const SizedBox(width: 15),

                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == "recomment") {
                            _navigateToPage(const RecommendedIngredientsPage());
                          } else if (value == "pairing") {
                            _navigateToPage(const IngredientPairingPage());
                          }
                        },
                        child: Row(
                          children: const [
                            Text("Information",
                                style: TextStyle(fontSize: 13, color: Colors.black)),
                            Icon(Icons.arrow_drop_down, size: 16),
                          ],
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: "recomment",
                            child: Text("Recommendation"),
                          ),
                          const PopupMenuItem(
                            value: "pairing",
                            child: Text("Product Pairing"),
                          ),
                        ],
                      ),
                    ],
                  ),

                Row(
                  children: [

                    AnimatedNavIcon(
                      icon: _isSearchOpen ? Icons.close : Icons.search,
                      color: _isSearchOpen ? Colors.red : Colors.grey[700]!,
                      routeName: "",
                      onTapCustom: () {
                        if (_isSearchOpen) {
                          _removeSearchOverlay();
                          _searchController.clear();
                        }
                        setState(() {
                          _isSearchOpen = !_isSearchOpen;
                          if (_isSearchOpen) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _searchFocusNode.requestFocus();
                            });
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 18),

                    AnimatedNavIcon(
                      icon: Icons.favorite_border,
                      color: Colors.pink[600]!,
                      routeName: "",
                      onTapCustom: () {
                        _handleAuthAction(
                              () {
                            _navigateToPage(const FavoritesPage());
                          },
                          featureName: "favorites",
                        );
                      },
                    ),

                    const SizedBox(width: 18),

                    AnimatedNavIcon(
                      icon: Icons.shopping_cart_outlined,
                      color: Colors.blue[700]!,
                      routeName: "",
                      onTapCustom: () {
                        _handleAuthAction(
                              () {
                            _navigateToPage(const CartPage());
                          },
                          featureName: "cart",
                        );
                      },
                    ),

                    if (isMobile)
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case "about":
                              _navigateToPage(const AboutUsPage());
                                break;
                              case "recomment":
                                _navigateToPage(const RecommendedIngredientsPage());
                                break;
                              case "pairing":
                                _navigateToPage(const IngredientPairingPage());
                                break;
                              // case "admin_product":
                              //   _navigateToPage(const AdminProductPage());
                              //   break;
                              // case "admin_icon":
                              //   _navigateToPage(const AdminCategoryIconPage());
                              //   break;
                              // case "admin_banner":
                              //   _navigateToPage(const AdminBannerPage());
                              //   break;
                            }
                          },
                          icon: const Icon(Icons.menu, size: 28),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: "about",
                              child: Text("About Me"),
                            ),
                            const PopupMenuItem(
                              value: "recomment",
                              child: Text("Recommendation"),
                            ),
                            const PopupMenuItem(
                              value: "pairing",
                              child: Text("Product Pairing"),
                            ),
                            // const PopupMenuItem(
                            //   value: "admin_product",
                            //   child: Text("Admin: Product"),
                            // ),
                            // const PopupMenuItem(
                            //   value: "admin_icon",
                            //   child: Text("Admin: Icon"),
                            // ),
                            // const PopupMenuItem(
                            //   value: "admin_banner",
                            //   child: Text("Admin: Banner"),
                            // ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isSearchOpen
              ? Container(
            key: const ValueKey("searchbar"),
            width: navbarWidth,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Search products by name, brand, or category...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _removeSearchOverlay();
                    _searchController.clear();
                    setState(() => _isSearchOpen = false);
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                if (value.length > 2) {
                  _searchProducts(value);
                } else {
                  _removeSearchOverlay();
                  setState(() {
                    _searchResults = [];
                  });
                }
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _removeSearchOverlay();
                  _searchController.clear();
                  setState(() => _isSearchOpen = false);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchResultsPage(searchQuery: value),
                    ),
                  );
                }
              },
            ),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _menuItem(String text) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$text page coming soon!')),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}