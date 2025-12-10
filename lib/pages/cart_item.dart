class CartItem {
  final String id;
  final String productId;
  final String name;
  final String image;
  final int price;
  final int salePrice;
  int quantity;
  final String brand;
  final String category;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.salePrice,
    required this.quantity,
    required this.brand,
    required this.category,
  });

  static CartItem empty() {
    return CartItem(
      id: '',
      productId: '',
      name: '',
      image: '',
      price: 0,
      salePrice: 0,
      quantity: 0,
      brand: '',
      category: '',
    );
  }

  int get actualPrice => salePrice > 0 ? salePrice : price;
  int get totalPrice => actualPrice * quantity;
  int get savings => salePrice > 0 ? (price - salePrice) * quantity : 0;

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? image,
    int? price,
    int? salePrice,
    int? quantity,
    String? brand,
    String? category,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      quantity: quantity ?? this.quantity,
      brand: brand ?? this.brand,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'image': image,
      'price': price,
      'salePrice': salePrice,
      'quantity': quantity,
      'brand': brand,
      'category': category,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      price: (map['price'] ?? 0).toInt(),
      salePrice: (map['salePrice'] ?? 0).toInt(),
      quantity: (map['quantity'] ?? 1).toInt(),
      brand: map['brand'] ?? '',
      category: map['category'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CartItem &&
              runtimeType == other.runtimeType &&
              productId == other.productId;

  @override
  int get hashCode => productId.hashCode;

  @override
  String toString() {
    return 'CartItem{id: $id, productId: $productId, name: $name, quantity: $quantity, totalPrice: $totalPrice}';
  }
}