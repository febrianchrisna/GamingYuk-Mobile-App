import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart'; // Add this import for debugPrint
import 'package:http/http.dart' as http;
import 'package:toko_game/models/game_model.dart';
import 'package:toko_game/utils/constants.dart';
import 'package:toko_game/utils/secure_storage.dart';

class ApiService {
  // Base URL for the games API
  final String baseUrl =
      'https://toko-game-be-663618957788.us-central1.run.app'; // Replace with your actual API URL

  // Get games from API
  Future<List<GameModel>> getGames({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/games?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('Games API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        debugPrint(
            'Games API response body: ${response.body.substring(0, min(100, response.body.length))}...');

        // Updated to check for 'games' field instead of 'data'
        if (jsonData.containsKey('games') && jsonData['games'] is List) {
          final List<dynamic> gamesJson = jsonData['games'];
          return gamesJson.map((json) => GameModel.fromJson(json)).toList();
        } else {
          debugPrint(
              'Invalid API response format. Expected games field with list: $jsonData');
          throw Exception('Invalid API response format');
        }
      } else {
        debugPrint('API returned status code: ${response.statusCode}');
        throw Exception('Failed to load games: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching games: $e');
      return [];
    }
  }

  // Get game by ID from API
  Future<GameModel> getGameById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/games/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('Game detail API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        debugPrint(
            'Game detail API response body: ${response.body.substring(0, min(100, response.body.length))}...');

        // The response might directly be the game object
        if (jsonData is Map<String, dynamic>) {
          return GameModel.fromJson(jsonData);
        } else {
          debugPrint(
              'Invalid API response format. Expected game data: $jsonData');
          throw Exception('Invalid API response format');
        }
      } else if (response.statusCode == 404) {
        throw Exception(
            'Game not found. The requested game may have been removed or is unavailable.');
      } else {
        throw Exception('Failed to load game details: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching game details: $e');
      rethrow;
    }
  }

  // Search games from API
  Future<List<GameModel>> searchGames(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/games/search?q=$query'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('Search API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        debugPrint(
            'Search API response body: ${response.body.substring(0, min(100, response.body.length))}...');

        // Updated to check for 'games' field instead of 'data'
        if (jsonData.containsKey('games') && jsonData['games'] is List) {
          final List<dynamic> gamesJson = jsonData['games'];
          return gamesJson.map((json) => GameModel.fromJson(json)).toList();
        } else {
          debugPrint(
              'Invalid API response format. Expected games field with list: $jsonData');
          return [];
        }
      } else {
        debugPrint('API returned status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error searching games: $e');
      return [];
    }
  }

  // Get categories from API - updated to handle a direct list response
  Future<List<String>> getGameCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/games/categories'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('Categories API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        debugPrint(
            'Categories API response body: ${response.body.substring(0, min(100, response.body.length))}...');

        // Check if the response is a direct list of categories
        if (jsonData is List) {
          return jsonData.map((category) => category.toString()).toList();
        }
        // Alternatively, check if it has a 'data' field containing the list
        else if (jsonData is Map &&
            jsonData.containsKey('data') &&
            jsonData['data'] is List) {
          final List<dynamic> categoriesJson = jsonData['data'];
          return categoriesJson.map((json) => json.toString()).toList();
        } else {
          debugPrint('Invalid API response format for categories: $jsonData');
          // Provide some default categories so the app still works
          return ['Action', 'Adventure', 'RPG', 'Sports'];
        }
      } else {
        debugPrint('API returned status code: ${response.statusCode}');
        // Provide some default categories so the app still works
        return ['Action', 'Adventure', 'RPG', 'Sports'];
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      // Provide some default categories so the app still works
      return ['Action', 'Adventure', 'RPG', 'Sports'];
    }
  }

  // Create transaction on API
  Future<Map<String, dynamic>> createTransaction({
    required List<Map<String, dynamic>> games,
    required double totalAmount,
    String currency = 'IDR',
    required String paymentMethod,
    required String deliveryType,
    String? steamId,
    Map<String, dynamic>? shippingAddress,
  }) async {
    try {
      final token = await SecureStorage.getTokenAsync();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Standardize the type values to ensure they match the backend requirements
      final standardizedGames = games.map((game) {
        // Ensure type is one of the accepted values (digital, fisik) to avoid truncation
        String standardizedType = game['type'].toString().toLowerCase();
        if (standardizedType != 'digital' && standardizedType != 'fisik') {
          // Default to digital if an invalid value is provided
          standardizedType = 'digital';
        }

        return {
          'gameId': game['gameId'],
          'quantity': game['quantity'],
          'type': standardizedType, // Use the standardized type value
        };
      }).toList();

      // Structure the request data according to the backend API requirements
      final Map<String, dynamic> requestData = {
        'games': standardizedGames,
        'paymentMethod': paymentMethod,
        'deliveryType': deliveryType,
      };

      // Add steam ID for digital deliveries
      if (steamId != null &&
          (deliveryType == 'digital' || deliveryType == 'keduanya')) {
        requestData['steamId'] = steamId;
      }

      // Add shipping address for physical deliveries - directly include fields at root level
      if (shippingAddress != null &&
          (deliveryType == 'fisik' || deliveryType == 'keduanya')) {
        // The API expects these fields at the root level, not nested under shippingAddress
        requestData['street'] = shippingAddress['street'];
        requestData['city'] = shippingAddress['city'];
        requestData['zipCode'] = shippingAddress['zipCode'];
        requestData['country'] = shippingAddress['country'];
      }

      // Log the full request for debugging
      debugPrint('Transaction API request: ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.transactionsEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );

      debugPrint('Transaction API response status: ${response.statusCode}');
      debugPrint('Transaction API response body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorResponse = json.decode(response.body);
        final errorMessage =
            errorResponse['message'] ?? 'Unknown error occurred';
        throw Exception(
            'Failed to create transaction: ${response.statusCode}\n$errorMessage');
      }
    } catch (e) {
      debugPrint('Error creating transaction: $e');
      rethrow;
    }
  }

  // Get transaction history for the user
  Future<List<dynamic>> getTransactions() async {
    try {
      // Get authentication token
      final token = await SecureStorage.getTokenAsync();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      debugPrint(
          'Fetching transactions with token: ${token.substring(0, min(10, token.length))}...');

      // Make the API request to the fixed endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/api/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint(
          'Transaction history API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint(
            'Transaction history API response body: ${response.body.substring(0, min(100, response.body.length))}...');

        // Process data to ensure IDs are strings before returning
        List<dynamic> transactions = [];

        if (data is Map) {
          if (data.containsKey('data')) {
            transactions = _processTransactionData(data['data']);
          } else if (data.containsKey('transactions')) {
            transactions = _processTransactionData(data['transactions']);
          } else {
            transactions = _processTransactionData([data]);
          }
        } else if (data is List) {
          transactions = _processTransactionData(data);
        }

        return transactions;
      } else if (response.statusCode == 401) {
        throw Exception('Your session has expired. Please log in again.');
      } else if (response.statusCode == 403) {
        // This shouldn't happen anymore with the fixed API, but keep just in case
        debugPrint('Full error response: ${response.body}');
        throw Exception(
            'You do not have permission to view transaction history. Please log in again.');
      } else {
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ??
              'Failed to load transactions: ${response.statusCode}';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception(
              'Failed to load transactions: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      // Rethrow the exception so it can be handled by the UI
      rethrow;
    }
  }

  // Get transaction detail by ID
  Future<Map<String, dynamic>> getTransactionById(String id) async {
    try {
      // Get authentication token
      final token = await SecureStorage.getTokenAsync();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/transactions/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Your session has expired. Please log in again.');
      } else {
        throw Exception('Failed to load transaction: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching transaction: $e');
      rethrow;
    }
  }

  // Delete transaction (cancel order)
  Future<bool> deleteTransaction(String id) async {
    try {
      // Get authentication token
      final token = await SecureStorage.getTokenAsync();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/transactions/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('Delete transaction response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Your session has expired. Please log in again.');
      } else {
        throw Exception('Failed to cancel transaction: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error cancelling transaction: $e');
      rethrow;
    }
  }

  // Update transaction (edit payment method or shipping address)
  Future<Map<String, dynamic>> updateTransaction(
      String id, Map<String, dynamic> updateData) async {
    try {
      // Get authentication token
      final token = await SecureStorage.getTokenAsync();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      // Process any nested shippingAddress structure
      if (updateData.containsKey('shippingAddress')) {
        final address =
            updateData.remove('shippingAddress') as Map<String, dynamic>;
        // Flatten address fields to root level
        updateData['street'] = address['street'];
        updateData['city'] = address['city'];
        updateData['zipCode'] = address['zipCode'];
        updateData['country'] = address['country'];
      }

      debugPrint(
          "Calling PUT /api/transactions/$id with data: ${json.encode(updateData)}");

      // Validate shipping address if present
      if (updateData.containsKey('shippingAddress')) {
        final address = updateData['shippingAddress'] as Map<String, dynamic>;
        if (address['street']?.isEmpty ??
            true || address['city']?.isEmpty ??
            true || address['zipCode']?.isEmpty ??
            true || address['country']?.isEmpty ??
            true) {
          throw Exception(
              'Shipping address is required for physical deliveries. All fields must be completed.');
        }
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/api/transactions/$id'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(updateData),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
          'Update transaction response: [${response.statusCode}] ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 400) {
        // Parse error message from response
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Bad request error';
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception('Your session has expired. Please log in again.');
      } else {
        throw Exception(
            'Failed to update transaction: Error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      rethrow;
    }
  }

  // Helper method to preprocess transaction data to ensure consistent types
  List<dynamic> _processTransactionData(List<dynamic> data) {
    for (int i = 0; i < data.length; i++) {
      if (data[i] is Map<String, dynamic>) {
        final item = data[i] as Map<String, dynamic>;

        // Ensure ID is a string
        if (item.containsKey('id')) {
          item['id'] = item['id'].toString();
        }

        // Ensure games array is always initialized
        if (!item.containsKey('games') || item['games'] == null) {
          item['games'] = []; // Initialize with empty array if missing
        }

        // Process games if present
        if (item.containsKey('games') && item['games'] is List) {
          final games = item['games'] as List;
          for (int j = 0; j < games.length; j++) {
            if (games[j] is Map<String, dynamic>) {
              final game = games[j] as Map<String, dynamic>;

              // Ensure game ID is a string
              if (game.containsKey('id')) {
                game['id'] = game['id'].toString();
              }

              // Ensure title is present and not empty
              if (!game.containsKey('title') ||
                  game['title'] == null ||
                  (game['title'] is String &&
                      (game['title'] as String).isEmpty)) {
                // Try to use description as title if available
                if (game.containsKey('description') &&
                    game['description'] != null &&
                    game['description'].toString().isNotEmpty) {
                  game['title'] = game['description'];
                } else {
                  game['title'] = 'Game Item';
                }
              }

              // Ensure required fields exist with default values
              if (!game.containsKey('price') || game['price'] == null) {
                game['price'] = 0.0;
              }
              if (!game.containsKey('quantity') || game['quantity'] == null) {
                game['quantity'] = 1;
              }
              if (!game.containsKey('type') || game['type'] == null) {
                game['type'] = 'digital';
              }
            }
          }
        }

        // If games list is empty but we have a description, create a placeholder game
        // This prevents showing "Unknown Purchase"
        if ((item['games'] as List).isEmpty &&
            item.containsKey('description') &&
            item['description'] != null &&
            item['description'].toString().isNotEmpty) {
          (item['games'] as List).add({
            'id': 'gen-${DateTime.now().millisecondsSinceEpoch}',
            'title': item['description'].toString(),
            'price': item['totalAmount'] ?? 0.0,
            'quantity': 1,
            'type': item['deliveryType'] ?? 'digital',
            'platform': 'Unknown'
          });
        }
      }
    }
    return data;
  }

  // Generate mock transaction data with fixed image URLs
  List<Map<String, dynamic>> _getMockTransactions() {
    final now = DateTime.now();

    return [
      {
        'id': 'mock123456789',
        'status': 'completed',
        'totalAmount': 750000,
        'currency': 'IDR',
        'paymentMethod': 'Credit Card',
        'deliveryType': 'digital',
        'createdAt': now.subtract(const Duration(days: 5)).toIso8601String(),
        'games': [
          {
            'id': 'game123',
            'title': 'Cyberpunk 2077',
            'price': 750000,
            'quantity': 1,
            'type': 'digital',
            'platform': 'PC',
            'imageUrl':
                'https://images.igdb.com/igdb/image/upload/t_cover_big/co2mjs.jpg'
          }
        ]
      },
      {
        'id': 'mock987654321',
        'status': 'pending',
        'totalAmount': 1100000,
        'currency': 'IDR',
        'paymentMethod': 'Bank Transfer',
        'deliveryType': 'keduanya',
        'createdAt': now.subtract(const Duration(days: 2)).toIso8601String(),
        'games': [
          {
            'id': 'game456',
            'title': 'The Last of Us Part II',
            'price': 700000,
            'quantity': 1,
            'type': 'fisik',
            'platform': 'PlayStation',
            'imageUrl':
                'https://images.igdb.com/igdb/image/upload/t_cover_big/co5ziw.jpg'
          },
          {
            'id': 'game789',
            'title': 'Minecraft',
            'price': 400000,
            'quantity': 1,
            'type': 'digital',
            'platform': 'PC',
            'imageUrl':
                'https://images.igdb.com/igdb/image/upload/t_cover_big/co49x5.jpg'
          }
        ]
      },
      {
        'id': 'mock567891234',
        'status': 'cancelled',
        'totalAmount': 600000,
        'currency': 'IDR',
        'paymentMethod': 'E-Wallet',
        'deliveryType': 'fisik',
        'createdAt': now.subtract(const Duration(days: 10)).toIso8601String(),
        'games': [
          {
            'id': 'game321',
            'title': 'Red Dead Redemption 2',
            'price': 600000,
            'quantity': 1,
            'type': 'fisik',
            'platform': 'Xbox',
            'imageUrl':
                'https://images.igdb.com/igdb/image/upload/t_cover_big/co1q1f.jpg'
          }
        ]
      }
    ];
  }
}
