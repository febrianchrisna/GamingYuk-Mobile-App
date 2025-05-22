import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:toko_game/providers/auth_provider.dart';
import 'package:toko_game/providers/cart_provider.dart';
import 'package:toko_game/providers/theme_provider.dart';
import 'package:toko_game/providers/currency_provider.dart';
import 'package:toko_game/providers/time_zone_provider.dart';
import 'package:toko_game/providers/notification_provider.dart';
import 'package:toko_game/screens/splash_screen.dart';
import 'package:toko_game/screens/auth/login_screen.dart';
import 'package:toko_game/screens/auth/register_screen.dart';
import 'package:toko_game/screens/home_screen.dart';
import 'package:toko_game/screens/explore_screen.dart';
import 'package:toko_game/screens/game_detail_screen.dart';
import 'package:toko_game/screens/cart_screen.dart';
import 'package:toko_game/utils/constants.dart';
import 'package:toko_game/utils/database_helper.dart';
import 'package:toko_game/utils/secure_storage.dart';
import 'package:toko_game/utils/notification_listener.dart'
    as app_notifications;
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  // Initialize bindings inside same zone as runApp
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Set up notification action listener for when app is terminated/killed
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    );

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Initialize SQLite database with proper error handling
    final DatabaseHelper dbHelper = DatabaseHelper();
    try {
      await dbHelper.initDatabase();
      await dbHelper.verifySettingsTable();

      // Initialize SecureStorage with the database
      await SecureStorage.initialize(dbHelper);

      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('Error initializing database: $e');
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => ThemeProvider(dbHelper: dbHelper)),
          ChangeNotifierProvider(
              create: (_) => AuthProvider(dbHelper: dbHelper)),
          ChangeNotifierProvider(
              create: (_) => CartProvider(dbHelper: dbHelper)),
          ChangeNotifierProvider(
            create: (ctx) => CurrencyProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => TimeZoneProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => NotificationProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('UNCAUGHT ERROR: $error');
    debugPrint('Stack trace: $stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'GamingYuk',
      debugShowCheckedModeBanner: false,
      navigatorKey: app_notifications.AppNavigator.navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor,
          brightness: Brightness.light,
        ),
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textColor,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.textColor,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      themeMode: themeProvider.themeMode,
      home: const app_notifications.AppNotificationListener(
        child: SplashScreen(),
      ),
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        '/explore': (context) => const ExploreScreen(),
        AppRoutes.cart: (context) => const CartScreen(),
        '/game-detail': (context) {
          final gameId = ModalRoute.of(context)?.settings.arguments as String;
          return GameDetailScreen(gameId: gameId);
        },
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
        );
      },
      builder: (context, child) {
        return app_notifications.AppNotificationListener(child: child!);
      },
    );
  }
}

class NotificationController {
  /// This method is called when the app is terminated and a notification action is triggered
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint("🔔 Notification action received when app was TERMINATED");
    debugPrint("🔔 Action: ${receivedAction.actionType}");
    debugPrint("🔔 Payload: ${receivedAction.payload}");

    // Create a stream to communicate with the app when it's opened
    // This requires more setup, but we're keeping it simple for now
  }
}
