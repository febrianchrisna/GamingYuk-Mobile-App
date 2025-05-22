import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'toko_game.db');
      final db = await openDatabase(
        path,
        version: 2, // Increment version to trigger onUpgrade
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
      );
      // Fix settings types
      await _fixSettingsTypes(db);

      final settings = await db.query('settings');
      if (settings.isNotEmpty) {
        final s = settings.first;
        if (s['theme_mode'] is! String ||
            s['language'] is! String ||
            s['notifications'] is! int) {
          await db.delete('settings');
          await db.insert('settings',
              {'theme_mode': 'system', 'language': 'en', 'notifications': 1});
        }
      }
      return db;
    } catch (e) {
      print('Critical database error: $e');
      final db = await openDatabase(
        ':memory:',
        version: 1,
        onCreate: _createTables,
      );
      await _fixSettingsTypes(db);
      return db;
    }
  }

  // Method to handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from $oldVersion to $newVersion");

    if (oldVersion < 2) {
      // Drop and recreate the cart table with proper structure
      await _recreateCartTable(db);
    }
  }

  // Method to recreate the cart table with correct structure
  Future<void> _recreateCartTable(Database db) async {
    print("Recreating cart table with proper structure");
    try {
      // Check if cart table exists
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='cart'");
      if (tables.isNotEmpty) {
        // Drop the table if it exists
        await db.execute('DROP TABLE IF EXISTS cart');
        print("Dropped existing cart table");
      }

      // Create the cart table with all required columns
      await db.execute('''
        CREATE TABLE cart (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id TEXT NOT NULL,
          user_id INTEGER NOT NULL DEFAULT 1,
          title TEXT,
          price REAL DEFAULT 0,
          quantity INTEGER DEFAULT 1,
          imageUrl TEXT,
          type TEXT DEFAULT 'digital',
          platform TEXT,
          added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      print("Created new cart table with all required columns");
    } catch (e) {
      print("Error recreating cart table: $e");
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        email TEXT UNIQUE,
        password TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        theme_mode TEXT,
        language TEXT,
        notifications INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id TEXT NOT NULL,
        user_id INTEGER NOT NULL DEFAULT 1,
        title TEXT,
        price REAL DEFAULT 0,
        quantity INTEGER DEFAULT 1,
        imageUrl TEXT, 
        type TEXT DEFAULT 'digital',
        platform TEXT,
        added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Insert default settings if not exists
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM settings'));
    if (count == 0) {
      await db.insert('settings',
          {'theme_mode': 'system', 'language': 'en', 'notifications': 1});
    }
  }

  /// Pastikan semua kolom settings bertipe benar (khususnya theme_mode harus String)
  Future<void> _fixSettingsTypes(Database db) async {
    try {
      final settingsList = await db.query('settings');
      if (settingsList.isEmpty) {
        await db.insert('settings',
            {'theme_mode': 'system', 'language': 'en', 'notifications': 1});
        return;
      }
      final setting = settingsList.first;
      final updates = <String, dynamic>{};

      // theme_mode harus String
      if (setting['theme_mode'] is! String) {
        if (setting['theme_mode'] is int) {
          int themeInt = setting['theme_mode'] as int;
          updates['theme_mode'] =
              themeInt == 0 ? 'system' : (themeInt == 1 ? 'light' : 'dark');
        } else {
          updates['theme_mode'] = 'system';
        }
      }

      // language harus String
      if (setting['language'] is! String) {
        updates['language'] = setting['language'].toString();
      }

      // notifications harus int
      if (setting['notifications'] is! int) {
        updates['notifications'] =
            int.tryParse(setting['notifications'].toString()) ?? 1;
      }

      if (updates.isNotEmpty) {
        await db.update(
          'settings',
          updates,
          where: 'id = ?',
          whereArgs: [setting['id']],
        );
      }
    } catch (e) {
      print('Error fixing settings types: $e');
    }
  }

  // Settings methods
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('settings');
      if (maps.isEmpty) {
        final Map<String, dynamic> defaultSettings = {
          'theme_mode': 'system',
          'language': 'en',
          'notifications': 1
        };
        await db.insert('settings', defaultSettings);
        return defaultSettings;
      }
      // Konversi tipe data secara eksplisit
      return {
        'theme_mode': maps.first['theme_mode']?.toString() ?? 'system',
        'language': maps.first['language']?.toString() ?? 'en',
        'notifications': maps.first['notifications'] is int
            ? maps.first['notifications']
            : int.tryParse(maps.first['notifications'].toString()) ?? 1
      };
    } catch (e) {
      print('Error getting settings (returning defaults): $e');
      return {'theme_mode': 'system', 'language': 'en', 'notifications': 1};
    }
  }

  Future<int> updateSettings(Map<String, dynamic> settings) async {
    final db = await database;
    return await db.update(
      'settings',
      settings,
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // Key issue: Change the signature to accept Map<String, Object?> which is what sqflite expects
  Future<int> addToCart(Map<dynamic, dynamic> item) async {
    print("\n===== ADDING TO CART DATABASE =====");
    print("Item to add: $item");

    try {
      final db = await database;

      // Create a very simple, flat map with clean values
      final cleanItem = {
        'product_id': item['product_id'] ?? item['gameId'] ?? '',
        'user_id': 1, // Always use user_id 1 for simplicity
        'title': item['title'] ?? 'Unknown Game',
        'price': item['price'] is num ? item['price'] : 0.0,
        'quantity': item['quantity'] is int ? item['quantity'] : 1,
        'imageUrl': item['imageUrl'] ?? '',
        'type': item['type'] ?? 'digital',
        'platform': item['platform'] ?? 'Unknown',
      };

      print("Cleaned item: $cleanItem");

      // Direct raw insert for maximum compatibility
      int id = await db.rawInsert(
          'INSERT INTO cart (product_id, user_id, title, price, quantity, imageUrl, type, platform) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            cleanItem['product_id'],
            cleanItem['user_id'],
            cleanItem['title'],
            cleanItem['price'],
            cleanItem['quantity'],
            cleanItem['imageUrl'],
            cleanItem['type'],
            cleanItem['platform'],
          ]);

      print("Item inserted with ID: $id");

      // Double-check the insertion worked by querying
      if (id > 0) {
        final items = await db.query('cart', where: 'id = ?', whereArgs: [id]);
        print("Verification query result: $items");
      }

      print("===== END ADDING TO CART DATABASE =====\n");
      return id;
    } catch (e) {
      print("ERROR in addToCart: $e");
      print("Stack trace: ${StackTrace.current}");

      // Try one last approach with simplified values
      try {
        final db = await database;
        final id = await db.rawInsert(
            'INSERT INTO cart (product_id, user_id, title, price) VALUES (?, ?, ?, ?)',
            [
              item['product_id'] ?? item['gameId'] ?? 'unknown',
              1,
              item['title'] ?? 'Unknown Game',
              item['price'] is num ? item['price'] : 0.0,
            ]);
        print("Simplified insert ID: $id");
        return id;
      } catch (e2) {
        print("Even simplified insert failed: $e2");
        return -1;
      }
    }
  }

  // Completely recreate the cart table to ensure it has all needed columns
  Future<void> fixDatabaseStructure() async {
    print("\n===== FIXING DATABASE STRUCTURE =====");

    try {
      final db = await database;

      // Try to create the cart table if it doesn't exist (simpler approach)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cart (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id TEXT NOT NULL,
          user_id INTEGER NOT NULL DEFAULT 1,
          title TEXT,
          price REAL DEFAULT 0,
          quantity INTEGER DEFAULT 1,
          imageUrl TEXT,
          type TEXT DEFAULT 'digital',
          platform TEXT,
          added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      print("Created/verified cart table");
      print("===== END FIXING DATABASE STRUCTURE =====\n");
    } catch (e) {
      print("ERROR fixing database structure: $e");
      print("Stack trace: ${StackTrace.current}");
    }
  }

  // Cart methods with improved debugging
  Future<List<Map<String, dynamic>>> getCartItems(int userId) async {
    print("\n===== GETTING CART ITEMS =====");
    print("User ID: $userId");

    try {
      final db = await database;

      // First make sure the cart table exists
      final tableExists = await _tableExists(db, 'cart');
      if (!tableExists) {
        print("Cart table doesn't exist, creating it");
        await fixDatabaseStructure();
      }

      // Get all items with simple query
      final items = await db.query(
        'cart',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      print("Raw items from DB (${items.length}): $items");
      print("===== END GETTING CART ITEMS =====\n");

      return items;
    } catch (e) {
      print("ERROR getting cart items: $e");
      print("Stack trace: ${StackTrace.current}");
      return [];
    }
  }

  Future<int> updateCartItem(Map<String, dynamic> item) async {
    try {
      print("Updating cart item: ${item['id']}");
      final db = await database;

      // Convert to Map<String, Object?> for database operations
      final Map<String, Object?> dbItem = {};
      item.forEach((key, value) {
        if (value != null) {
          dbItem[key] = value;
        }
      });

      return await db.update(
        'cart',
        dbItem,
        where: 'id = ?',
        whereArgs: [item['id']],
      );
    } catch (e) {
      print('Error updating cart item: $e');
      return 0;
    }
  }

  Future<int> removeFromCart(int id) async {
    try {
      print("Removing cart item with ID: $id");
      final db = await database;
      return await db.delete(
        'cart',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error removing from cart: $e');
      return 0;
    }
  }

  Future<int> clearCart(int userId) async {
    try {
      print("Clearing cart for user: $userId");
      final db = await database;
      return await db.delete(
        'cart',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      print('Error clearing cart: $e');
      return 0;
    }
  }

  Future<void> logDatabaseState() async {
    try {
      print("\n=== DATABASE STATE LOG ===");

      final db = await database;

      // Check tables
      final tables = await db
          .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      print("Tables in database: ${tables.map((t) => t['name']).join(', ')}");

      // Check cart table structure
      if (tables.any((t) => t['name'] == 'cart')) {
        final columns = await db.rawQuery('PRAGMA table_info(cart)');
        print("Cart table columns:");
        for (var col in columns) {
          print("  ${col['name']} (${col['type']})");
        }

        // Check cart content
        final cartItems = await db.query('cart');
        print("Cart items (${cartItems.length}):");
        for (var item in cartItems) {
          print("  ID: ${item['id']}, Title: ${item['title'] ?? 'No Title'}, "
              "Product ID: ${item['product_id']}, "
              "Quantity: ${item['quantity']}");
        }
      } else {
        print("Cart table doesn't exist!");
      }

      print("=== END DATABASE STATE LOG ===\n");
    } catch (e) {
      print("Error logging database state: $e");
    }
  }

  // Check if a table exists in the database
  Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  // Verify settings table structure
  Future<void> verifySettingsTable() async {
    try {
      final db = await database;

      // Check if table exists
      final tableExists = await _tableExists(db, 'settings');
      if (!tableExists) {
        await db.execute('''
          CREATE TABLE settings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            theme_mode TEXT,
            language TEXT,
            notifications INTEGER
          )
        ''');
        await db.insert('settings',
            {'theme_mode': 'system', 'language': 'en', 'notifications': 1});
        return;
      }

      // Check if there are settings
      final settingsCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM settings'));

      if (settingsCount == 0) {
        await db.insert('settings',
            {'theme_mode': 'system', 'language': 'en', 'notifications': 1});
        return;
      }

      // Check the type of theme_mode
      final settings = await db.query('settings', limit: 1);
      if (settings.isNotEmpty) {
        final setting = settings.first;
        // If theme_mode is an int, convert it to string
        if (setting['theme_mode'] is int) {
          int themeInt = setting['theme_mode'] as int;
          String themeStr =
              themeInt == 0 ? 'system' : (themeInt == 1 ? 'light' : 'dark');

          await db.update(
            'settings',
            {'theme_mode': themeStr},
            where: 'id = ?',
            whereArgs: [setting['id']],
          );
        }
      }
    } catch (e) {
      print('Error verifying settings table: $e');
    }
  }
}
