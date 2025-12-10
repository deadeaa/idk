import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/user_provider.dart';

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<DocumentSnapshot> _allDeliveries = [];
  List<DocumentSnapshot> _filteredDeliveries = [];
  Timer? _timer;

  String _selectedFilter = 'all';
  final List<String> _statusFilters = [
    'all',
    'pending',
    'completed',
    'shipped',
    'delivered'
  ];

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkAndUpdateStatus();
    });
  }

  Future<void> _checkAndUpdateStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      bool hasUpdates = false;

      for (var doc in _allDeliveries) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'];
        final orderId = doc.id;
        final createdAt = data['createdAt'] as Timestamp?;

        if (status == 'completed' && createdAt != null) {
          final completedTime = createdAt.toDate();
          final tenMinutesLater = completedTime.add(const Duration(minutes: 10));

          if (now.isAfter(tenMinutesLater)) {
            print('Updating order $orderId to shipped');

            await _firestore.collection('orders').doc(orderId).update({
              'status': 'shipped',
              'shippedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

            hasUpdates = true;
          }
        }
      }

      if (hasUpdates) {
        await _loadDeliveries();
      }

    } catch (e) {
      print('Error updating status: $e');
    }
  }

  Future<void> _loadDeliveries() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Please login to view deliveries';
          _isLoading = false;
        });
        return;
      }

      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .where('status', whereIn: [
          'pending',
          'completed',
          'shipped',
          'delivered'
        ])
            .orderBy('createdAt', descending: true)
            .get();
      } catch (e) {
        snapshot = await _firestore
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .where('status', whereIn: [
          'pending',
          'completed',
          'shipped',
          'delivered'
        ])
            .get();

        _allDeliveries = snapshot.docs;
        _allDeliveries.sort((a, b) {
          final aDate = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bDate = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          return (bDate?.millisecondsSinceEpoch ?? 0)
              .compareTo(aDate?.millisecondsSinceEpoch ?? 0);
        });

        _applyFilter();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _allDeliveries = snapshot.docs;
        _applyFilter();
        _isLoading = false;
      });

    } on FirebaseException catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Database error: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load deliveries: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'all') {
      _filteredDeliveries = List.from(_allDeliveries);
    } else {
      _filteredDeliveries = _allDeliveries.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['status'] == _selectedFilter;
      }).toList();
    }
  }

  Future<void> _forceToShipped(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'shipped',
        'shippedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order forced to shipped!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );

      await _loadDeliveries();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: const Color(0xFFF44336),
        ),
      );
    }
  }

  Widget _buildNotLoggedIn() {
    return Scaffold(
        backgroundColor: const Color(0xFFEDF5FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFB3A80),
          foregroundColor: Colors.white,
          title: const Text('Deliveries',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(
                        color: const Color(0xFFF8BBD0),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.local_shipping,
                      size: 50,
                      color: const Color(0xFFF06292),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Please Login to View Deliveries',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Login to track your orders and deliveries in real-time',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        )
    );
  }

  Widget _buildEmptyDeliveries() {
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 120,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: const Color(0xFF90CAF9),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    size: 50,
                    color: const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Active Deliveries',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Complete your purchase to see delivery tracking here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/products');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF06292),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
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

  String _getShortShippingMethod(String method) {
    if (method.toLowerCase().contains('same day') ||
        method.toLowerCase().contains('today')) {
      return 'Today Delivery';
    }
    if (method.toLowerCase().contains('express')) {
      return 'Express Delivery';
    }
    if (method.toLowerCase().contains('regular')) {
      return 'Regular Delivery';
    }
    if (method.toLowerCase().contains('pickup') ||
        method.toLowerCase().contains('store') ||
        method.toLowerCase().contains('self')) {
      return 'Store Pickup';
    }
    if (method.toLowerCase().contains('next day')) {
      return 'Next Day Delivery';
    }
    return method.length > 20 ? '${method.substring(0, 20)}...' : method;
  }

  DateTime _calculateEstimatedDelivery(DateTime orderDate, String shippingMethod) {
    if (shippingMethod.toLowerCase().contains('same day') ||
        shippingMethod.toLowerCase().contains('today')) {
      return orderDate;
    }
    if (shippingMethod.toLowerCase().contains('express')) {
      return orderDate.add(const Duration(days: 2));
    }
    if (shippingMethod.toLowerCase().contains('next day')) {
      return orderDate.add(const Duration(days: 1));
    }
    if (shippingMethod.toLowerCase().contains('pickup') ||
        shippingMethod.toLowerCase().contains('store') ||
        shippingMethod.toLowerCase().contains('self')) {
      return orderDate;
    }
    return orderDate.add(const Duration(days: 5));
  }

  Widget _buildDeliveryCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final status = data['status'] ?? 'pending';
    final orderIdStr = data['orderId'] ?? doc.id.substring(0, 8).toUpperCase();
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final shippedAt = data['shippedAt'] != null
        ? (data['shippedAt'] as Timestamp).toDate()
        : null;
    final totalAmount = data['totalAmount'] ?? 0;
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final shippingMethod = data['shippingMethod'] ?? 'Regular Delivery';

    final estimatedDelivery = _calculateEstimatedDelivery(createdAt, shippingMethod);

    Color getStatusColor(String status) {
      switch (status) {
        case 'pending':
          return const Color(0xFFF06292);
        case 'completed':
          return const Color(0xFF4CAF50);
        case 'shipped':
          return const Color(0xFF2196F3);
        case 'delivered':
          return const Color(0xFF009688);
        default:
          return const Color(0xFFB0BEC5);
      }
    }

    IconData getStatusIcon(String status) {
      switch (status) {
        case 'pending':
          return Icons.pending_actions;
        case 'completed':
          return Icons.check_circle;
        case 'shipped':
          return Icons.local_shipping;
        case 'delivered':
          return Icons.verified;
        default:
          return Icons.pending;
      }
    }

    String getStatusText(String status) {
      switch (status) {
        case 'pending':
          return 'Pending';
        case 'completed':
          return 'Paid';
        case 'shipped':
          return 'On Delivery';
        case 'delivered':
          return 'Delivered';
        default:
          return 'Pending';
      }
    }

    String getShippingTime(String method) {
      if (method.toLowerCase().contains('same day') ||
          method.toLowerCase().contains('today')) {
        return 'Today';
      }
      if (method.toLowerCase().contains('express')) {
        return '1-2 days';
      }
      if (method.toLowerCase().contains('next day')) {
        return 'Tomorrow';
      }
      if (method.toLowerCase().contains('pickup') ||
          method.toLowerCase().contains('store') ||
          method.toLowerCase().contains('self')) {
        return 'Self Pickup';
      }
      return '3-5 days';
    }

    String getShippingSubtitle(String method) {
      if (method.toLowerCase().contains('same day') ||
          method.toLowerCase().contains('today')) {
        return 'Arrives today';
      }
      if (method.toLowerCase().contains('express')) {
        return '1-2 business days';
      }
      if (method.toLowerCase().contains('pickup') ||
          method.toLowerCase().contains('store') ||
          method.toLowerCase().contains('self')) {
        return 'Pickup at store';
      }
      return '3-5 business days';
    }

    String? getNextStatusTime() {
      final now = DateTime.now();

      if (status == 'completed') {
        final tenMinutesLater = createdAt.add(const Duration(minutes: 10));
        if (now.isBefore(tenMinutesLater)) {
          final remaining = tenMinutesLater.difference(now);
          final minutes = remaining.inMinutes;
          final seconds = remaining.inSeconds % 60;
          return 'Shipping in ${minutes}m ${seconds}s';
        } else {
          return 'Shipping now...';
        }
      }

      return null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showOrderDetails(doc.id, data);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Order #${orderIdStr.length > 6 ? orderIdStr.substring(orderIdStr.length - 6) : orderIdStr}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF333333),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yy').format(createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: getStatusColor(status).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            getStatusIcon(status),
                            size: 12,
                            color: getStatusColor(status),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            getStatusText(status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: getStatusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: const Color(0xFFFCE4EC),
                          border: Border.all(color: const Color(0xFFF8BBD0)),
                        ),
                        child: items.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            items[0]['imageUrl'] ?? items[0]['image'] ?? 'assets/product/default.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.shopping_bag,
                                color: const Color(0xFFF06292).withOpacity(0.3),
                              );
                            },
                          ),
                        )
                            : Icon(
                          Icons.shopping_bag,
                          color: const Color(0xFFF06292).withOpacity(0.3),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${items.length} item${items.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF444444),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.local_shipping,
                                  size: 12,
                                  color: const Color(0xFF2196F3),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _getShortShippingMethod(shippingMethod),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              getShippingSubtitle(shippingMethod),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            getShippingTime(shippingMethod),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: shippingMethod.toLowerCase().contains('pickup')
                                  ? const Color(0xFF9C27B0)
                                  : const Color(0xFF2196F3),
                            ),
                          ),
                          Text(
                            shippingMethod.toLowerCase().contains('pickup')
                                ? 'Self Pickup'
                                : 'Delivery',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: status == 'shipped'
                        ? const Color(0xFFE3F2FD)
                        : status == 'completed'
                        ? const Color(0xFFE8F5E9)
                        : status == 'delivered'
                        ? const Color(0xFFE0F2F1)
                        : const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: status == 'shipped'
                          ? const Color(0xFF90CAF9)
                          : status == 'completed'
                          ? const Color(0xFF81C784)
                          : status == 'delivered'
                          ? const Color(0xFF80CBC4)
                          : const Color(0xFFF8BBD0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        status == 'shipped'
                            ? Icons.local_shipping
                            : status == 'completed'
                            ? Icons.check_circle
                            : status == 'delivered'
                            ? Icons.verified
                            : Icons.pending_actions,
                        size: 16,
                        color: getStatusColor(status),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status == 'shipped'
                                  ? 'Package is on the way'
                                  : status == 'completed'
                                  ? 'Payment completed'
                                  : status == 'delivered'
                                  ? 'Package delivered'
                                  : 'Waiting for payment',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: getStatusColor(status),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              getNextStatusTime() ??
                                  (status == 'shipped'
                                      ? 'Estimated arrival: ${DateFormat('dd MMM').format(estimatedDelivery)}'
                                      : status == 'completed'
                                      ? 'Will be shipped in 10 minutes'
                                      : status == 'delivered'
                                      ? 'Order completed successfully'
                                      : 'Complete payment to continue'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF888888),
                          ),
                        ),
                        Text(
                          'Rp ${_formatPrice(totalAmount)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF06292),
                          ),
                        ),
                      ],
                    ),

                    if (status == 'shipped')
                      ElevatedButton(
                        onPressed: () {
                          _markAsDelivered(doc.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Package Arrived',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (status == 'delivered')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF009688).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF009688)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 14, color: Color(0xFF009688)),
                            SizedBox(width: 6),
                            Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF009688),
                              ),
                            ),
                          ],
                        ),
                      ),

                    OutlinedButton(
                      onPressed: () {
                        _showOrderDetails(doc.id, data);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2196F3),
                        side: const BorderSide(color: Color(0xFF2196F3)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusFilters.map((filter) {
            return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    filter == 'all'
                        ? 'All'
                        : filter[0].toUpperCase() + filter.substring(1),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _selectedFilter == filter ? Colors.white : const Color(0xFF666666),
                    ),
                  ),
                  selected: _selectedFilter == filter,
                  selectedColor: const Color(0xFFF06292),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _selectedFilter == filter
                          ? const Color(0xFFF06292)
                          : const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                      _applyFilter();
                    });
                  },
                )
            );
          }).toList(),
        ),
      ),
    );
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

  Future<void> _markAsDelivered(String orderId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
            SizedBox(width: 10),
            Text(
              'Confirm Delivery',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          'Have you received your package?',
          style: TextStyle(
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Not Yet',
              style: TextStyle(
                color: Color(0xFF666666),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateOrderStatus(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Received'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadDeliveries();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Package marked as delivered!'),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${e.toString()}'),
          backgroundColor: const Color(0xFFF44336),
        ),
      );
    }
  }

  void _showOrderDetails(String orderId, Map<String, dynamic> data) {
    final orderIdStr = data['orderId'] ?? orderId.substring(0, 8).toUpperCase();
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final status = data['status'] ?? 'pending';
    final totalAmount = data['totalAmount'] ?? 0;
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final userAddress = data['userAddress'] ?? 'No address provided';
    final userName = data['userName'] ?? 'Customer';
    final userPhone = data['userPhone'] ?? 'No phone';
    final shippingMethod = data['shippingMethod'] ?? 'Regular Delivery';
    final shippingCost = data['shippingCost'] ?? 0;
    final subtotal = data['subtotal'] ?? 0;
    final tax = data['tax'] ?? 0;

    final estimatedDelivery = _calculateEstimatedDelivery(createdAt, shippingMethod);

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
                      'Delivery Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: status == 'shipped'
                            ? const Color(0xFFE3F2FD)
                            : status == 'completed'
                            ? const Color(0xFFE8F5E9)
                            : status == 'delivered'
                            ? const Color(0xFFE0F2F1)
                            : const Color(0xFFFCE4EC),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: status == 'shipped'
                              ? const Color(0xFF2196F3)
                              : status == 'completed'
                              ? const Color(0xFF4CAF50)
                              : status == 'delivered'
                              ? const Color(0xFF009688)
                              : const Color(0xFFF06292),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status == 'shipped'
                                ? Icons.local_shipping
                                : status == 'completed'
                                ? Icons.check_circle
                                : status == 'delivered'
                                ? Icons.verified
                                : Icons.pending_actions,
                            size: 12,
                            color: status == 'shipped'
                                ? const Color(0xFF2196F3)
                                : status == 'completed'
                                ? const Color(0xFF4CAF50)
                                : status == 'delivered'
                                ? const Color(0xFF009688)
                                : const Color(0xFFF06292),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status == 'shipped'
                                ? 'On Delivery'
                                : status == 'completed'
                                ? 'Paid'
                                : status == 'delivered'
                                ? 'Delivered'
                                : 'Pending',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: status == 'shipped'
                                  ? const Color(0xFF2196F3)
                                  : status == 'completed'
                                  ? const Color(0xFF4CAF50)
                                  : status == 'delivered'
                                  ? const Color(0xFF009688)
                                  : const Color(0xFFF06292),
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
                      'Order #$orderIdStr',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                    Text(
                      'Ordered on ${DateFormat('dd MMMM yyyy').format(createdAt)}',
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
                        'Delivery Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildTimelineStep(
                        icon: Icons.shopping_bag,
                        title: 'Order Placed',
                        subtitle: DateFormat('dd MMM, HH:mm').format(createdAt),
                        isCompleted: true,
                        color: const Color(0xFFF06292),
                      ),
                      _buildTimelineStep(
                        icon: Icons.payment,
                        title: 'Payment',
                        subtitle: status == 'pending' ? 'Pending' : 'Completed',
                        isCompleted: status != 'pending',
                        isCurrent: status == 'pending',
                        color: const Color(0xFFF06292),
                      ),
                      _buildTimelineStep(
                        icon: Icons.check_circle,
                        title: 'Payment Completed',
                        subtitle: status == 'completed' ? 'Completed' : 'Waiting',
                        isCompleted: status == 'completed' || status == 'shipped' || status == 'delivered',
                        isCurrent: status == 'completed',
                        color: const Color(0xFF4CAF50),
                      ),
                      _buildTimelineStep(
                        icon: Icons.local_shipping,
                        title: 'On Delivery',
                        subtitle: status == 'shipped' ? 'On the way' : 'Not yet',
                        isCompleted: status == 'delivered',
                        isCurrent: status == 'shipped',
                        color: const Color(0xFF2196F3),
                      ),
                      _buildTimelineStep(
                        icon: Icons.check_circle,
                        title: 'Delivered',
                        subtitle: DateFormat('dd MMM').format(estimatedDelivery),
                        isCompleted: status == 'delivered',
                        color: const Color(0xFF009688),
                      ),

                      const SizedBox(height: 24),

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
                            const Row(
                              children: [
                                Icon(Icons.person, size: 14, color: Color(0xFFF06292)),
                                SizedBox(width: 8),
                                Text(
                                  'Recipient',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFF06292),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                                fontSize: 13,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFE0E0E0)),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Color(0xFFF06292)),
                                SizedBox(width: 8),
                                Text(
                                  'Delivery Address',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFF06292),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              userAddress,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFE0E0E0)),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                Icon(Icons.local_shipping, size: 14, color: Color(0xFF2196F3)),
                                SizedBox(width: 8),
                                Text(
                                  'Shipping Method',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2196F3),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getShortShippingMethod(shippingMethod),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                            if (!shippingMethod.toLowerCase().contains('pickup') &&
                                !shippingMethod.toLowerCase().contains('store') &&
                                !shippingMethod.toLowerCase().contains('self'))
                              Text(
                                shippingMethod.toLowerCase().contains('same day') ||
                                    shippingMethod.toLowerCase().contains('today')
                                    ? 'Arrives today'
                                    : 'Estimated: ${DateFormat('dd MMM yyyy').format(estimatedDelivery)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                              )
                            else
                              Text(
                                'Ready for pickup',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9C27B0),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Order Summary',
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
                            _buildSummaryRow('Subtotal', 'Rp ${_formatPrice(subtotal)}'),
                            _buildSummaryRow('Shipping', 'Rp ${_formatPrice(shippingCost)}'),
                            if (tax > 0) _buildSummaryRow('Tax', 'Rp ${_formatPrice(tax)}'),
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
                    if (status == 'shipped')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _markAsDelivered(orderId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Package Arrived',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (status != 'shipped')
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

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isCurrent = false,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted || isCurrent ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCompleted || isCurrent ? color : const Color(0xFFE0E0E0),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 14,
              color: isCompleted || isCurrent ? Colors.white : const Color(0xFFE0E0E0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted || isCurrent ? color : const Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted || isCurrent ? const Color(0xFF666666) : const Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 120,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                  'Unable to Load Deliveries',
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
                  onPressed: _loadDeliveries,
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
    final userProvider = Provider.of<UserProvider>(context);
    final user = _auth.currentUser;

    if (user == null || !userProvider.isLoggedIn) {
      return _buildNotLoggedIn();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFB3A80),
        foregroundColor: Colors.white,
        title: const Text(
          'My Deliveries',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.bug_report_outlined),
            onSelected: (value) {
              if (value == 'refresh') {
                _loadDeliveries();
              } else if (value == 'check_status') {
                _checkAndUpdateStatus();
              } else if (value == 'force_all_shipped') {
                for (var doc in _allDeliveries) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['status'] == 'completed') {
                    _forceToShipped(doc.id);
                  }
                }
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'refresh',
                  child: Text('Refresh Data'),
                ),
                const PopupMenuItem<String>(
                  value: 'check_status',
                  child: Text('Check Status Now'),
                ),
                const PopupMenuItem<String>(
                  value: 'force_all_shipped',
                  child: Text('Force All to Shipped'),
                ),
              ];
            },
          ),
        ],
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
        child: Column(
          children: [
            _buildFilterChips(),

            Expanded(
              child: _isLoading
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF06292)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading deliveries...',
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
                  : _filteredDeliveries.isEmpty
                  ? _buildEmptyDeliveries()
                  : RefreshIndicator(
                onRefresh: _loadDeliveries,
                color: const Color(0xFFF06292),
                backgroundColor: const Color(0xFFE3F2FD),
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 120,
                  ),
                  itemCount: _filteredDeliveries.length,
                  itemBuilder: (context, index) {
                    return _buildDeliveryCard(_filteredDeliveries[index]);
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