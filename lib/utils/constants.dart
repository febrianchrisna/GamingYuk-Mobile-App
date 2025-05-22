import 'package:flutter/material.dart';

// API constants
class ApiConstants {
  // Set development mode to false to use the real API
  static const bool devMode = false;

  // API Base URL
  static const String baseUrl =
      'https://toko-game-be-663618957788.us-central1.run.app';

  // Auth endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String refreshTokenEndpoint = '/api/auth/token';
  static const String profileEndpoint = '/api/auth/profile';

  // Game endpoints
  static const String gamesEndpoint = '/api/games';
  static const String searchGamesEndpoint = '/api/games/search';
  static const String categoriesEndpoint = '/api/games/categories';
  static const String platformsEndpoint = '/api/games/platforms';
  static const String gameDetailEndpoint =
      '/api/games'; // Base endpoint for game/:id

  // Transaction endpoints
  static const String transactionsEndpoint = '/api/transactions';
  static const String transactionDetailEndpoint =
      '/api/transactions'; // Base endpoint for transaction/:id
  static const String cancelTransactionEndpoint =
      '/api/transactions'; // Base endpoint for transaction/:id/cancel

  // Notification endpoints
  static const String notificationsEndpoint = '/api/notifications';
  static const String markNotificationReadEndpoint =
      '/api/notifications'; // Base endpoint for notifications/:id/read
  static const String markAllNotificationsReadEndpoint =
      '/api/notifications/read-all';
}

// App colors
class AppColors {
  static const Color primaryColor = Color(0xFF7C4DFF);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color accentColor = Color(0xFFFF4081);
  static const Color textColor = Color(0xFF333333);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF757575);
  static const Color errorColor = Color(0xFFB00020);
  static const Color successColor = Color(0xFF4CAF50);
}

// App text styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textColor,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    color: AppColors.textColor,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.darkGray,
  );
}

// Routes
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String gameDetail = '/game-detail';
  static const String cart = '/cart';
  static const String profile = '/profile';
  static const String checkout = '/checkout';
  static const String transactionHistory = '/transactions';
  static const String notifications = '/notifications';
  static const String gameNearby = '/game-nearby';
  static const String currencyConverter = '/currency-converter';
  static const String timeConverter = '/time-converter';
  static const String tapGame = '/tap-game';
  static const String feedback = '/feedback';
  static const String settings = '/settings'; // Added settings route
}
