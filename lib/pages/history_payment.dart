import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedFilter = 'all';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<DocumentSnapshot> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Please login to view order history';
          _isLoading = false;
        });
        return;
      }

      print('Loading orders for user: ${user.uid}');

      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();
        print('Query with orderBy successful');
      } catch (e) {
        print('OrderBy failed, trying without orderBy: $e');
        snapshot = await _firestore
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .get();
        _orders = snapshot.docs;
        _orders.sort((a, b) {
          final aDate = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bDate = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          return (bDate?.millisecondsSinceEpoch ?? 0)
              .compareTo(aDate?.millisecondsSinceEpoch ?? 0);
        });
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _orders = snapshot.docs;
        _isLoading = false;
        print('Loaded ${_orders.length} orders');
      });

    } on FirebaseException catch (e) {
      print('Firebase error: ${e.code} - ${e.message}');
      setState(() {
        _hasError = true;
        _errorMessage = 'Database error: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      print('General error: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load orders: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<DocumentSnapshot> _getFilteredOrders() {
    if (_selectedFilter == 'all') return _orders;

    return _orders.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status']?.toString().toLowerCase() ?? '';

      if (_selectedFilter == 'completed') {
        return status != 'pending' && status != 'cancelled';
      }

      return status == _selectedFilter.toLowerCase();
    }).toList();
  }

  String _getDisplayStatus(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
      case 'shipped':
      case 'delivered':
        return 'Completed';
      default:
        return status.capitalize();
    }
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();

    if (statusLower == 'pending') {
      return const Color(0xFFFF8A80);
    } else if (statusLower == 'completed') {
      return const Color(0xFF81C784);
    } else if (statusLower == 'cancelled') {
      return const Color(0xFFE57373);
    }

    if (statusLower == 'processing' ||
        statusLower == 'shipped' ||
        statusLower == 'delivered') {
      return const Color(0xFF81C784);
    }

    return const Color(0xFFB0BEC5);
  }

  IconData _getStatusIcon(String status) {
    final statusLower = status.toLowerCase();

    if (statusLower == 'pending') {
      return Icons.pending_actions;
    } else if (statusLower == 'completed' ||
        statusLower == 'processing' ||
        statusLower == 'shipped' ||
        statusLower == 'delivered') {
      return Icons.check_circle;
    } else if (statusLower == 'cancelled') {
      return Icons.cancel;
    }

    return Icons.receipt;
  }

  int _calculateItemCount(List<dynamic>? items) {
    if (items == null) return 0;
    return items.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 0));
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';

    final intPrice = price is int ? price :
    price is double ? price.toInt() :
    int.tryParse(price.toString()) ?? 0;

    return intPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  String _getPaymentMethodIcon(String? method) {
    if (method == null) return '💰';

    final methodLower = method.toLowerCase();
    if (methodLower.contains('credit')) return '💳';
    if (methodLower.contains('bank')) return '🏦';
    if (methodLower.contains('ewallet') || methodLower.contains('wallet')) return '📱';
    if (methodLower.contains('cash') || methodLower.contains('cod')) return '💵';
    return '💰';
  }

  Widget _buildFilterChips() {
    final filters = [
      {'value': 'all', 'label': 'All Orders'},
      {'value': 'pending', 'label': 'Pending'},
      {'value': 'completed', 'label': 'Completed'},
      {'value': 'cancelled', 'label': 'Cancelled'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: const Color(0xFFE9EDF1),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(
                  filter['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: _selectedFilter == filter['value'],
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter['value']!;
                  });
                },
                selectedColor: const Color(0xFF90D4FA),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: _selectedFilter == filter['value']
                      ? Colors.white
                      : const Color(0xFF555555),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _selectedFilter == filter['value']
                        ? const Color(0xFF90D4FA)
                        : const Color(0xFFF8BBD0),
                  ),
                ),
                checkmarkColor: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrderCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final orderId = data['orderId'] ?? 'N/A';
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final status = data['status']?.toString() ?? 'pending';
    final displayStatus = _getDisplayStatus(status);
    final paymentMethod = data['paymentMethodName'] ?? data['paymentMethod'] ?? 'Unknown';
    final totalAmount = data['totalAmount'] ?? 0;
    final items = data['items'] as List<dynamic>? ?? [];
    final itemCount = _calculateItemCount(items);

    final firstItem = items.isNotEmpty ? items[0] as Map<String, dynamic>? : null;
    final imageUrl = firstItem?['imageUrl'] ?? firstItem?['image'] ?? 'assets/product/default.jpg';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showOrderDetails(data);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                size: 14,
                                color: const Color(0xFFF06292),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Order #${orderId.substring(orderId.length - 6)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF333333),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd/MM/yy, HH:mm').format(createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _getStatusColor(status).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            size: 10,
                            color: _getStatusColor(status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            displayStatus,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: const Color(0xFFFCE4EC),
                        border: Border.all(color: const Color(0xFFCCEDFF)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: imageUrl.startsWith('http')
                            ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.shopping_bag,
                              color: const Color(0xFFF06292).withOpacity(0.3),
                              size: 20,
                            );
                          },
                        )
                            : Image.asset(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.shopping_bag,
                              color: const Color(0xFFF06292).withOpacity(0.3),
                              size: 20,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${itemCount} item${itemCount > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF444444),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                _getPaymentMethodIcon(paymentMethod),
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  paymentMethod,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF666666),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rp ${_formatPrice(totalAmount)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF06292),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCE4EC),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Paid',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFFF06292),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (status.toLowerCase() == 'pending')
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () {
                                _completePayment(orderId, data);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF06292),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: EdgeInsets.zero,
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.payment, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Complete Payment',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: IconButton(
                            onPressed: () {
                              _cancelOrder(orderId);
                            },
                            icon: Icon(
                              Icons.close,
                              size: 16,
                              color: const Color(0xFFF44336),
                            ),
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _completePayment(String orderId, Map<String, dynamic> orderData) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(
              Icons.payment,
              color: const Color(0xFFF06292),
            ),
            const SizedBox(width: 10),
            const Text(
              'Complete Payment',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please complete your payment and upload proof of payment.',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 10),
            Text(
              'Bank Transfer:\nBCA 1234567890',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Later',
              style: TextStyle(
                color: Color(0xFF666666),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPaymentProofDialog(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF06292),
              foregroundColor: Colors.white,
            ),
            child: const Text('Upload Proof'),
          ),
        ],
      ),
    );
  }

  void _showPaymentProofDialog(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Payment Proof'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF8BBD0),
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 32,
                    color: Color(0xFFF06292),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap to upload screenshot',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Reference Number',
                labelStyle: const TextStyle(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFF8BBD0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitPaymentProof(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF81C784),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPaymentProof(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'completed',
        'paymentProof': 'uploaded',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadOrders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payment proof submitted successfully'),
          backgroundColor: const Color(0xFF81C784),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: ${e.toString()}'),
          backgroundColor: const Color(0xFFF44336),
        ),
      );
    }
  }

  void _showOrderDetails(Map<String, dynamic> orderData) {
    final orderId = orderData['orderId'] ?? 'N/A';
    final createdAt = orderData['createdAt'] != null
        ? (orderData['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final status = orderData['status']?.toString() ?? 'pending';
    final displayStatus = _getDisplayStatus(status);
    final paymentMethod = orderData['paymentMethodName'] ?? orderData['paymentMethod'] ?? 'Unknown';
    final shippingMethod = orderData['shippingMethod'] ?? 'Regular Delivery';
    final shippingCost = orderData['shippingCost'] ?? 0;
    final subtotal = orderData['subtotal'] ?? 0;
    final tax = orderData['tax'] ?? 0;
    final totalAmount = orderData['totalAmount'] ?? 0;
    final items = orderData['items'] as List<dynamic>? ?? [];
    final userAddress = orderData['userAddress'] ?? 'No address provided';
    final userName = orderData['userName'] ?? 'Customer';
    final userPhone = orderData['userPhone'] ?? 'No phone';
    final orderNotes = orderData['orderNotes'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          margin: const EdgeInsets.only(top: 40),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  width: 35,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCCCCC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _getStatusColor(status),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            size: 12,
                            color: _getStatusColor(status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            displayStatus,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #$orderId',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                    Text(
                      DateFormat('dd MMMM yyyy, HH:mm').format(createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      const Text(
                        'Order Items',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...items.map((item) {
                        final itemMap = item as Map<String, dynamic>;
                        final name = itemMap['name'] ?? 'Unknown Product';
                        final quantity = itemMap['quantity'] ?? 0;
                        final price = itemMap['price'] ?? 0;
                        final originalPrice = itemMap['originalPrice'] ?? price;
                        final image = itemMap['imageUrl'] ?? itemMap['image'] ?? 'assets/product/default.jpg';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF0F0F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: const Color(0xFFFCE4EC),
                                  border: Border.all(color: const Color(0xFFF8BBD0)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: image.startsWith('http')
                                      ? Image.network(
                                    image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.shopping_bag,
                                        color: const Color(0xFFF06292).withOpacity(0.3),
                                      );
                                    },
                                  )
                                      : Image.asset(
                                    image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.shopping_bag,
                                        color: const Color(0xFFF06292).withOpacity(0.3),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                        color: Color(0xFF333333),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${quantity} x Rp ${_formatPrice(price)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                    if (originalPrice > price)
                                      Text(
                                        'Save Rp ${_formatPrice(originalPrice - price)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF81C784),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rp ${_formatPrice((price as int) * (quantity as int))}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 20),

                      const Text(
                        'Shipping Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE4EC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF8BBD0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFF06292),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userPhone,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1, color: Color(0xFFE0E0E0)),
                            const SizedBox(height: 8),
                            const Text(
                              'Delivery Address',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFF06292),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userAddress,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Payment Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF0F0F0)),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Payment Method', '$paymentMethod ${_getPaymentMethodIcon(paymentMethod)}'),
                            _buildDetailRow('Shipping Method', shippingMethod),
                            const Divider(color: Color(0xFFEEEEEE), height: 16),
                            _buildDetailRow('Subtotal', 'Rp ${_formatPrice(subtotal)}'),
                            _buildDetailRow('Shipping', 'Rp ${_formatPrice(shippingCost)}'),
                            if (tax > 0) _buildDetailRow('Tax', 'Rp ${_formatPrice(tax)}'),
                            const Divider(color: Color(0xFFEEEEEE), height: 16),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF06292),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'TOTAL',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_formatPrice(totalAmount)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 120,
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    if (status.toLowerCase() == 'pending')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _completePayment(orderId, orderData);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF06292),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Complete Payment',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (status.toLowerCase() != 'pending')
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: const BorderSide(color: Color(0xFFF06292)),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: Color(0xFFF06292),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isTotal ? const Color(0xFFF06292) : const Color(0xFF333333),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: const Color(0xFFF44336),
            ),
            const SizedBox(width: 10),
            const Text(
              'Cancel Order',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: TextStyle(
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'No',
              style: TextStyle(
                color: Color(0xFF666666),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('orders').doc(orderId).update({
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _loadOrders();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order cancelled successfully'),
            backgroundColor: const Color(0xFF81C784),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: ${e.toString()}'),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 120,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: const Color(0xFFF8BBD0),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 40,
                    color: const Color(0xFFFB3A80),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No Orders Yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Start shopping to see your orders here!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/products');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF06292),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Start Shopping',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 120,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: const Color(0xFFF8BBD0),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 40,
                    color: const Color(0xFFF06292),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Unable to Load Orders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadOrders,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF06292),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFB3A80),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[50]!,
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: screenWidth * 0.1,
                height: screenWidth * 0.1,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF06292)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading your orders...',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        )
            : _hasError
            ? _buildErrorState()
            : Column(
          children: [
            _buildFilterChips(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadOrders,
                color: const Color(0xFFF06292),
                backgroundColor: Colors.white,
                displacement: screenHeight * 0.02,
                child: _getFilteredOrders().isEmpty
                    ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: screenHeight * 0.7,
                    child: _buildEmptyState(),
                  ),
                )
                    : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: 8,
                    bottom: MediaQuery.of(context).padding.bottom + 120,
                  ),
                  itemCount: _getFilteredOrders().length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(_getFilteredOrders()[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}