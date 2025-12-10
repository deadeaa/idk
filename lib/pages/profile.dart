import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../auth/login_page.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../pages/history_payment.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(25),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xFFFFB6C1), width: 2),
              ),
              child: const Icon(
                Icons.sentiment_dissatisfied,
                size: 40,
                color: Color(0xFFFF6B9D),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Logout?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Are you sure you want to leave?\nWe\'ll miss you! 😢',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6A5ACD),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cancel_outlined, size: 18),
                SizedBox(width: 8),
                Text(
                  'Stay Here',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout, size: 18),
                SizedBox(width: 8),
                Text(
                  'Yes, Logout',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      final cartProvider = context.read<CartProvider>();
      final userProvider = context.read<UserProvider>();

      await _auth.signOut();
      cartProvider.clearCart();
      userProvider.logout();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Logout error! Please try again.'),
          backgroundColor: const Color(0xFFFF6B9D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF0F5),
            Color(0xFFF0F8FF),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFE4EC),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFB6C1),
                      Color(0xFFFF6B9D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(65),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(55),
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Color(0xFFFF6B9D),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(17.5),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            _userData?['fullName'] ?? 'No Name',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
              fontFamily: 'ComicNeue',
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 16,
                color: Color(0xFF6A5ACD),
              ),
              const SizedBox(width: 8),
              Text(
                _userData?['email'] ?? 'No Email',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              if (_userData?['phone'] != null)
                _buildCuteBadge(
                  icon: Icons.phone,
                  text: _userData!['phone'],
                  color: const Color(0xFF87CEEB),
                ),
              if (_userData?['gender'] != null)
                _buildCuteBadge(
                  icon: _userData!['gender'] == 'Male' ? Icons.male : Icons.female,
                  text: _userData!['gender'],
                  color: const Color(0xFF98FB98),
                ),
              if (_userData?['skinType'] != null)
                _buildCuteBadge(
                  icon: Icons.spa,
                  text: '${_userData!['skinType']} Skin',
                  color: const Color(0xFFFFDAB9),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCuteBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuteMenuCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Card(
      margin: EdgeInsets.only(
        top: isFirst ? 0 : 4,
        bottom: isLast ? 0 : 4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: iconColor?.withOpacity(0.15) ?? const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor?.withOpacity(0.3) ?? const Color(0xFFE6F7FF),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? const Color(0xFF6A5ACD),
                  size: 22,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ),

              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFFFF6B9D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF0F5),
            Color(0xFFE6F7FF),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4EC),
                  borderRadius: BorderRadius.circular(75),
                  border: Border.all(
                    color: const Color(0xFFFFB6C1),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_alt_1,
                      size: 70,
                      color: Color(0xFFFF6B9D),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '👋',
                      style: TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Welcome to Your Profile!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                  fontFamily: 'ComicNeue',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              const Text(
                'Join our skincare family to unlock all the cute features! 🌸',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B9D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.login, size: 22),
                      SizedBox(width: 12),
                      Text(
                        'Login to Join the Fun!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6A5ACD),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'New here? ',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF0F5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.2),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 4,
                  color: Color(0xFFFF6B9D),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Loading your cute profile...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '🌸',
                style: TextStyle(fontSize: 24),
              ),
            ],
          ),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        body: _buildNotLoggedIn(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF0F5),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.person, color: Color(0xFFFF6B9D), size: 24),
            SizedBox(width: 10),
            Text(
              'My Cute Profile',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'ComicNeue',
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
            },
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: Color(0xFFFF6B9D),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF0F5),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildProfileHeader(),

              const SizedBox(height: 30),

              if (_userData?['address'] != null && _userData!['address'].toString().isNotEmpty)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F8FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF87CEEB),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color(0xFF87CEEB),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.home,
                              color: Color(0xFF87CEEB),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Address',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _userData!['address'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

              _buildCuteMenuCard(
                title: 'Payment History',
                icon: Icons.history,
                iconColor: const Color(0xFF6A5ACD),
                isFirst: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentHistoryPage()),
                  );
                },
              ),

              _buildCuteMenuCard(
                title: 'Delivery Status',
                icon: Icons.local_shipping,
                iconColor: const Color(0xFF00CED1),
                onTap: () {
                  Navigator.pushNamed(context, '/delivery');
                },
              ),

              _buildCuteMenuCard(
                title: 'My Favorites',
                icon: Icons.favorite,
                iconColor: const Color(0xFFFF6B9D),
                onTap: () {
                  Navigator.pushNamed(context, '/favorites');
                },
              ),

              const SizedBox(height: 30),

              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: const Color(0xFFF8F9FF),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF6A5ACD)),
                          SizedBox(width: 10),
                          Text(
                            'About SkinCare Store',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Your happy place for all things skincare! 🌸✨\nWe help you find the perfect products for your skin type with lots of cute vibes!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSmallBadge('🌸', 'Gentle'),
                          const SizedBox(width: 10),
                          _buildSmallBadge('✨', 'Effective'),
                          const SizedBox(width: 10),
                          _buildSmallBadge('💖', 'Cute'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF4444),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(
                        color: Color(0xFFFFE4E6),
                        width: 2,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout, size: 22),
                      SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'SkinCare Store • v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Made with 💖 and cute vibes!',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF999999),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallBadge(String emoji, String text) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF0F0F0),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}