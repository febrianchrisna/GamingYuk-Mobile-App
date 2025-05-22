import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:toko_game/utils/database_helper.dart';

class SecureStorage {
  static DatabaseHelper? _dbHelper;
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  // Initialize with dbHelper instance
  static Future<void> initialize(DatabaseHelper dbHelper) async {
    _dbHelper = dbHelper;
    await _ensureAuthTableExists();
  }

  // Create auth table if it doesn't exist
  static Future<void> _ensureAuthTableExists() async {
    if (_dbHelper == null) {
      print('SecureStorage: dbHelper is null!');
      return;
    }

    final db = await _dbHelper!.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS auth_storage(
        id INTEGER PRIMARY KEY,
        key TEXT UNIQUE,
        value TEXT
      )
    ''');
  }

  // Dummy implementations for synchronous methods
  static String? getToken() {
    print('Warning: Using synchronous getToken() which always returns null');
    return null;
  }

  static Map<String, dynamic>? getUserData() {
    print('Warning: Using synchronous getUserData() which always returns null');
    return null;
  }

  // ASYNCHRONOUS METHODS (preferred)
  static Future<String?> getTokenAsync() async {
    return await _getValue(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    await _saveValue(_tokenKey, token);
  }

  static Future<Map<String, dynamic>?> getUserDataAsync() async {
    try {
      final data = await _getValue(_userDataKey);
      if (data == null) return null;

      // Parse and sanitize user data to ensure consistent types
      final parsedData = json.decode(data);
      if (parsedData is Map) {
        // Convert to Map<String, dynamic> and sanitize types
        final Map<String, dynamic> sanitizedData = {};

        parsedData.forEach((key, value) {
          if (key == 'id' || key.endsWith('Id')) {
            // Make sure IDs are stored as strings for consistency
            sanitizedData[key] = value.toString();
          } else {
            sanitizedData[key] = value;
          }
        });

        return sanitizedData;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    // Sanitize the data before saving
    final sanitizedData = Map<String, dynamic>.from(userData);

    // Make sure all ID fields are strings
    userData.forEach((key, value) {
      if (key == 'id' || key.endsWith('Id')) {
        sanitizedData[key] = value.toString();
      }
    });

    await _saveValue(_userDataKey, json.encode(sanitizedData));
  }

  // Helper method to save a value
  static Future<void> _saveValue(String key, String value) async {
    if (_dbHelper == null) {
      print('SecureStorage: dbHelper is null!');
      return;
    }

    final db = await _dbHelper!.database;
    await db.insert(
      'auth_storage',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Helper method to get a value
  static Future<String?> _getValue(String key) async {
    if (_dbHelper == null) {
      print('SecureStorage: dbHelper is null!');
      return null;
    }

    final db = await _dbHelper!.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'auth_storage',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  // Clear all auth data
  static Future<void> logout() async {
    if (_dbHelper == null) {
      print('SecureStorage: dbHelper is null!');
      return;
    }

    final db = await _dbHelper!.database;
    await db.delete('auth_storage');
  }
}
