import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminProductPage extends StatefulWidget {
  const AdminProductPage({super.key});

  @override
  State<AdminProductPage> createState() => _AdminProductPageState();
}

class _AdminProductPageState extends State<AdminProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();

  String? _selectedCategory;
  List<String> _selectedImages = [];
  bool _uploading = false;
  String? _editingId;

  DateTime? _saleStartDate;
  DateTime? _saleEndDate;

  bool _isTrending = false;
  bool _isNew = true;
  bool _isMustHave = false;
  bool _isBestSeller = false;

  final List<String> _categories = [
    'Moisturizer', 'Cleanser', 'Sunscreen', 'Serum',
    'Lip Care', 'Toner', 'Face Mask'
  ];

  final List<String> _brands = [
    'COSRX', 'The Ordinary', 'Beauty of Joseon', 'CeraVe', 'Neutrogena',
    'Cetaphil', 'Paula\'s Choice', 'Kiehl\'s', 'Anessa', 'Embryolisse',
    'I\'m From', 'Innisfree', 'Laneige', 'Anua', 'Other'
  ];

  final productsRef = FirebaseFirestore.instance.collection('products');
  List<Map<String, dynamic>> _products = [];

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  List<Map<String, String>> _getAvailableImages() {
    if (_selectedCategory == null || _brandController.text.isEmpty) {
      return [];
    }

    final category = _selectedCategory!.toLowerCase().replaceAll(' ', '');
    final brand = _brandController.text.toLowerCase().replaceAll(' ', '').replaceAll('\'', '');
    print('🔍 Looking for images: category=$category, brand=$brand');

    final allImages = ProductData.getAllImageOptions();
    final filteredImages = allImages.where((image) {
      final imageCategory = image['category']?.toLowerCase() ?? '';
      final imageBrand = image['brand']?.toLowerCase() ?? '';
      return imageCategory.contains(category) && imageBrand.contains(brand);
    }).toList();

    print('✅ Found ${filteredImages.length} images');

    return filteredImages;
  }

  Future<void> _loadProducts() async {
    try {
      final snapshot = await productsRef.orderBy('createdAt', descending: true).get();

      setState(() {
        _products = snapshot.docs.map((doc) {
          final data = doc.data();
          final images = data['images'];

          List<String> imageList = [];
          if (images is List) {
            imageList = List<String>.from(images.map((e) => e.toString()));
          } else if (images is Map) {
            final Map<String, dynamic> imageMap = Map<String, dynamic>.from(images);
            imageList = imageMap.values.map((e) => e.toString()).toList();
          }

          return {
            'id': doc.id,
            'name': data['name'] ?? '',
            'price': (data['price'] ?? 0).toDouble(),
            'salePrice': (data['salePrice'] ?? 0).toDouble(),
            'description': data['description'] ?? '',
            'ingredients': data['ingredients'] ?? '',
            'category': data['category'] ?? '',
            'brand': data['brand'] ?? 'Other',
            'images': imageList,
            'active': data['active'] ?? true,
            'isTrending': data['isTrending'] ?? false,
            'isNew': data['isNew'] ?? true,
            'isMustHave': data['isMustHave'] ?? false,
            'isBestSeller': data['isBestSeller'] ?? false,
            'saleStart': data['saleStart'],
            'saleEnd': data['saleEnd'],
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        }).toList();
      });
    } catch (e) {
      _showError('Failed to load: $e');
      print('Error loading products: $e');
    }
  }

  Future<void> _pickSaleStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _saleStartDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _saleStartDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickSaleEndDate() async {
    final initialDate = _saleStartDate != null
        ? _saleStartDate!.add(const Duration(days: 7))
        : DateTime.now().add(const Duration(days: 7));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _saleEndDate ?? initialDate,
      firstDate: _saleStartDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _saleEndDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      _showError('Select at least 1 image');
      return;
    }

    setState(() => _uploading = true);

    try {
      final price = double.tryParse(_priceController.text.replaceAll('.', '')) ?? 0;
      final salePrice = _salePriceController.text.isNotEmpty
          ? double.tryParse(_salePriceController.text.replaceAll('.', '')) ?? 0
          : 0;

      if (price <= 0) {
        _showError('Price must be greater than 0');
        setState(() => _uploading = false);
        return;
      }

      if (salePrice > 0 && salePrice >= price) {
        _showError('Sale price must be less than regular price');
        setState(() => _uploading = false);
        return;
      }

      final productData = {
        "name": _nameController.text.trim(),
        "price": price,
        "salePrice": salePrice,
        "description": _descriptionController.text.trim(),
        "ingredients": _ingredientsController.text.trim(),
        "category": _selectedCategory ?? "Skincare",
        "brand": _brandController.text.trim().isEmpty ? 'Other' : _brandController.text.trim(),
        "images": _selectedImages,
        "active": true,
        "isTrending": _isTrending,
        "isNew": _isNew,
        "isMustHave": _isMustHave,
        "isBestSeller": _isBestSeller,
        "saleStart": _saleStartDate != null ? Timestamp.fromDate(_saleStartDate!) : null,
        "saleEnd": _saleEndDate != null ? Timestamp.fromDate(_saleEndDate!) : null,
        "createdAt": FieldValue.serverTimestamp(),
      };

      if (_editingId == null) {
        final docRef = await productsRef.add(productData);
        setState(() {
          _products.insert(0, {
            ...productData,
            'id': docRef.id,
            'createdAt': DateTime.now(),
          });
        });
      } else {
        await productsRef.doc(_editingId!).update(productData);
        setState(() {
          final index = _products.indexWhere((item) => item['id'] == _editingId);
          if (index != -1) {
            _products[index] = {..._products[index], ...productData};
          }
        });
      }

      _resetForm();
      _showSuccess(_editingId == null ? 'Product added! 🎉' : 'Product updated! ✅');
    } catch (e) {
      _showError('Failed to save: $e');
      print('Error saving product: $e');
    } finally {
      setState(() => _uploading = false);
    }
  }

  Widget _buildImageSelection() {
    final availableImages = _getAvailableImages();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Product Images (max 3):',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 8),

        if (_selectedCategory == null || _brandController.text.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              '👆 Select category & brand first to see available images',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
            ),
          )
        else if (availableImages.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow.shade200),
                ),
                child: Text(
                  '⚠️ No pre-made images found for "$_selectedCategory" - "${_brandController.text}"',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              _buildManualImageInput(),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '✅ ${availableImages.length} images available',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_selectedImages.length}/3 selected',
                        style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 160,
                  minHeight: 140,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: availableImages.map((image) => _buildImageOption(image)).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Selected Images:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          LimitedBox(
            maxHeight: 140,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _selectedImages.map((imagePath) {
                  return Container(
                    width: 90,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade600, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('❌ Error loading image: $imagePath');
                                print('Error details: $error');
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, size: 24, color: Colors.grey.shade500),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Image not found',
                                        style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                                      ),
                                      Text(
                                        'Path: ${imagePath.split('/').last}',
                                        style: TextStyle(fontSize: 8, color: Colors.red),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 80,
                          child: Text(
                            imagePath.split('/').last,
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => setState(() => _selectedImages.remove(imagePath)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.remove, size: 12, color: Colors.red),
                                SizedBox(width: 4),
                                Text(
                                  'Remove',
                                  style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageOption(Map<String, String> image) {
    final isSelected = _selectedImages.contains(image['path']!);
    final isDisabled = _selectedImages.length >= 3 && !isSelected;

    return GestureDetector(
      onTap: isDisabled ? null : () {
        setState(() {
          if (isSelected) {
            _selectedImages.remove(image['path']!);
          } else if (_selectedImages.length < 3) {
            _selectedImages.add(image['path']!);
          }
        });
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? Colors.blue.shade600 :
                  isDisabled ? Colors.grey.shade300 : Colors.grey.shade400,
                  width: isSelected ? 3 : 1,
                ),
                color: isSelected ? Colors.blue.shade50 :
                isDisabled ? Colors.grey.shade100 : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  image['path']!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ Error loading image option: ${image['path']}');
                    return Container(
                      color: Colors.grey.shade200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 24, color: Colors.grey.shade400),
                          const SizedBox(height: 4),
                          Text(
                            'Not found',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                image['name'] ?? 'Image',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.blue.shade800 : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 10, color: Colors.green),
                    SizedBox(width: 2),
                    Text(
                      'Selected',
                      style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManualImageInput() {
    String manualPath = '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Enter image path manually:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                onChanged: (value) => manualPath = value,
                decoration: InputDecoration(
                  hintText: 'assets/product/category/brand/image.jpg',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                  prefixIcon: const Icon(Icons.photo, size: 20),
                  suffixIcon: manualPath.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {},
                  )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (manualPath.isEmpty) {
                  _showError('Please enter an image path');
                  return;
                }

                if (!manualPath.startsWith('assets/')) {
                  _showError('Image path must start with "assets/"');
                  return;
                }

                if (_selectedImages.length >= 3) {
                  _showError('Maximum 3 images allowed');
                  return;
                }

                if (_selectedImages.contains(manualPath)) {
                  _showError('This image is already selected');
                  return;
                }

                try {
                  precacheImage(AssetImage(manualPath), context).then((_) {
                    setState(() => _selectedImages.add(manualPath));
                    _showSuccess('Image added successfully!');
                  }).catchError((error) {
                    _showError('Image not found at: $manualPath');
                    print('Error loading image: $error');
                  });
                } catch (e) {
                  _showError('Invalid image path: $manualPath');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text(
                'Add Image',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '💡 Common image paths:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 4),
              Text(
                '• assets/product/moisturizer/cosrx/front.jpg',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                '• assets/product/cleanser/cosrx/side.jpg',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                '• assets/product/sunscreen/annesa/back.jpg',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrandSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Brand:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _brandController.text.isEmpty ? null : _brandController.text,
          items: _brands.map((brand) {
            return DropdownMenuItem(
              value: brand,
              child: Text(brand),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _brandController.text = value ?? 'Other';
              _selectedImages.clear();
            });
          },
          decoration: const InputDecoration(
            hintText: 'Select Brand',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.branding_watermark),
          ),
          validator: (value) => value == null || value.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Category:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          items: _categories.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
              _selectedImages.clear();
            });
          },
          decoration: const InputDecoration(
            labelText: "Select Category",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          validator: (value) => value == null ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildProductFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Product Features:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildFeatureChip('🔥 Trending', _isTrending, (value) {
              setState(() => _isTrending = value);
            }),
            _buildFeatureChip('🆕 New', _isNew, (value) {
              setState(() => _isNew = value);
            }),
            _buildFeatureChip('⭐ Must Have', _isMustHave, (value) {
              setState(() => _isMustHave = value);
            }),
            _buildFeatureChip('🏆 Best Seller', _isBestSeller, (value) {
              setState(() => _isBestSeller = value);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureChip(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green,
      labelStyle: TextStyle(
        color: value ? Colors.green.shade800 : Colors.grey.shade700,
        fontWeight: value ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildFlashSaleSection() {
    final salePriceText = _salePriceController.text;
    final salePrice = double.tryParse(salePriceText.replaceAll('.', '')) ?? 0;
    final hasSalePrice = salePriceText.isNotEmpty && salePrice > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Flash Sale Settings:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),

        if (hasSalePrice) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Sale Start Date:'),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      onPressed: _pickSaleStartDate,
                      child: Text(
                        _saleStartDate != null
                            ? '${_saleStartDate!.day}/${_saleStartDate!.month}/${_saleStartDate!.year}'
                            : 'Select Start Date',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Sale End Date:'),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      onPressed: _pickSaleEndDate,
                      child: Text(
                        _saleEndDate != null
                            ? '${_saleEndDate!.day}/${_saleEndDate!.month}/${_saleEndDate!.year}'
                            : 'Select End Date',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_saleStartDate != null && _saleEndDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Sale Period: ${_saleStartDate!.day}/${_saleStartDate!.month}/${_saleStartDate!.year} - ${_saleEndDate!.day}/${_saleEndDate!.month}/${_saleEndDate!.year}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_saleEndDate!.isBefore(_saleStartDate!)) ...[
              const SizedBox(height: 4),
              Text(
                '⚠️ End date must be after start date',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ],
        ] else
          Text(
            salePriceText.isEmpty
                ? 'Enter a sale price to enable flash sale dates'
                : 'Sale price must be greater than 0',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    final images = List<String>.from(product['images'] ?? []);
    final mainImage = images.isNotEmpty ? images[0] : 'assets/default_product.jpg';
    final brand = product['brand'] ?? 'Other';
    final price = (product['price'] ?? 0).toDouble();
    final salePrice = (product['salePrice'] ?? 0).toDouble();
    final isOnSale = salePrice > 0 && salePrice < price;

    bool isActiveSale = false;
    if (isOnSale && product['saleStart'] != null && product['saleEnd'] != null) {
      final now = DateTime.now();
      final saleStart = (product['saleStart'] as Timestamp).toDate();
      final saleEnd = (product['saleEnd'] as Timestamp).toDate();
      isActiveSale = now.isAfter(saleStart) && now.isBefore(saleEnd);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              mainImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('❌ Error loading product image: $mainImage');
                print('Error: $error');
                return Container(
                  color: Colors.grey.shade200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag, color: Colors.grey.shade400),
                      Text(
                        'Image\nnot found',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        title: Text(
          product['name'],
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  _currencyFormat.format(price),
                  style: TextStyle(
                    fontSize: 14,
                    color: isOnSale ? Colors.grey.shade600 : Colors.green.shade700,
                    decoration: isOnSale ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (isOnSale) ...[
                  const SizedBox(width: 4),
                  Text(
                    _currencyFormat.format(salePrice),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$brand • ${product['category']}',
              style: const TextStyle(fontSize: 12),
            ),
            if (product['isTrending'] == true || product['isBestSeller'] == true || product['isMustHave'] == true) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: [
                  if (product['isTrending'] == true)
                    _buildFeatureTag('🔥 Trending', Colors.orange),
                  if (product['isBestSeller'] == true)
                    _buildFeatureTag('🏆 Best Seller', Colors.blue),
                  if (product['isMustHave'] == true)
                    _buildFeatureTag('⭐ Must Have', Colors.purple),
                  if (product['isNew'] == true)
                    _buildFeatureTag('🆕 New', Colors.green),
                  if (isActiveSale)
                    _buildFeatureTag('💰 Sale', Colors.red),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.green, size: 20),
              onPressed: () => _showProductDetail(product),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue.shade600, size: 20),
              onPressed: () => _startEdit(product),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteProduct(
                product['id'],
                product['name'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showProductDetail(Map<String, dynamic> product) {
    final images = List<String>.from(product['images'] ?? []);
    final price = (product['price'] ?? 0).toDouble();
    final salePrice = (product['salePrice'] ?? 0).toDouble();
    final isOnSale = salePrice > 0 && salePrice < price;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['name']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (images.isNotEmpty)
                SizedBox(
                  height: 250,
                  child: PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade100,
                        ),
                        child: Image.asset(
                          images[index],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ Error loading detail image: ${images[index]}');
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 50, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Image not found',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Path: ${images[index].split('/').last}',
                                    style: TextStyle(color: Colors.red, fontSize: 10),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No images available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              Text(
                'Brand: ${product['brand'] ?? 'Other'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Text(
                    _currencyFormat.format(price),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isOnSale ? Colors.grey.shade600 : Colors.green,
                      decoration: isOnSale ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (isOnSale) ...[
                    const SizedBox(width: 12),
                    Text(
                      _currencyFormat.format(salePrice),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              Text('Category: ${product['category']}'),
              const SizedBox(height: 12),

              if (product['isTrending'] == true || product['isBestSeller'] == true ||
                  product['isMustHave'] == true || product['isNew'] == true) ...[
                const Text(
                  'Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    if (product['isTrending'] == true)
                      _buildFeatureTag('🔥 Trending', Colors.orange),
                    if (product['isBestSeller'] == true)
                      _buildFeatureTag('🏆 Best Seller', Colors.blue),
                    if (product['isMustHave'] == true)
                      _buildFeatureTag('⭐ Must Have', Colors.purple),
                    if (product['isNew'] == true)
                      _buildFeatureTag('🆕 New', Colors.green),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(product['description']),
              const SizedBox(height: 12),

              const Text(
                'Ingredients:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(product['ingredients']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _startEdit(Map<String, dynamic> product) {
    setState(() {
      _editingId = product['id'];
      _nameController.text = product['name'];
      _priceController.text = (product['price'] ?? 0).toString();
      _salePriceController.text = (product['salePrice'] ?? 0).toString();
      _descriptionController.text = product['description'];
      _ingredientsController.text = product['ingredients'];
      _selectedCategory = product['category'];
      _brandController.text = product['brand'] ?? 'Other';
      _selectedImages = List<String>.from(product['images'] ?? []);
      _isTrending = product['isTrending'] ?? false;
      _isNew = product['isNew'] ?? true;
      _isMustHave = product['isMustHave'] ?? false;
      _isBestSeller = product['isBestSeller'] ?? false;

      if (product['saleStart'] != null) {
        _saleStartDate = (product['saleStart'] as Timestamp).toDate();
      }
      if (product['saleEnd'] != null) {
        _saleEndDate = (product['saleEnd'] as Timestamp).toDate();
      }
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _resetForm();
    });
  }

  void _resetForm() {
    _nameController.clear();
    _priceController.clear();
    _salePriceController.clear();
    _descriptionController.clear();
    _ingredientsController.clear();
    _brandController.clear();
    _selectedCategory = null;
    _selectedImages = [];
    _isTrending = false;
    _isNew = true;
    _isMustHave = false;
    _isBestSeller = false;
    _saleStartDate = null;
    _saleEndDate = null;
  }

  Future<void> _deleteProduct(String id, String productName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$productName"?'),
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

    final deletedItem = _products.firstWhere((item) => item['id'] == id);
    setState(() => _products.removeWhere((item) => item['id'] == id));

    try {
      await productsRef.doc(id).delete();
      _showSuccess('Product deleted successfully 🗑️');
    } catch (e) {
      setState(() => _products.add(deletedItem));
      _showError('Failed to delete product: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Product Management",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _editingId != null ? '✏️ Edit Product' : '➕ Add New Product',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: "Product Name",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.shopping_bag),
                            ),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 12),

                          _buildBrandSelection(),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: "Price",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return "Required";
                              }
                              final price = double.tryParse(v.replaceAll('.', '')) ?? 0;
                              if (price <= 0) {
                                return "Price must be greater than 0";
                              }
                              return null;
                            },
                            onChanged: (value) {
                              final cleanValue = value.replaceAll('.', '');
                              if (cleanValue.isNotEmpty) {
                                final number = int.tryParse(cleanValue) ?? 0;
                                if (number > 0) {
                                  final formatted = _currencyFormat.format(number);
                                  _priceController.value = TextEditingValue(
                                    text: formatted.replaceAll('Rp ', ''),
                                    selection: TextSelection.collapsed(offset: formatted.length - 3),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _salePriceController,
                            decoration: const InputDecoration(
                              labelText: "Sale Price (optional)",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.local_offer),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final cleanValue = value.replaceAll('.', '');
                              if (cleanValue.isNotEmpty) {
                                final number = int.tryParse(cleanValue) ?? 0;
                                if (number > 0) {
                                  final formatted = _currencyFormat.format(number);
                                  _salePriceController.value = TextEditingValue(
                                    text: formatted.replaceAll('Rp ', ''),
                                    selection: TextSelection.collapsed(offset: formatted.length - 3),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          _buildCategorySelection(),
                          const SizedBox(height: 12),

                          _buildProductFeatures(),
                          const SizedBox(height: 12),

                          _buildFlashSaleSection(),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: "Description",
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _ingredientsController,
                            decoration: const InputDecoration(
                              labelText: "Ingredients",
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildImageSelection(),
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
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveProduct,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                ),
                                child: const Text(
                                  'Update',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ] else
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveProduct,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                ),
                                child: const Text(
                                  'Save Product',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
                  '📦 Your Products',
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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_products.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _loadProducts,
                  tooltip: 'Refresh List',
                ),
              ],
            ),
            const SizedBox(height: 8),

            _products.isEmpty
                ? Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No products yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      'Add your first product above!',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _products.length,
              itemBuilder: (context, index) => _buildProductItem(_products[index]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _brandController.dispose();
    super.dispose();
  }
}

class ProductData {
  static List<Map<String, String>> getAllImageOptions() {
    return [
      // === MOISTURIZER ===
      {'name': 'Rice Cream Front', 'path': 'assets/moisturizer/imfrom.png', 'category': 'moisturizer', 'brand': 'imfrom'},
      {'name': 'Lait Creme Front', 'path': 'assets/moisturizer/embry.png', 'category': 'moisturizer', 'brand': 'embryolisse'},

      // === CLEANSER ===
      {'name': 'COSRX Cleanser Front', 'path': 'assets/cleanser/front.png', 'category': 'cleanser', 'brand': 'cosrx'},
      {'name': 'COSRX Cleanser Side', 'path': 'assets/cleanser/side.png', 'category': 'cleanser', 'brand': 'cosrx'},
      {'name': 'Innisfree Cleanser 1', 'path': 'assets/cleanser/1.png', 'category': 'cleanser', 'brand': 'innisfree'},
      {'name': 'Innisfree Cleanser 2', 'path': 'assets/cleanser/2.png', 'category': 'cleanser', 'brand': 'innisfree'},

      // === SUNSCREEN ===
      {'name': 'Anessa Sunscreen Front', 'path': 'assets/sunscreen/frontas.jpg', 'category': 'sunscreen', 'brand': 'anessa'},
      {'name': 'Rice Sunscreen', 'path': 'assets/sunscreen/from1.png', 'category': 'sunscreen', 'brand': 'imfrom'},
      {'name': 'BOJ Sunscreen', 'path': 'assets/sunscreen/boj.png', 'category': 'sunscreen', 'brand': 'boj'},
      {'name': 'BOJ Sunscreen Side', 'path': 'assets/sunscreen/boj2.png', 'category': 'sunscreen', 'brand': 'boj'},

      // === Lip Care ===
      {'name': 'Lane Lip', 'path': 'assets/moisturizer/lane.png', 'category': 'lip care', 'brand': 'lane'},

      // === Serum ===
      {'name': 'Anua', 'path': 'assets/moisturizer/anua.png', 'category': 'serun', 'brand': 'anua'},
    ];
  }

  static List<Map<String, dynamic>> getAllProducts() {
    return [
      // === MOISTURIZER ===
      {
        'name': 'Rice Cream',
        'category': 'Moisturizer',
        'brand': 'I\'m From',
        'images': [
          'assets/moisturizer/imfrom.png',
        ]
      },
      {
        'name': 'Lait Creme Concentre',
        'category': 'Moisturizer',
        'brand': 'Embryolisse',
        'images': [
          'assets/moisturizer/embry.png',
        ]
      },

      // === Lip Care ===
      {
        'name': 'Lip Sleeping Mask EX Berry',
        'category': 'Lip Care',
        'brand': 'Laneige',
        'images': [
          'assets/moisturizer/lane.png',
        ]
      },

      // === Serum ===
      {
        'name': 'Niacinamide 10% + TXA 3% Serum',
        'category': 'Serum',
        'brand': 'Anua',
        'images': [
          'assets/moisturizer/anua.png',
        ]
      },
      // === CLEANSER ===
      {
        'name': 'COSRX Low pH Cleanser',
        'category': 'Cleanser',
        'brand': 'COSRX',
        'images': [
          'assets/cleanser/front.png',
          'assets/cleanser/side.png'
        ]
      },
      {
        'name': 'Green Tea Hydrating Amino Acid Cleansing Foam',
        'category': 'Cleanser',
        'brand': 'Innisfree',
        'images': [
          'assets/cleanser/1.png',
          'assets/cleanser/2.png'
        ]
      },

      // === SUNSCREEN ===
      {
        'name': 'New Perfect Uv Sunscreen Skincare Milk',
        'category': 'Sunscreen',
        'brand': 'Anessa',
        'images': [
          'assets/sunscreen/frontas.jpg',
        ]
      },

      {
        'name': 'Rice Sunscreen',
        'category': 'Sunscreen',
        'brand': 'I\'m From',
        'images': [
          'assets/sunscreen/from1.png',
        ]
      },

      {
        'name': 'Sunscreen : Rice + Probiotics',
        'category': 'Sunscreen',
        'brand': 'Beauty of Joseon',
        'images': [
          'assets/sunscreen/boj.png',
          'assets/sunscreen/boj2.png',
        ]
      },
    ];
  }
}