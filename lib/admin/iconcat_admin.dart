import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCategoryIconPage extends StatefulWidget {
  const AdminCategoryIconPage({super.key});

  @override
  State<AdminCategoryIconPage> createState() => _AdminCategoryIconPageState();
}

class _AdminCategoryIconPageState extends State<AdminCategoryIconPage> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _editCategoryController = TextEditingController();
  String? _selectedIconPath;
  bool _uploading = false;
  String? _editingId;

  final List<Map<String, String>> _availableIcons = [
    {'name': 'Moisturizer', 'path': 'assets/icons/mois.png'},
    {'name': 'Cleanser', 'path': 'assets/icons/fw.png'},
    {'name': 'Sunscreen', 'path': 'assets/icons/suns.png'},
    {'name': 'Serum', 'path': 'assets/icons/serum.png'},
    {'name': 'Lip Care', 'path': 'assets/icons/lip.png'},
    {'name': 'Toner', 'path': 'assets/icons/toner.png'},
    {'name': 'Face Mask', 'path': 'assets/icons/mask.png'},
  ];

  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      print('🔄 Loading categories from Firestore...');

      final snapshot = await FirebaseFirestore.instance
          .collection("categoryIcons")
          .orderBy("createdAt", descending: true)
          .get();

      print('📥 Received ${snapshot.docs.length} categories');

      setState(() {
        _categories = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'category': data['category'] ?? 'No Name',
            'icon': data['icon'] ?? 'assets/icons/skincare.png',
            'createdAt': data['createdAt'] ?? DateTime.now(),
          };
        }).toList();
      });

      print('✅ Categories loaded: ${_categories.length} items');

    } catch (e) {
      print('❌ Error loading categories: $e');
      _showError('Failed to load categories: $e');
    }
  }

  Future<void> _addCategory() async {
    if (_categoryController.text.isEmpty || _selectedIconPath == null) {
      _showError('Please enter category name and select icon');
      return;
    }

    setState(() => _uploading = true);

    try {
      final newCategory = {
        "category": _categoryController.text.trim(),
        "icon": _selectedIconPath,
        "createdAt": FieldValue.serverTimestamp(),
      };

      print('💾 Saving to Firestore: ${_categoryController.text.trim()}');

      final optimisticId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _categories.insert(0, {
          'id': optimisticId,
          'category': _categoryController.text.trim(),
          'icon': _selectedIconPath,
          'isOptimistic': true,
        });
      });

      final docRef = await FirebaseFirestore.instance
          .collection("categoryIcons")
          .add(newCategory);

      print('✅ Saved to Firestore with ID: ${docRef.id}');

      setState(() {
        _categories.removeWhere((item) => item['id'] == optimisticId);
        _categories.insert(0, {
          'id': docRef.id,
          'category': _categoryController.text.trim(),
          'icon': _selectedIconPath,
          'createdAt': DateTime.now(),
        });
      });

      _resetForm();
      _showSuccess('Category added successfully! 🎉');

    } catch (e) {
      print('❌ Error saving category: $e');
      setState(() {
        _categories.removeWhere((item) => item['id'].toString().startsWith('temp_'));
      });
      _showError('Failed to add category: $e');
    } finally {
      setState(() => _uploading = false);
    }
  }

  Widget _buildIconSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Icon:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: _buildIconGrid(),
            ),
          ),
        ),
        if (_selectedIconPath != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    image: DecorationImage(
                      image: AssetImage(_selectedIconPath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected: ${_availableIcons.firstWhere((icon) => icon['path'] == _selectedIconPath)['name']}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade800,
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

  Widget _buildIconGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableIcons.map((icon) {
        final isSelected = _selectedIconPath == icon['path'];

        return SizedBox(
          width: 70,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedIconPath = icon['path']!;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
                border: Border.all(
                  color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      image: DecorationImage(
                        image: AssetImage(icon['path']!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    icon['name']!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
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

  void _resetForm() {
    _categoryController.clear();
    _selectedIconPath = null;
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final isOptimistic = category['isOptimistic'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: AssetImage(category['icon']),
              fit: BoxFit.cover,
            ),
          ),
          child: isOptimistic
              ? Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10),
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
          category['category'],
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isOptimistic ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: isOptimistic
            ? const Text(
          'Saving...',
          style: TextStyle(color: Colors.orange, fontSize: 12),
        )
            : null,
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
              onPressed: () => _startEdit(category),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteCategory(
                category['id'],
                category['category'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startEdit(Map<String, dynamic> category) {
    setState(() {
      _editingId = category['id'];
      _editCategoryController.text = category['category'];
      _selectedIconPath = category['icon'];
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _editCategoryController.clear();
      _selectedIconPath = null;
    });
  }

  Future<void> _updateCategory() async {
    if (_editingId == null || _editCategoryController.text.isEmpty) {
      _showError('Please enter category name');
      return;
    }

    setState(() => _uploading = true);

    try {
      final updatedData = {
        "category": _editCategoryController.text.trim(),
        "icon": _selectedIconPath,
      };

      setState(() {
        final index = _categories.indexWhere((item) => item['id'] == _editingId);
        _categories[index] = {
          ..._categories[index],
          'category': _editCategoryController.text.trim(),
          'icon': _selectedIconPath,
        };
      });

      await FirebaseFirestore.instance
          .collection("categoryIcons")
          .doc(_editingId)
          .update(updatedData);

      _cancelEdit();
      _showSuccess('Category updated successfully! ✅');
    } catch (e) {
      print('❌ Error updating category: $e');
      _loadCategories(); // Rollback
      _showError('Failed to update category: $e');
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _deleteCategory(String id, String categoryName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$categoryName"?'),
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

    final deletedItem = _categories.firstWhere((item) => item['id'] == id);
    setState(() => _categories.removeWhere((item) => item['id'] == id));

    try {
      await FirebaseFirestore.instance
          .collection("categoryIcons")
          .doc(id)
          .delete();

      _showSuccess('Category deleted successfully 🗑️');
    } catch (e) {
      setState(() => _categories.add(deletedItem));
      _showError('Failed to delete category: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Category Icons",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
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
                    shadowColor: Colors.blue.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editingId != null ? '✏️ Edit Category' : '➕ Add New Category',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _editingId != null
                                ? _editCategoryController
                                : _categoryController,
                            decoration: const InputDecoration(
                              labelText: "Category Name",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildIconSelection(),
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
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _updateCategory,
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
                                      onPressed: _addCategory,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade700,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      child: const Text(
                                        'Save Category',
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
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Text(
                        '📁 Your Categories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${_categories.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: _loadCategories,
                        tooltip: 'Refresh List',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  _categories.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No categories yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Text(
                          'Add your first category above!',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      return _buildCategoryItem(_categories[index]);
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