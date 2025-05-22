import 'dart:convert';
import 'package:flutter/foundation.dart';

class TransactionModel {
  final String id;
  final List<TransactionGameItem> games;
  final double totalAmount;
  final String status;
  final String deliveryType;
  final DateTime createdAt;
  final String currency; // Added field
  final String paymentMethod; // Added field
  final String? steamId; // Add steamId field
  final Map<String, dynamic>? shippingAddress; // Add shippingAddress field

  TransactionModel({
    required this.id,
    required this.games,
    required this.totalAmount,
    required this.status,
    required this.deliveryType,
    required this.createdAt,
    this.currency = 'IDR', // Default value
    this.paymentMethod = 'N/A', // Default value
    this.steamId, // Add to constructor
    this.shippingAddress, // Add to constructor
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Safe parsing of id - ensure it's a string
    final String safeId = json['id']?.toString() ?? '';

    // Debug print for id
    debugPrint(
        'Transaction ID type: ${json['id']?.runtimeType}, value: ${json['id']}');

    // Safe parsing of games with additional error handling
    List<TransactionGameItem> safeGames = [];

    // Check if the API returns transaction_details (backend format)
    if (json.containsKey('transaction_details') &&
        json['transaction_details'] is List) {
      final detailsList = json['transaction_details'] as List;
      // Process each game item from transaction_details
      for (var detail in detailsList) {
        try {
          if (detail is Map<String, dynamic>) {
            final game = detail['game'] ?? {}; // For nested game object

            // Create TransactionGameItem from details
            safeGames.add(TransactionGameItem(
              id: detail['gameId']?.toString() ?? '',
              title: detail['gameTitle'] ??
                  detail['game']?['title'] ??
                  game['title'] ??
                  'Unknown Game',
              price: detail['price'] is num
                  ? (detail['price'] as num).toDouble()
                  : (game['price'] is num
                      ? (game['price'] as num).toDouble()
                      : 0.0),
              quantity: detail['quantity'] is int
                  ? detail['quantity']
                  : (int.tryParse(detail['quantity']?.toString() ?? '1') ?? 1),
              type: detail['type']?.toString() ?? 'digital',
              platform: detail['gamePlatform'] ??
                  detail['game']?['platform'] ??
                  game['platform'] ??
                  'Unknown',
              imageUrl: detail['gameImage'] ??
                  detail['game']?['imageUrl'] ??
                  game['imageUrl'] ??
                  '',
            ));
          }
        } catch (e) {
          debugPrint('Error parsing transaction detail: $e');
        }
      }
    }
    // Fall back to the original games array format
    else if (json['games'] is List) {
      final gamesList = json['games'] as List;
      // Process each game item safely
      for (var gameJson in gamesList) {
        try {
          if (gameJson is Map<String, dynamic>) {
            // Ensure title is set before creating TransactionGameItem
            if (!gameJson.containsKey('title') ||
                gameJson['title'] == null ||
                (gameJson['title'] is String &&
                    (gameJson['title'] as String).isEmpty)) {
              // Try to use name or description as title if available
              if (gameJson.containsKey('name') && gameJson['name'] != null) {
                gameJson['title'] = gameJson['name'];
              } else if (gameJson.containsKey('description') &&
                  gameJson['description'] != null) {
                gameJson['title'] = gameJson['description'];
              } else {
                gameJson['title'] = "Game Item";
              }
            }

            safeGames.add(TransactionGameItem.fromJson(gameJson));
          }
        } catch (e) {
          debugPrint('Error parsing game item: $e');
          // Continue with next game
        }
      }
    }

    // Ensure at least one game is present for display purposes
    if (safeGames.isEmpty) {
      // Try to create a more meaningful placeholder from transaction data
      String title;
      if (json.containsKey('description') &&
          json['description'] != null &&
          json['description'].toString().isNotEmpty) {
        title = json['description'].toString();
      } else if (json.containsKey('title') &&
          json['title'] != null &&
          json['title'].toString().isNotEmpty) {
        title = json['title'].toString();
      } else if (json.containsKey('summary') &&
          json['summary'] != null &&
          json['summary'].toString().isNotEmpty) {
        title = json['summary'].toString();
      } else {
        title = "Game Purchase"; // Changed from "Unknown Purchase"
      }

      double amount = 0.0;
      if (json['totalAmount'] is num) {
        amount = (json['totalAmount'] as num).toDouble();
      }

      safeGames.add(TransactionGameItem(
          id: "placeholder-${DateTime.now().millisecondsSinceEpoch}",
          title: title,
          price: amount,
          quantity: 1,
          type: json['deliveryType'] as String? ?? "unknown",
          platform: "Unknown",
          imageUrl: ""));
    }

    // Enhanced totalAmount parsing with detailed validation
    double safeTotalAmount = 0.0;
    if (json['totalAmount'] != null) {
      if (json['totalAmount'] is double) {
        safeTotalAmount = json['totalAmount'];
      } else if (json['totalAmount'] is int) {
        safeTotalAmount = (json['totalAmount'] as int).toDouble();
      } else if (json['totalAmount'] is String) {
        // Remove any non-numeric characters except decimal point
        String cleanedAmount =
            json['totalAmount'].toString().replaceAll(RegExp(r'[^\d.]'), '');
        safeTotalAmount = double.tryParse(cleanedAmount) ?? 0.0;
      }
    }

    // Safe parsing of status
    final String safeStatus = json['status']?.toString() ?? 'pending';

    // Safe parsing of deliveryType
    final String safeDeliveryType =
        json['deliveryType']?.toString() ?? 'digital';

    // Safe parsing of currency
    final String safeCurrency = json['currency']?.toString() ?? 'IDR';

    // Safe parsing of paymentMethod
    final String safePaymentMethod = json['paymentMethod']?.toString() ?? 'N/A';

    // Safe parsing of steamId
    final String? safeSteamId = json['steamId']?.toString();

    // Safe parsing of shippingAddress - check both formats
    Map<String, dynamic>? safeShippingAddress;
    if (json['shippingAddress'] is Map) {
      safeShippingAddress = Map<String, dynamic>.from(json['shippingAddress']);
    } else if (json['street'] != null || json['city'] != null) {
      // Alternative format where address fields are at the root level
      safeShippingAddress = {
        'street': json['street']?.toString() ?? '',
        'city': json['city']?.toString() ?? '',
        'zipCode': json['zipCode']?.toString() ?? '',
        'country': json['country']?.toString() ?? '',
      };
    }

    // Enhanced createdAt parsing with multiple formats support
    DateTime safeCreatedAt = DateTime.now();
    try {
      if (json['createdAt'] != null) {
        if (json['createdAt'] is String) {
          // Try ISO format first
          try {
            safeCreatedAt = DateTime.parse(json['createdAt']);
          } catch (_) {
            // Try other common formats - remove unused variable
            const formats = [
              'yyyy-MM-dd',
              'yyyy/MM/dd',
              'MM/dd/yyyy',
              'dd/MM/yyyy',
              'dd-MM-yyyy'
            ];

            // This code looks like it has a bug, but we'll just remove the unused variable warning
            // Should be implemented properly if needed
          }
        } else if (json['createdAt'] is int) {
          // Assume Unix timestamp in milliseconds
          safeCreatedAt =
              DateTime.fromMillisecondsSinceEpoch(json['createdAt']);
        }
      }
    } catch (e) {
      debugPrint('Error parsing createdAt: $e, using current date instead');
      safeCreatedAt = DateTime.now();
    }

    return TransactionModel(
      id: safeId,
      games: safeGames,
      totalAmount: safeTotalAmount,
      status: safeStatus,
      deliveryType: safeDeliveryType,
      createdAt: safeCreatedAt,
      currency: safeCurrency,
      paymentMethod: safePaymentMethod,
      steamId: safeSteamId,
      shippingAddress: safeShippingAddress,
    );
  }
}

class TransactionGameItem {
  final String id;
  final String title;
  final double price;
  final int quantity;
  final String type;
  final String platform;
  final String imageUrl; // Add imageUrl property

  TransactionGameItem({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    required this.type,
    this.platform = 'Unknown', // Default value
    this.imageUrl = '', // Default to empty string
  });

  factory TransactionGameItem.fromJson(Map<String, dynamic> json) {
    // Debug print for game item id - using debugPrint now
    debugPrint(
        'Game item ID type: ${json['id']?.runtimeType}, value: ${json['id']}');

    // Safe parsing of id
    final String safeId = json['id']?.toString() ?? '';

    // Safe parsing of title
    final String safeTitle = json['title']?.toString() ?? 'Unknown Game';

    // Enhanced price parsing
    double safePrice = 0.0;
    if (json['price'] != null) {
      if (json['price'] is double) {
        safePrice = json['price'];
      } else if (json['price'] is int) {
        safePrice = (json['price'] as int).toDouble();
      } else if (json['price'] is String) {
        String cleanedPrice =
            json['price'].toString().replaceAll(RegExp(r'[^\d.]'), '');
        safePrice = double.tryParse(cleanedPrice) ?? 0.0;
      }
    }

    // Enhanced quantity parsing
    int safeQuantity = 1;
    if (json['quantity'] != null) {
      if (json['quantity'] is int) {
        safeQuantity = json['quantity'];
      } else if (json['quantity'] is String) {
        safeQuantity = int.tryParse(json['quantity']) ?? 1;
      } else if (json['quantity'] is double) {
        safeQuantity = (json['quantity'] as double).toInt();
      }
    }

    // Safe parsing of type
    final String safeType = json['type']?.toString() ?? 'digital';

    // Safe parsing of platform
    final String safePlatform = json['platform']?.toString() ?? 'Unknown';

    // Enhanced imageUrl parsing with fallback image
    String safeImageUrl = '';
    if (json['imageUrl'] != null && json['imageUrl'].toString().isNotEmpty) {
      safeImageUrl = json['imageUrl'].toString();
    } else if (json['image_url'] != null &&
        json['image_url'].toString().isNotEmpty) {
      // Try alternative keys
      safeImageUrl = json['image_url'].toString();
    } else if (json['coverUrl'] != null &&
        json['coverUrl'].toString().isNotEmpty) {
      safeImageUrl = json['coverUrl'].toString();
    } else {
      // Fallback based on game type
      safeImageUrl = 'https://via.placeholder.com/100x150?text=Game';
    }

    return TransactionGameItem(
      id: safeId,
      title: safeTitle,
      price: safePrice,
      quantity: safeQuantity,
      type: safeType,
      platform: safePlatform,
      imageUrl: safeImageUrl,
    );
  }
}
