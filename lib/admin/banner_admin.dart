import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminBannerPage extends StatefulWidget {
  const AdminBannerPage({super.key});

  @override
  State<AdminBannerPage> createState() => _AdminBannerPageState();
}

class _AdminBannerPageState extends State<AdminBannerPage> {
  String? _selectedBannerPath;
  bool _uploading = false;
  String? _editingId;
  final TextEditingController _orderController = TextEditingController();
  final TextEditingController _editOrderController = TextEditingController();

  final List<Map<String, String>> _availableBanners = [
    {'name': 'Banner 1', 'path': 'assets/images/banner1.png'},
    {'name': 'Banner 2', 'path': 'assets/images/banner2.png'},
    {'name': 'Banner 3', 'path': 'assets/images/banner3.png'},
  ];

  List<Map<String, dynamic>> _banners = [];

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    try {
      print('🔄 Loading banners from Firestore...');

      final snapshot = await FirebaseFirestore.instance
          .collection("banners")
          .orderBy("order", descending: false)
          .get();

      print('📥 Received ${snapshot.docs.length} banners');

      setState(() {
        _banners = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'image': data['image'] ?? 'assets/images/banner1.png',
            'order': data['order'] ?? 0,
            'active': data['active'] ?? true,
            'createdAt': data['createdAt'] ?? DateTime.now(),
          };
        }).toList();
      });

      print('✅ Banners loaded: ${_banners.length} items');

    } catch (e) {
      print('❌ Error loading banners: $e');
      _showError('Failed to load banners: $e');
    }
  }

  Future<void> _addBanner() async {
    if (_selectedBannerPath == null) {
      _showError('Please select a banner');
      return;
    }

    setState(() => _uploading = true);

    try {
      final order = int.tryParse(_orderController.text) ?? (_banners.isEmpty ? 0 : (_banners.last['order'] + 1));

      final newBanner = {
        "image": _selectedBannerPath,
        "order": order,
        "active": true,
        "createdAt": FieldValue.serverTimestamp(),
      };

      print('💾 Saving to Firestore: $_selectedBannerPath with order $order');

      final optimisticId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _banners.add({
          'id': optimisticId,
          'image': _selectedBannerPath,
          'order': order,
          'active': true,
          'isOptimistic': true,
        });
        _banners.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
      });

      final docRef = await FirebaseFirestore.instance
          .collection("banners")
          .add(newBanner);

      print('✅ Saved to Firestore with ID: ${docRef.id}');

      setState(() {
        _banners.removeWhere((item) => item['id'] == optimisticId);
        _banners.add({
          'id': docRef.id,
          'image': _selectedBannerPath,
          'order': order,
          'active': true,
          'createdAt': DateTime.now(),
        });
        _banners.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
      });

      _resetForm();
      _showSuccess('Banner added successfully! 🎉');

    } catch (e) {
      print('❌ Error saving banner: $e');
      setState(() {
        _banners.removeWhere((item) => item['id'].toString().startsWith('temp_'));
      });
      _showError('Failed to add banner: $e');
    } finally {
      setState(() => _uploading = false);
    }
  }

  Widget _buildBannerSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Banner:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: _buildBannerGrid(),
            ),
          ),
        ),
        if (_selectedBannerPath != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      image: AssetImage(_selectedBannerPath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected: ${_getBannerName(_selectedBannerPath!)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.purple.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getBannerName(String path) {
    try {
      return _availableBanners.firstWhere((banner) => banner['path'] == path)['name'] ?? 'Unknown';
    } catch (e) {
      return 'Unknown Banner';
    }
  }

  Widget _buildBannerGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _availableBanners.map((banner) {
        final isSelected = _selectedBannerPath == banner['path'];

        return SizedBox(
          width: 100,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedBannerPath = banner['path']!;
                print('🎯 Selected: ${banner['name']} - Path: ${banner['path']}');
              });
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.purple.shade50 : Colors.grey.shade50,
                border: Border.all(
                  color: isSelected ? Colors.purple.shade700 : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      image: DecorationImage(
                        image: AssetImage(banner['path']!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    banner['name']!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.purple.shade700 : Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderInput() {
    return TextField(
      controller: _editingId != null ? _editOrderController : _orderController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: "Display Order",
        hintText: "0",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.sort),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  void _resetForm() {
    _selectedBannerPath = null;
    _orderController.clear();
  }

  Widget _buildBannerItem(Map<String, dynamic> banner) {
    final isOptimistic = banner['isOptimistic'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            image: DecorationImage(
              image: AssetImage(banner['image']),
              fit: BoxFit.cover,
            ),
          ),
          child: isOptimistic
              ? Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          )
              : null,
        ),
        title: Text(
          'Order: ${banner['order']}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isOptimistic ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Text(
          '${_getBannerName(banner['image'])} - ${banner['active'] == true ? 'Active' : 'Inactive'}',
          style: TextStyle(
            fontSize: 12,
            color: banner['active'] == true ? Colors.green : Colors.red,
          ),
        ),
        trailing: isOptimistic
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue.shade600, size: 20),
              onPressed: () => _startEdit(banner),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteBanner(
                banner['id'],
                'Banner Order ${banner['order']}',
              ),
              tooltip: 'Delete',
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: banner['active'] == true,
                onChanged: (value) => _toggleBannerActive(banner['id'], value),
                activeColor: Colors.green,
                inactiveThumbColor: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startEdit(Map<String, dynamic> banner) {
    setState(() {
      _editingId = banner['id'];
      _selectedBannerPath = banner['image'];
      _editOrderController.text = banner['order'].toString();
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _selectedBannerPath = null;
      _editOrderController.clear();
    });
  }

  Future<void> _updateBanner() async {
    if (_editingId == null) return;

    setState(() => _uploading = true);

    try {
      final order = int.tryParse(_editOrderController.text) ?? 0;

      final updatedData = {
        "image": _selectedBannerPath,
        "order": order,
      };

      print('✏️ Updating banner $_editingId with order $order');

      setState(() {
        final index = _banners.indexWhere((item) => item['id'] == _editingId);
        _banners[index] = {
          ..._banners[index],
          'image': _selectedBannerPath,
          'order': order,
        };
        _banners.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
      });

      await FirebaseFirestore.instance
          .collection("banners")
          .doc(_editingId)
          .update(updatedData);

      _cancelEdit();
      _showSuccess('Banner updated successfully! ✅');
    } catch (e) {
      print('❌ Error updating banner: $e');
      _loadBanners();
      _showError('Failed to update banner: $e');
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _toggleBannerActive(String id, bool active) async {
    try {
      print('🔘 Toggling banner $id active: $active');

      setState(() {
        final index = _banners.indexWhere((item) => item['id'] == id);
        _banners[index]['active'] = active;
      });

      await FirebaseFirestore.instance
          .collection("banners")
          .doc(id)
          .update({"active": active});

      _showSuccess('Banner ${active ? 'activated' : 'deactivated'}!');
    } catch (e) {
      print('❌ Error toggling banner: $e');
      _loadBanners();
      _showError('Failed to update banner: $e');
    }
  }

  Future<void> _deleteBanner(String id, String bannerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$bannerName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    print('🗑️ Deleting banner $id');

    final deletedItem = _banners.firstWhere((item) => item['id'] == id);
    setState(() => _banners.removeWhere((item) => item['id'] == id));

    try {
      await FirebaseFirestore.instance
          .collection("banners")
          .doc(id)
          .delete();

      _showSuccess('Banner deleted successfully 🗑️');
    } catch (e) {
      print('❌ Error deleting banner: $e');
      setState(() => _banners.add(deletedItem));
      _showError('Failed to delete banner: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Banner Management",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBanners,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 3,
                    shadowColor: Colors.purple.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editingId != null ? '✏️ Edit Banner' : '➕ Add New Banner',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildBannerSelection(),
                          const SizedBox(height: 16),
                          _buildOrderInput(),
                          const SizedBox(height: 16),
                          if (_uploading)
                            const Center(
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Saving...',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          else
                            Row(
                              children: [
                                if (_editingId != null) ...[
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _cancelEdit,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        side: BorderSide(color: Colors.grey.shade400),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(color: Colors.grey.shade700),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _updateBanner,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.shade600,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      child: const Text(
                                        'Update',
                                        style: TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ] else
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _addBanner,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple.shade700,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      child: const Text(
                                        'Save Banner',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Text(
                        '🖼️ Your Banners',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_banners.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: _loadBanners,
                        tooltip: 'Refresh List',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  _banners.isEmpty
                      ? Container(
                    margin: const EdgeInsets.only(top: 40),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.photo_library, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No banners yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Add your first banner above!',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _banners.length,
                    itemBuilder: (context, index) {
                      return _buildBannerItem(_banners[index]);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}