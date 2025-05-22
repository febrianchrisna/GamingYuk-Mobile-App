import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toko_game/providers/notification_provider.dart';
import 'package:toko_game/utils/constants.dart';
import 'package:toko_game/screens/game_detail_screen.dart';
import 'package:toko_game/screens/cart_screen.dart';
import 'package:toko_game/screens/home_screen.dart';

class AppNotificationListener extends StatefulWidget {
  final Widget child;

  const AppNotificationListener({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AppNotificationListener> createState() =>
      _AppNotificationListenerState();
}

class _AppNotificationListenerState extends State<AppNotificationListener> {
  @override
  void initState() {
    super.initState();
    _setupNotificationListeners();
  }

  void _setupNotificationListeners() {
    // Listen for notification creation events
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _onNotificationCreatedMethod,
      onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
    );
  }

  /// Use this method to detect when a new notification is created
  @pragma('vm:entry-point')
  static Future<void> _onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('Notification created: ${receivedNotification.title}');
  }

  /// Use this method to detect when a notification is displayed
  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('Notification displayed: ${receivedNotification.title}');
  }

  /// Use this method to detect when the user dismisses a notification
  @pragma('vm:entry-point')
  static Future<void> _onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('Notification dismissed: ${receivedAction.title}');
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma('vm:entry-point')
  static Future<void> _onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('Notification action received: ${receivedAction.actionType}');
    debugPrint('Notification payload: ${receivedAction.payload}');

    // We need to check if the app is in foreground or background
    if (receivedAction.actionType == ActionType.SilentAction ||
        receivedAction.actionType == ActionType.SilentBackgroundAction) {
      // Handle silent actions - these won't disturb the user
      return;
    }

    // Extract payload data
    final payload = receivedAction.payload?['data'];
    final actionKey = receivedAction.buttonKeyPressed;

    // Handle navigation based on payload and action buttons
    if (payload != null) {
      // For game details
      if (payload.startsWith('game:') ||
          payload.startsWith('discount:') ||
          payload.startsWith('release:')) {
        final gameId = payload.split(':')[1];
        AwesomeNotifications().navigateToNotificationContent(
          gameId,
          payload: {'route': '/game-detail', 'gameId': gameId},
        );
        return;
      }

      // For cart
      if (payload == 'cart_reminder' || actionKey == 'VIEW_CART') {
        AwesomeNotifications().navigateToNotificationContent(
          'cart',
          payload: {'route': AppRoutes.cart},
        );
        return;
      }
    }

    // Default navigation
    AwesomeNotifications().navigateToNotificationContent(
      'default',
      payload: {'route': AppRoutes.home},
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Extension method to handle notification navigation
extension NotificationNavigation on AwesomeNotifications {
  Future<void> navigateToNotificationContent(
    String targetId, {
    Map<String, String>? payload,
  }) async {
    // This method will be called to navigate to the proper screen
    if (payload == null) return;

    final route = payload['route'];
    if (route == null) return;

    // Get the navigator key from the app scaffold messenger
    final context = AppNavigator.navigatorKey.currentContext;
    if (context == null) return;

    switch (route) {
      case '/game-detail':
        final gameId = payload['gameId'];
        if (gameId != null) {
          Navigator.of(context, rootNavigator: true).pushNamed(
            route,
            arguments: gameId,
          );
        }
        break;

      case AppRoutes.cart:
        Navigator.of(context, rootNavigator: true).pushNamed(route);
        break;

      case AppRoutes.home:
      default:
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        break;
    }
  }
}

// A class to expose the navigator key
class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
