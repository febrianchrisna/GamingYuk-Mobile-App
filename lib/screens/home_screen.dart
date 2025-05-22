import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toko_game/providers/auth_provider.dart';
import 'package:toko_game/providers/notification_provider.dart'; // Add this import
import 'package:toko_game/screens/cart_screen.dart';
import 'package:toko_game/screens/explore_screen.dart';
import 'package:toko_game/screens/profile_screen.dart';
import 'package:toko_game/screens/utils_screen.dart';
import 'package:toko_game/screens/home_page_screen.dart';
import 'package:toko_game/utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const HomePageScreen(),
    const ExploreScreen(),
    const CartScreen(),
    const UtilsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Check notification permissions
    _checkNotificationPermission();

    // Update app activity timestamp whenever home screen is shown
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    notificationProvider.updateAppActivity();

    debugPrint("🏠 HomeScreen: App activity timestamp updated");
  }

  Future<void> _checkNotificationPermission() async {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    final isGranted = await notificationProvider.isPermissionGranted();
    if (!isGranted) {
      // Show dialog asking for permission after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _showNotificationPermissionDialog();
        }
      });
    }
  }

  void _showNotificationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Text(
            'Get notified about new games, discounts, and other important updates. Would you like to enable notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              final notificationProvider =
                  Provider.of<NotificationProvider>(context, listen: false);
              // Fix: Use requestNotificationPermission() instead of requestPermission()
              notificationProvider.requestNotificationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    _pageController.jumpToPage(index);
    setState(() {
      _currentIndex = index;
    });

    // Update activity timestamp when user navigates
    _updateUserActivity();
  }

  // Add this method to update activity timestamp when user interacts with the app
  void _updateUserActivity() {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    notificationProvider.updateAppActivity();
    debugPrint("👆 User activity detected: timestamp updated");
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If not authenticated, redirect to login
    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      });
    }

    return GestureDetector(
      onTap: _updateUserActivity,
      child: Scaffold(
        appBar: _currentIndex == 0
            ? AppBar(
                title: const Text('GamingYuk'),
                elevation: 0,
                backgroundColor: Colors.transparent,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.person_outline),
                    onPressed: _navigateToProfile,
                  ),
                ],
              )
            : null,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1F1F1F)
                : Colors.white,
            selectedItemColor: AppColors.primaryColor,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                activeIcon: Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Utilities',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
