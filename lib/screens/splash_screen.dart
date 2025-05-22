import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toko_game/providers/auth_provider.dart';
import 'package:toko_game/providers/notification_provider.dart';
import 'package:toko_game/screens/home_screen.dart';
import 'package:toko_game/screens/auth/login_screen.dart';
import 'package:toko_game/utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Initialize notifications
    _initNotifications();

    Future.delayed(const Duration(seconds: 3), () {
      navigateToNextScreen();
    });
  }

  Future<void> _initNotifications() async {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    // Check if permission is already granted
    final isGranted = await notificationProvider.isPermissionGranted();
    if (!isGranted) {
      // Request permission - fix: use requestNotificationPermission instead
      await notificationProvider.requestNotificationPermission();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void navigateToNextScreen() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    // Navigate to the appropriate screen
    Widget nextScreen =
        authProvider.isAuthenticated ? const HomeScreen() : const LoginScreen();

    // Show welcome notification if the user is authenticated
    if (authProvider.isAuthenticated && authProvider.userData != null) {
      final username = authProvider.userData!['username'] ?? 'Gamer';
      // Make sure we send the notification
      Future.delayed(const Duration(seconds: 1), () {
        notificationProvider.sendWelcomeNotification(username);
        debugPrint("🔔 Welcome notification triggered for $username");
      });
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // Fix: Replace withOpacity with withAlpha
                    color: AppColors.primaryColor.withAlpha(26), // ~0.1 opacity
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.games,
                    size: 80,
                    color: AppColors.primaryColor,
                  ),
                ),

                const SizedBox(height: 24),

                // App name
                Text(
                  'GamingYuk',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    // Fix: Replace withOpacity with withAlpha
                    shadows: [
                      Shadow(
                        color: Colors.black.withAlpha(64), // ~0.25 opacity
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tag line
                const Text(
                  'Your Ultimate Gaming Destination',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 48),

                // Loading indicator
                const CircularProgressIndicator(),

                const SizedBox(height: 16),

                // Loading text
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    // Fix: Replace withOpacity with withAlpha
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
