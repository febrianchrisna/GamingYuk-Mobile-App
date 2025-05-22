import 'package:intl/intl.dart';

class GameModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final String publisher;
  final DateTime releaseDate;
  final String platform;
  final String category;
  final bool hasDigital;
  final bool hasFisik;
  final double rating;

  GameModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.publisher,
    required this.releaseDate,
    required this.platform,
    required this.category,
    required this.hasDigital,
    required this.hasFisik,
    required this.rating,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    // Parse date safely
    DateTime parseDate() {
      try {
        if (json['releaseDate'] is String) {
          return DateTime.parse(json['releaseDate']);
        } else {
          return DateTime.now();
        }
      } catch (e) {
        return DateTime.now();
      }
    }

    // Ensure ID is always String
    String safeId = json['id']?.toString() ?? '';

    // Ensure numeric values are correct type
    double safePrice = 0.0;
    if (json['price'] is int) {
      safePrice = (json['price'] as int).toDouble();
    } else if (json['price'] is double) {
      safePrice = json['price'];
    } else if (json['price'] is String) {
      safePrice = double.tryParse(json['price']) ?? 0.0;
    }

    double safeRating = 0.0;
    if (json['rating'] is int) {
      safeRating = (json['rating'] as int).toDouble();
    } else if (json['rating'] is double) {
      safeRating = json['rating'];
    } else if (json['rating'] is String) {
      safeRating = double.tryParse(json['rating']) ?? 0.0;
    }

    return GameModel(
      id: safeId,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: safePrice,
      imageUrl: json['imageUrl']?.toString() ?? '',
      publisher: json['publisher']?.toString() ?? '',
      releaseDate: parseDate(),
      platform: json['platform']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      hasDigital: json['hasDigital'] == true,
      hasFisik: json['hasFisik'] == true,
      rating: safeRating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'publisher': publisher,
      'releaseDate': DateFormat('yyyy-MM-dd').format(releaseDate),
      'platform': platform,
      'category': category,
      'hasDigital': hasDigital,
      'hasFisik': hasFisik,
      'rating': rating,
    };
  }
}
