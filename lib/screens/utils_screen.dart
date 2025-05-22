import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toko_game/providers/notification_provider.dart';
import 'package:toko_game/screens/currency_converter_screen.dart';
import 'package:toko_game/screens/nearby_stores_screen.dart';
import 'package:toko_game/screens/profile_screen.dart';
import 'package:toko_game/screens/tap_game_screen.dart';
import 'package:toko_game/screens/time_converter_screen.dart';
import 'package:toko_game/utils/constants.dart';

class UtilsScreen extends StatelessWidget {
  const UtilsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Useful Tools',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Explore these helpful tools for gamers',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 24),

            // Currency Converter
            _buildUtilityCard(
              context,
              icon: Icons.currency_exchange,
              color: Colors.green,
              title: 'Currency Converter',
              description: 'Convert between IDR, USD, EUR, and more',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CurrencyConverterScreen(),
                  ),
                );
              },
            ),

            // Time Converter
            _buildUtilityCard(
              context,
              icon: Icons.access_time,
              color: Colors.blue,
              title: 'Time Zone Converter',
              description:
                  'Check and set the app time zone (WIB, WIT, WITA, etc.)',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TimeConverterScreen(),
                  ),
                );
              },
            ),

            // Notification Settings
            _buildUtilityCard(
              context,
              icon: Icons.notifications_active,
              color: Colors.orange,
              title: 'Notification Settings',
              description: 'Manage your notification preferences',
              onTap: () {
                _showNotificationSettingsDialog(context);
              },
            ),

            // Nearby Game Stores
            _buildUtilityCard(
              context,
              icon: Icons.store,
              color: Colors.purple,
              title: 'Nearby Game Stores',
              description: 'Find physical game stores near you',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NearbyStoresScreen(),
                  ),
                );
              },
            ),

            // Mini Game
            _buildUtilityCard(
              context,
              icon: Icons.gamepad,
              color: Colors.red,
              title: 'Mini Game',
              description: 'Take a break with a quick game',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TapGameScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettingsDialog(BuildContext context) async {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    // Fix: Use the correct method name
    final isGranted = await notificationProvider.isPermissionGranted();
    final backgroundEnabled =
        notificationProvider.backgroundNotificationsEnabled;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('Enable Notifications'),
              subtitle: Text(isGranted
                  ? 'Notifications are enabled'
                  : 'Notifications are disabled'),
              leading: Icon(
                isGranted
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: isGranted ? Colors.green : Colors.grey,
              ),
              trailing: Switch(
                value: isGranted,
                activeColor: AppColors.primaryColor,
                onChanged: (value) async {
                  Navigator.of(context).pop();
                  if (value) {
                    // Fix: Use requestNotificationPermission() instead of requestPermission()
                    await notificationProvider.requestNotificationPermission();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please disable notifications in your device settings',
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            if (isGranted)
              ListTile(
                title: const Text('Background Notifications'),
                subtitle: const Text(
                    'Get notified about promotions and reminders even when app is closed'),
                leading: Icon(
                  backgroundEnabled
                      ? Icons.circle_notifications
                      : Icons.notifications_paused,
                  color: backgroundEnabled ? Colors.orange : Colors.grey,
                ),
                trailing: Switch(
                  value: backgroundEnabled,
                  activeColor: AppColors.accentColor,
                  onChanged: (value) {
                    notificationProvider.setBackgroundNotifications(value);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Background notifications enabled'
                              : 'Background notifications disabled',
                        ),
                        backgroundColor: value ? Colors.green : Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            const Divider(),
            const Text(
              'To fully customize notification settings, please visit your device settings.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // Fix: Replace withOpacity with withAlpha to avoid deprecation warning
                  color: color.withAlpha(
                      25), // Approximately 0.1 opacity as alpha value (25/255)
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
