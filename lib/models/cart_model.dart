class CartItem {
  final int id; // Database ID
  final String gameId; // Game ID from API
  final String title;
  final double price;
  final int quantity;
  final String imageUrl;
  final String type;
  final String platform;

  CartItem({
    required this.id,
    required this.gameId,
    required this.title,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.type,
    required this.platform,
  });

  // Create a copy with updated fields
  CartItem copyWith({
    int? id,
    String? gameId,
    String? title,
    double? price,
    int? quantity,
    String? imageUrl,
    String? type,
    String? platform,
  }) {
    return CartItem(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      title: title ?? this.title,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      platform: platform ?? this.platform,
    );
  }

  // Convert to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameId': gameId,
      'product_id': gameId, // Added for DB compatibility
      'title': title,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'type': type,
      'platform': platform,
    };
  }

  // Convert to Map for checkout process
  Map<String, dynamic> toCheckoutMap() {
    return {
      'id': id,
      'gameId': gameId,
      'title': title,
      'price': price,
      'quantity': quantity,
      'type': type,
      'platform': platform,
      'subtotal': price * quantity,
    };
  }

  // Add this operator to make the CartItem compatible with code that uses Map-like access
  dynamic operator [](String key) {
    switch (key) {
      case 'id':
        return id;
      case 'gameId':
        return gameId;
      case 'product_id':
        return gameId;
      case 'title':
        return title;
      case 'price':
        return price;
      case 'quantity':
        return quantity;
      case 'imageUrl':
        return imageUrl;
      case 'type':
        return type;
      case 'platform':
        return platform;
      default:
        return null;
    }
  }

  // Add a factory constructor for creating a new cart item without an ID (for adding to cart)
  factory CartItem.forInsert({
    required String gameId,
    required String title,
    required double price,
    required int quantity,
    required String imageUrl,
    required String type,
    required String platform,
  }) {
    return CartItem(
      id: 0, // ID will be assigned by the database
      gameId: gameId,
      title: title,
      price: price,
      quantity: quantity,
      imageUrl: imageUrl,
      type: type,
      platform: platform,
    );
  }

  // Improve the fromMap constructor for better type safety
  static CartItem fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] is int
          ? map['id']
          : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      gameId: (map['product_id'] ?? map['gameId'] ?? '').toString(),
      title: (map['title'] ?? 'Unknown Game').toString(),
      price: map['price'] is num
          ? (map['price'] is int
              ? (map['price'] as int).toDouble()
              : map['price'] as double)
          : double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      quantity: map['quantity'] is int
          ? map['quantity'] as int
          : int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      imageUrl: (map['imageUrl'] ?? '').toString(),
      type: (map['type'] ?? 'digital').toString(),
      platform: (map['platform'] ?? 'Unknown').toString(),
    );
  }

  // Add a method to create a database-compatible map
  Map<String, Object?> toDatabaseMap() {
    return {
      'product_id': gameId,
      'title': title,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'type': type,
      'platform': platform,
    };
  }

  // Add toString method for better debugging
  @override
  String toString() {
    return 'CartItem{id: $id, gameId: $gameId, title: $title, price: $price, quantity: $quantity, type: $type}';
  }
}
