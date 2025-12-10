import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'cart_item.dart';
import 'history_payment.dart';

class CheckoutFormPage extends StatefulWidget {
  final List<CartItem> selectedItems;

  const CheckoutFormPage({super.key, required this.selectedItems});

  @override
  State<CheckoutFormPage> createState() => _CheckoutFormPageState();
}

class _CheckoutFormPageState extends State<CheckoutFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedShipping;
  String? _selectedPayment;
  bool _agreeTerms = false;
  bool _saveInfo = true;
  bool _isSubmitting = false;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  final List<String> _shippingOptions = [
    'Regular Delivery (3-5 days) - Rp 10.000',
    'Express Delivery (1-2 days) - Rp 25.000',
    'Same Day Delivery - Rp 50.000',
    'Store Pickup - FREE'
  ];

  final List<String> _paymentMethods = [
    'Credit/Debit Card',
    'Bank Transfer',
    'E-Wallet (OVO/GoPay/Dana)',
    'Cash on Delivery',
    'PayLater'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();

          _nameController.text = _userData?['fullName'] ?? '';
          _emailController.text = _userData?['email'] ?? user.email ?? '';
          _phoneController.text = _userData?['phone'] ?? '';
          _addressController.text = _userData?['address'] ?? '';

          _isLoading = false;
        });
      } else {
        _emailController.text = user.email ?? '';
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _calculateTotal() {
    int total = 0;
    for (var item in widget.selectedItems) {
      final price = item.salePrice > 0 ? item.salePrice : item.price;
      total += price * item.quantity;
    }

    if (_selectedShipping?.contains('Regular') == true) total += 10000;
    if (_selectedShipping?.contains('Express') == true) total += 25000;
    if (_selectedShipping?.contains('Same Day') == true) total += 50000;

    return total;
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to the terms and conditions')),
      );
      return;
    }

    if (_selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final cartProvider = context.read<CartProvider>();
      for (var item in widget.selectedItems) {
        await cartProvider.removeFromCart(item.productId);
      }

      final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}${user.uid.substring(0, 5)}';

      final orderData = {
        'orderId': orderId,
        'userId': user.uid,
        'userName': _nameController.text.trim(),
        'userEmail': _emailController.text.trim(),
        'userPhone': _phoneController.text.trim(),
        'userAddress': _addressController.text.trim(),
        'items': widget.selectedItems.map((item) => {
          'productId': item.productId,
          'name': item.name,
          'price': item.salePrice > 0 ? item.salePrice : item.price,
          'originalPrice': item.price,
          'quantity': item.quantity,
          'imageUrl': item.image,
          'category': item.category,
        }).toList(),
        'shippingMethod': _selectedShipping ?? '',
        'paymentMethod': _selectedPayment ?? '',
        'orderNotes': _notesController.text.trim(),
        'subtotal': _calculateTotal() - _getShippingCost(),
        'shippingCost': _getShippingCost(),
        'totalAmount': _calculateTotal(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set(orderData);

      if (_saveInfo && user.uid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fullName': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Order placed successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PaymentHistoryPage(),
        ),
      );

    } catch (e) {
      print('Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  int _getShippingCost() {
    if (_selectedShipping?.contains('Regular') == true) return 10000;
    if (_selectedShipping?.contains('Express') == true) return 25000;
    if (_selectedShipping?.contains('Same Day') == true) return 50000;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: _buildCustomAppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final total = _calculateTotal();

    return Scaffold(
      appBar: _buildCustomAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('🛒 Order Summary'),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    for (var item in widget.selectedItems)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(item.image),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.quantity} × Rp ${_formatPrice(item.salePrice > 0 ? item.salePrice : item.price)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Rp ${_formatPrice((item.salePrice > 0 ? item.salePrice : item.price) * item.quantity)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Items:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          '${widget.selectedItems.length} items',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          'Rp ${_formatPrice(total - _getShippingCost())}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('👤 Customer Information'),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length < 10) {
                    return 'Phone number must be at least 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Shipping Address *',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('🚚 Shipping Method'),

              DropdownButtonFormField<String>(
                value: _selectedShipping,
                decoration: const InputDecoration(
                  labelText: 'Select Shipping Method *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_shipping),
                ),
                items: _shippingOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedShipping = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select shipping method';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('💳 Payment Method'),

              Column(
                children: _paymentMethods.map((method) {
                  return RadioListTile<String>(
                    title: Text(method),
                    value: method,
                    groupValue: _selectedPayment,
                    onChanged: (value) {
                      setState(() => _selectedPayment = value);
                    },
                    secondary: Icon(_getPaymentIcon(method)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              if (_selectedPayment != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 10),
                      Text(
                        'Selected: $_selectedPayment',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              _buildSectionHeader('📝 Additional Information'),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Order Notes (Optional)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Save my information for next time'),
                    value: _saveInfo,
                    onChanged: (value) {
                      setState(() => _saveInfo = value ?? false);
                    },
                    secondary: const Icon(Icons.save),
                  ),

                  CheckboxListTile(
                    title: RichText(
                      text: const TextSpan(
                        text: 'I agree to the ',
                        style: TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: 'Terms and Conditions',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' *'),
                        ],
                      ),
                    ),
                    value: _agreeTerms,
                    onChanged: (value) {
                      setState(() => _agreeTerms = value ?? false);
                    },
                    secondary: const Icon(Icons.description),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('💰 Final Total'),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('Rp ${_formatPrice(total - _getShippingCost())}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Shipping:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          _selectedShipping?.contains('FREE') == true
                              ? 'FREE'
                              : _selectedShipping?.contains('Rp') == true
                              ? _selectedShipping!.split('-').last.trim()
                              : _selectedShipping != null ? 'Rp ${_formatPrice(_getShippingCost())}' : '-',
                          style: TextStyle(
                            color: _selectedShipping?.contains('FREE') == true
                                ? Colors.green
                                : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          'Rp ${_formatPrice(total)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isSubmitting ? 'Processing Order...' : 'Place Order & Pay',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        child: AppBar(
          title: const Text(
            'Checkout Order',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.pink.shade700,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          elevation: 10,
          shadowColor: Colors.pink.shade300,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.pink,
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'Credit/Debit Card':
        return Icons.credit_card;
      case 'Bank Transfer':
        return Icons.account_balance;
      case 'E-Wallet (OVO/GoPay/Dana)':
        return Icons.wallet;
      case 'Cash on Delivery':
        return Icons.money;
      case 'PayLater':
        return Icons.schedule;
      default:
        return Icons.payment;
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }
}