import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:toko_game/utils/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  // Initialize notifications
  Future<void> initialize() async {
    debugPrint("🔔 Initializing AwesomeNotifications");

    // Make sure we have the proper defaults and clean up previous notifications
    await AwesomeNotifications().resetGlobalBadge();
    await AwesomeNotifications().cancelAll();

    try {
      final result = await AwesomeNotifications().initialize(
        null, // Null is fine for testing, will use default icon
        [
          NotificationChannel(
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic notifications',
            defaultColor: AppColors.primaryColor,
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            channelShowBadge: true,
            enableVibration: true,
            playSound: true,
          ),
          NotificationChannel(
            channelKey: 'promo_channel',
            channelName: 'Promotional notifications',
            channelDescription: 'Notification channel for promotions',
            defaultColor: AppColors.accentColor,
            ledColor: Colors.yellow,
            importance:
                NotificationImportance.High, // Changed to High for testing
            channelShowBadge: true,
            enableVibration: true,
            playSound: true,
          ),
          NotificationChannel(
            channelKey: 'cart_channel',
            channelName: 'Cart notifications',
            channelDescription: 'Notification channel for cart reminders',
            defaultColor: Colors.red,
            ledColor: Colors.red,
            importance: NotificationImportance.High,
            channelShowBadge: true,
            enableVibration: true,
            playSound: true,
          ),
        ],
      );

      debugPrint("🔔 AwesomeNotifications initialized: $result");

      // Request permission immediately
      final hasPermission = await requestNotificationPermission();
      debugPrint("🔔 Notification permission granted: $hasPermission");
    } catch (e) {
      debugPrint("⚠️ Error initializing notifications: $e");
    }
  }

  // Request notification permission
  Future<bool> requestNotificationPermission() async {
    debugPrint("🔔 Requesting notification permission");
    try {
      final result =
          await AwesomeNotifications().requestPermissionToSendNotifications();
      debugPrint("🔔 Permission request result: $result");
      return result;
    } catch (e) {
      debugPrint("⚠️ Error requesting notification permission: $e");
      return false;
    }
  }

  // Check if notification permission is granted
  Future<bool> isNotificationPermissionGranted() async {
    try {
      final result = await AwesomeNotifications().isNotificationAllowed();
      debugPrint("🔔 Notification permission status: $result");
      return result;
    } catch (e) {
      debugPrint("⚠️ Error checking notification permission: $e");
      return false;
    }
  }

  // Send a basic notification
  Future<bool> showBasicNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint("🔔 Creating basic notification: $title");
    try {
      final result = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          title: title,
          body: body,
          payload: payload != null ? {'data': payload} : null,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Message,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
      );
      debugPrint("🔔 Basic notification created: $result");
      return result;
    } catch (e) {
      debugPrint("⚠️ Error creating basic notification: $e");
      return false;
    }
  }

  // Send a promotional notification with an image
  Future<bool> showPromoNotification({
    required int id,
    required String title,
    required String body,
    required String imageUrl,
    String? payload,
  }) async {
    debugPrint("🔔 Creating promo notification: $title with image: $imageUrl");
    try {
      final result = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'promo_channel',
          title: title,
          body: body,
          bigPicture: imageUrl,
          notificationLayout: NotificationLayout.BigPicture,
          payload: payload != null ? {'data': payload} : null,
          category: NotificationCategory.Promo,
          wakeUpScreen: true,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
      );
      debugPrint("🔔 Promo notification created: $result");
      return result;
    } catch (e) {
      debugPrint("⚠️ Error creating promo notification: $e");
      return false;
    }
  }

  // Send a cart reminder notification
  Future<bool> showCartReminderNotification({
    required int id,
    required String title,
    required String body,
    required int itemCount,
    String? payload,
  }) async {
    debugPrint(
        "🔔 Creating cart reminder notification: $title for $itemCount items");
    try {
      final result = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'cart_channel',
          title: title,
          body: body,
          payload: payload != null ? {'data': payload} : null,
          notificationLayout: NotificationLayout.Default,
          badge: itemCount,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'VIEW_CART',
            label: 'Lihat Keranjang',
          ),
          NotificationActionButton(
            key: 'DISMISS',
            label: 'Tutup',
            isDangerousOption: true,
          ),
        ],
      );
      debugPrint("🔔 Cart reminder notification created: $result");
      return result;
    } catch (e) {
      debugPrint("⚠️ Error creating cart reminder notification: $e");
      return false;
    }
  }

  // Schedule a notification
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    debugPrint("⏰ Scheduling notification: $title for $scheduledDate");
    try {
      final result = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          title: title,
          body: body,
          payload: payload != null ? {'data': payload} : null,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
        schedule: NotificationCalendar.fromDate(date: scheduledDate),
      );
      debugPrint("⏰ Notification scheduled: $result");
      return result;
    } catch (e) {
      debugPrint("⚠️ Error scheduling notification: $e");
      return false;
    }
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    debugPrint("🔕 Cancelling notification #$id");
    await AwesomeNotifications().cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    debugPrint("🔕 Cancelling all notifications");
    await AwesomeNotifications().cancelAll();
  }
}
