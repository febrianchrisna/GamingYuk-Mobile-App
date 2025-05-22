import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:toko_game/models/cart_model.dart';
import 'package:toko_game/utils/database_helper.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  final DatabaseHelper _dbHelper;
  final int _userId = 1;
  bool _initialized = false;

  CartProvider({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper {
    _initializeCart();
  }

  List<CartItem> get items => _items;

  // Convert items to map for backward compatibility
  List<Map<String, dynamic>> get itemsAsMap =>
      _items.map((item) => item.toMap()).toList();

  // Initialize cart with proper database structure
  Future<void> _initializeCart() async {
    print("Initializing cart provider...");
    try {
      // Make sure cart table has proper structure
      await _dbHelper.fixDatabaseStructure();
      await _loadCartItems();
      _initialized = true;
    } catch (e) {
      print("Error initializing cart: $e");
    }
  }

  // Completely rewritten _loadCartItems for better reliability
  Future<void> _loadCartItems() async {
    print("\n===== LOADING CART ITEMS =====");

    try {
      // Get raw items from database
      final rawItems = await _dbHelper.getCartItems(_userId);
      print("Raw items from database: ${rawItems.length}");

      // Clear existing items
      _items = [];

      // Process each item from database
      for (final item in rawItems) {
        try {
          print("Processing item: $item");

          // Extract values with safe type conversions
          final id = item['id'] is int
              ? item['id']
              : int.tryParse(item['id'].toString()) ?? 0;
          final gameId = item['product_id']?.toString() ?? '';
          final title = item['title']?.toString() ?? 'Unknown Game';

          // Convert price carefully
          double price = 0.0;
          if (item['price'] != null) {
            if (item['price'] is double) {
              price = item['price'];
            } else if (item['price'] is int) {
              price = (item['price'] as int).toDouble();
            } else {
              price = double.tryParse(item['price'].toString()) ?? 0.0;
            }
          }

          // Handle quantity
          int quantity = 1;
          if (item['quantity'] != null) {
            if (item['quantity'] is int) {
              quantity = item['quantity'];
            } else {
              quantity = int.tryParse(item['quantity'].toString()) ?? 1;
            }
          }

          final imageUrl = item['imageUrl']?.toString() ?? '';
          final type = item['type']?.toString() ?? 'digital';
          final platform = item['platform']?.toString() ?? 'Unknown';

          // Create CartItem and add to list
          final cartItem = CartItem(
            id: id,
            gameId: gameId,
            title: title,
            price: price,
            quantity: quantity,
            imageUrl: imageUrl,
            type: type,
            platform: platform,
          );

          print("Created CartItem: $cartItem");
          _items.add(cartItem);
        } catch (e) {
          print("Error processing individual item: $e");
        }
      }

      print("Successfully loaded ${_items.length} cart items");
      print("===== END LOADING CART ITEMS =====\n");

      notifyListeners();
    } catch (e) {
      print("ERROR loading cart items: $e");
      print("Stack trace: ${StackTrace.current}");
      _items = [];
      notifyListeners();
    }
  }

  String _selectedCurrency = 'IDR';

  String get selectedCurrency => _selectedCurrency;

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Simplified addItem method for maximum reliability
  Future<void> addItem({
    required String gameId,
    required String title,
    required double price,
    required String imageUrl,
    required String type,
    required String platform,
  }) async {
    print("\n===== ADDING ITEM TO CART =====");
    print("Game ID: $gameId");
    print("Title: $title");
    print("Price: $price");
    print("Type: $type");
    print("Platform: $platform");

    try {
      // First check if the item already exists
      final existingIndex = _items.indexWhere((item) => item.gameId == gameId);

      if (existingIndex >= 0) {
        print("Item already exists, updating quantity");

        // Get existing item
        final existingItem = _items[existingIndex];
        final newQuantity = existingItem.quantity + 1;

        // Update in database
        final updated = await _dbHelper.updateCartItem({
          'id': existingItem.id,
          'quantity': newQuantity,
        });

        print("Database update result: $updated");

        // Update in memory
        if (updated > 0) {
          final updatedItem = existingItem.copyWith(quantity: newQuantity);
          _items[existingIndex] = updatedItem;
          print("Updated item in memory");
        }
      } else {
        print("Adding new item to cart");

        // Create a simple map for database
        final dbItem = {
          'product_id': gameId,
          'user_id': _userId,
          'title': title,
          'price': price,
          'quantity': 1,
          'imageUrl': imageUrl,
          'type': type,
          'platform': platform,
        };

        // Add to database
        final id = await _dbHelper.addToCart(dbItem);
        print("Database insert result ID: $id");

        // Only add to memory if database insert succeeded
        if (id > 0) {
          final newItem = CartItem(
            id: id,
            gameId: gameId,
            title: title,
            price: price,
            quantity: 1,
            imageUrl: imageUrl,
            type: type,
            platform: platform,
          );

          _items.add(newItem);
          print("Added item to memory");
        } else {
          print("Failed to add item to database, not adding to memory");
        }
      }

      // Always notify listeners
      notifyListeners();
      print("===== END ADDING ITEM TO CART =====\n");
    } catch (e) {
      print("ERROR adding item to cart: $e");
      print("Stack trace: ${StackTrace.current}");
    }
  }

  String getCurrencySymbol(String currency) {
    switch (currency) {
      case 'IDR':
        return 'Rp';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return currency;
    }
  }

  // Improve refreshCart to ensure it actually gets the latest data
  Future<void> refreshCart() async {
    print("Refreshing cart from database");
    await _loadCartItems();
    notifyListeners();
  }

  // Method to fully reset and reload the cart
  Future<void> resetAndRefreshCart() async {
    print("\n===== RESETTING AND REFRESHING CART =====");

    try {
      // Make sure database is properly set up
      await _dbHelper.fixDatabaseStructure();

      // Log current database state
      await _dbHelper.logDatabaseState();

      // Reload items from database
      await _loadCartItems();

      print("===== END RESETTING AND REFRESHING CART =====\n");
    } catch (e) {
      print("ERROR resetting and refreshing cart: $e");
      print("Stack trace: ${StackTrace.current}");
    }
  }

  // Add the missing removeItem method used in cart_screen.dart
  void removeItem(String gameId) async {
    print("\n===== REMOVING ITEM FROM CART =====");
    print("Game ID to remove: $gameId");

    try {
      // Find the item index in memory
      final itemIndex = _items.indexWhere((item) => item.gameId == gameId);

      if (itemIndex >= 0) {
        // Get item details for database removal
        final item = _items[itemIndex];
        final itemId = item.id;

        print("Found item to remove at index $itemIndex with ID $itemId");

        // Remove from memory
        _items.removeAt(itemIndex);
        print("Removed item from memory");

        // Then remove from database
        if (itemId > 0) {
          final result = await _dbHelper.removeFromCart(itemId);
          print("Database removal result: $result");
        }

        // Notify listeners
        notifyListeners();
        print("Notified listeners about item removal");
      } else {
        print("Item with gameId $gameId not found in cart");
      }

      print("===== END REMOVING ITEM FROM CART =====\n");
    } catch (e) {
      print("ERROR removing item from cart: $e");
      print("Stack trace: ${StackTrace.current}");
    }
  }

  // Add methods required by checkout_screen.dart

  // Check if cart has digital items
  bool hasDigitalItems() {
    return _items.any((item) => item.type.toLowerCase() == 'digital');
  }

  // Check if cart has physical items
  bool hasPhysicalItems() {
    return _items.any((item) =>
        item.type.toLowerCase() == 'physical' ||
        item.type.toLowerCase() == 'fisik');
  }

  // Convert cart items to checkout format
  List<Map<String, dynamic>> getItemsForCheckout() {
    return _items.map((item) {
      return {
        'id': item.id,
        'gameId': item.gameId,
        'title': item.title,
        'price': item.price,
        'quantity': item.quantity,
        'type': item.type,
        'platform': item.platform,
        'subtotal': item.price * item.quantity,
      };
    }).toList();
  }

  // Clear the entire cart
  void clear() async {
    print("Clearing cart");
    _items = [];

    // Clear all items from database
    try {
      await _dbHelper.clearCart(_userId);
      print("Cart cleared from database");
    } catch (e) {
      print("Error clearing cart from database: $e");
    }

    notifyListeners();
  }

  Future<void> decreaseQuantity(String gameId) async {
    try {
      final index = _items.indexWhere((item) => item.gameId == gameId);
      if (index >= 0) {
        // If item exists, decrease quantity
        if (_items[index].quantity > 1) {
          // Create updated item with decreased quantity
          final updatedItem = CartItem(
            id: _items[index].id, // Include the id parameter
            gameId: _items[index].gameId,
            title: _items[index].title,
            price: _items[index].price,
            imageUrl: _items[index].imageUrl,
            quantity: _items[index].quantity - 1,
            type: _items[index].type,
            platform: _items[index].platform,
          );

          // Update in database with a Map
          await _dbHelper.updateCartItem({
            'id': updatedItem.id,
            'quantity': updatedItem.quantity,
          });

          // Update the item in memory
          _items[index] = updatedItem;
        } else {
          // If quantity becomes 0, remove the item
          final itemId = _items[index].id;
          await _dbHelper.removeFromCart(
              itemId); // Use removeFromCart instead of deleteCartItem
          _items.removeAt(index);
        }
        notifyListeners();
      }
    } catch (e) {
      print("Error decreasing quantity: $e");
    }
  }
}
