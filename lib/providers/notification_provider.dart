import 'dart:async';
import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:toko_game/models/cart_model.dart';
import 'package:toko_game/models/game_model.dart';
import 'package:toko_game/services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  bool _initialized = false;
  final Random _random = Random();
  Timer? _inactivityTimer;
  Timer? _periodicPromotionTimer;
  Timer? _abandonedCartTimer;
  DateTime? _lastAppUseTime;

  // Track if background notifications are enabled
  bool _backgroundNotificationsEnabled = true;

  NotificationProvider() {
    _init();
  }

  // Initialize notification service
  Future<void> _init() async {
    if (!_initialized) {
      try {
        await _notificationService.initialize();
        _initialized = true;

        // Start monitoring app activity
        _startInactivityMonitoring();

        // Schedule periodic promotion notifications
        _schedulePeriodicPromotions();

        debugPrint("🔔 Notification service initialized successfully");
      } catch (e) {
        debugPrint("⚠️ Error initializing notification service: $e");
      }
    }
  }

  // Start monitoring app inactivity to trigger cart reminders
  void _startInactivityMonitoring() {
    _lastAppUseTime = DateTime.now();

    // Cancel existing timers if any
    _inactivityTimer?.cancel();

    // Create a new timer that checks inactivity after 1 minute (for testing)
    _inactivityTimer = Timer.periodic(
        const Duration(minutes: 4), // Check every 1 minute for testing
        (timer) {
      final now = DateTime.now();
      final lastUse = _lastAppUseTime ?? now;

      // If app hasn't been used for 1 minute and there are items in cart
      if (now.difference(lastUse).inMinutes >= 4) {
        debugPrint("🔔 Checking for cart items after inactivity");
        _checkAndSendCartReminder();
      }
    });

    debugPrint("⏰ Inactivity monitoring started with 1 minute duration");
  }

  // Schedule periodic promotions
  void _schedulePeriodicPromotions() {
    _periodicPromotionTimer?.cancel();

    // Send a promotion every 1 minute for testing
    _periodicPromotionTimer = Timer.periodic(const Duration(minutes: 4), (_) {
      if (_backgroundNotificationsEnabled) {
        debugPrint("🔔 Sending periodic promotion notification");
        _sendRandomPromotion();
      }
    });

    debugPrint(
        "⏰ Promotional notification timer started with 1 minute interval");
  }

  // Update the last app use time
  void updateAppActivity() {
    _lastAppUseTime = DateTime.now();
    debugPrint("⏰ App activity updated at: $_lastAppUseTime");
  }

  // Check if there are items in cart and send reminder if needed
  Future<void> _checkAndSendCartReminder() async {
    try {
      // This would normally be connected to the CartProvider
      // For testing, we'll always assume there are items
      bool hasItemsInCart = true; // For testing purposes

      if (hasItemsInCart && _backgroundNotificationsEnabled) {
        // Menghasilkan ID acak antara 0-999 untuk setiap notifikasi
        // ID ini berfungsi sebagai pengenal unik untuk setiap notifikasi
        // yang memungkinkan sistem untuk:
        // 1. Membedakan antara notifikasi yang berbeda
        // 2. Memperbarui notifikasi yang sudah ada (jika ID-nya sama)
        // 3. Menghapus notifikasi tertentu berdasarkan ID
        final result = await _notificationService.showBasicNotification(
          id: _random.nextInt(1000), // ID acak untuk notifikasi
          title: 'Kamu punya item di keranjang! 🛒',
          body:
              'Jangan lupa untuk menyelesaikan pembelianmu. Barang-barangmu sedang menunggu!',
          payload: 'cart_reminder_auto',
        );

        if (result) {
          debugPrint("✅ Cart reminder notification sent successfully");
        } else {
          debugPrint("❌ Failed to send cart reminder notification");
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error sending cart reminder: $e");
    }
  }

  // Send a random promotion
  Future<void> _sendRandomPromotion() async {
    try {
      // In real app, get these from API or database
      final promos = [
        {
          'title': 'Weekend Sale!',
          'discount': 25,
          'gameId': 'game1',
          'gameName': 'Call of Adventure',
          'imageUrl':
              'https://cf.geekdo-images.com/oz_C4Hwf1Hb6KHt6KTxJJA__itemrep/img/p5eKp_s2dmS1y9iM0xKoV0J2mNw=/fit-in/246x300/filters:strip_icc()/pic4165094.jpg'
        },
        {
          'title': 'Flash Sale!',
          'discount': 50,
          'gameId': 'game2',
          'gameName': 'NFS Unbound',
          'imageUrl':
              'https://upload.wikimedia.org/wikipedia/id/d/db/Need_for_Speed_Unbound.png'
        },
        {
          'title': 'Special Offer!',
          'discount': 30,
          'gameId': 'game3',
          'gameName': 'Expedition 33',
          'imageUrl':
              'https://image.api.playstation.com/vulcan/ap/rnd/202501/2217/15dd9f9368aa87c9b2dcaf58e1856e8cca01b6e595331858.jpg'
        },
      ];

      if (promos.isNotEmpty) {
        final promo = promos[_random.nextInt(promos.length)];
        bool result;

        // Alternate between different notification types
        if (_random.nextBool()) {
          result = await _sendDiscountNotification(
            promo['gameName'] as String,
            promo['discount'] as int,
            promo['gameId'] as String,
          );
        } else {
          result = await _sendGamePromotionNotification(
            promo['gameName'] as String,
            promo['imageUrl'] as String,
            promo['gameId'] as String,
          );
        }

        if (result) {
          debugPrint("✅ Promotional notification sent successfully");
        } else {
          debugPrint("❌ Failed to send promotional notification");
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error sending promotional notification: $e");
    }
  }

  // Private method to send discount notification
  Future<bool> _sendDiscountNotification(
    String gameTitle,
    int discountPercent,
    String gameId,
  ) async {
    return await _notificationService.showBasicNotification(
      id: _random.nextInt(1000),
      title: 'Penawaran Terbatas!',
      body:
          'Dapatkan diskon $discountPercent% untuk $gameTitle. Segera sebelum promo berakhir!',
      payload: 'discount:$gameId',
    );
  }

  // Private method to send game promotion notification
  Future<bool> _sendGamePromotionNotification(
    String gameTitle,
    String imageUrl,
    String gameId,
  ) async {
    return await _notificationService.showPromoNotification(
      id: _random.nextInt(1000),
      title: 'Game Baru!',
      body: 'Cek $gameTitle, sekarang tersedia di GamingYuk!',
      imageUrl: imageUrl,
      payload: 'game:$gameId',
    );
  }

  // Set whether background notifications are enabled
  void setBackgroundNotifications(bool enabled) {
    _backgroundNotificationsEnabled = enabled;

    if (enabled) {
      _startInactivityMonitoring();
      _schedulePeriodicPromotions();
      debugPrint("🔔 Background notifications enabled");
    } else {
      _inactivityTimer?.cancel();
      _periodicPromotionTimer?.cancel();
      debugPrint("🔕 Background notifications disabled");
    }

    notifyListeners();
  }

  // Get background notifications status
  bool get backgroundNotificationsEnabled => _backgroundNotificationsEnabled;

  // Schedule abandoned cart reminder (after 1 minute of no checkout for testing)
  Future<bool> scheduleAbandonedCartReminder(List<CartItem> cartItems) async {
    if (cartItems.isEmpty) return false;

    // Cancel existing timer if any
    _abandonedCartTimer?.cancel();

    // For testing, schedule a notification to appear 1 minute from now
    debugPrint("⏰ Scheduling abandoned cart reminder in 1 minute");
    _abandonedCartTimer = Timer(const Duration(minutes: 5), () async {
      try {
        final result = await _notificationService.showCartReminderNotification(
          id: 9000 + _random.nextInt(1000),
          title: 'Selesaikan Pembelianmu!',
          body:
              'Keranjangmu sedang menunggu. Selesaikan pembelian untuk mulai bermain!',
          itemCount: cartItems.length,
          payload: 'abandoned_cart',
        );

        if (result) {
          debugPrint("✅ Abandoned cart notification sent successfully");
        } else {
          debugPrint("❌ Failed to send abandoned cart notification");
        }
      } catch (e) {
        debugPrint("⚠️ Error sending abandoned cart notification: $e");
      }
    });

    return true;
  }

  // Send a welcome notification
  Future<bool> sendWelcomeNotification(String username) async {
    try {
      debugPrint("🔔 Sending welcome notification to $username");
      final result = await _notificationService.showBasicNotification(
        id: _random.nextInt(1000),
        title: 'Selamat datang di GamingYuk! 🎮',
        body:
            'Hai $username, selamat datang di toko game terbaik. Jelajahi game-game terbaru kami!',
        payload: 'welcome',
      );

      if (result) {
        debugPrint("✅ Welcome notification sent successfully");
      } else {
        debugPrint("❌ Failed to send welcome notification");
      }

      return result;
    } catch (e) {
      debugPrint("⚠️ Error sending welcome notification: $e");
      return false;
    }
  }

  // Send a cart reminder notification
  Future<bool> sendCartReminderNotification(List<CartItem> cartItems) async {
    if (cartItems.isEmpty) return false;

    try {
      String itemText = cartItems.length > 1
          ? '${cartItems.length} items'
          : '${cartItems[0].title}';

      debugPrint("🔔 Sending cart reminder notification for $itemText");
      final result = await _notificationService.showCartReminderNotification(
        id: _random.nextInt(1000),
        title: 'Item menunggu di keranjangmu!',
        body:
            'Kamu memiliki $itemText di keranjang. Selesaikan pembelianmu sekarang!',
        itemCount: cartItems.length,
        payload: 'cart_reminder',
      );

      if (result) {
        debugPrint("✅ Cart reminder notification sent successfully");
      } else {
        debugPrint("❌ Failed to send cart reminder notification");
      }

      return result;
    } catch (e) {
      debugPrint("⚠️ Error sending cart reminder notification: $e");
      return false;
    }
  }

  // Schedule a notification for game release
  Future<bool> scheduleNewReleaseReminder(
    String gameTitle,
    DateTime releaseDate,
    String gameId,
  ) async {
    try {
      // For testing, set the notification to 1 minute from now
      final notificationTime = DateTime.now().add(const Duration(minutes: 10));
      debugPrint(
          "⏰ Scheduling game release notification for $gameTitle at $notificationTime");

      final result = await _notificationService.scheduleNotification(
        id: _random.nextInt(1000),
        title: 'Pengingat Rilis Game',
        body:
            '$gameTitle sekarang tersedia! Jadilah yang pertama memainkannya.',
        scheduledDate: notificationTime, // Use current time + 1 min for testing
        payload: 'release:$gameId',
      );

      if (result) {
        debugPrint("✅ Game release notification scheduled successfully");
      } else {
        debugPrint("❌ Failed to schedule game release notification");
      }

      return result;
    } catch (e) {
      debugPrint("⚠️ Error scheduling game release notification: $e");
      return false;
    }
  }

  // Check if notification permissions are granted
  Future<bool> isPermissionGranted() async {
    final result = await _notificationService.isNotificationPermissionGranted();
    debugPrint("🔔 Notification permission granted: $result");
    return result;
  }

  // Request notification permissions
  Future<bool> requestNotificationPermission() async {
    debugPrint("🔔 Requesting notification permission");
    final result = await _notificationService.requestNotificationPermission();
    debugPrint("🔔 Notification permission request result: $result");
    return result;
  }

  // Process received notifications
  Future<void> processReceivedAction(ReceivedAction receivedAction) async {
    final payload = receivedAction.payload?['data'];
    final actionKey = receivedAction.buttonKeyPressed;

    debugPrint(
        "🔔 Processing notification action: $actionKey, Payload: $payload");

    if (actionKey == 'VIEW_CART') {
      // Logic to navigate to cart will be handled in notification_listener.dart
      debugPrint("👆 User clicked View Cart button");
    }

    // Other action processing logic here
    notifyListeners();
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    debugPrint("🔕 Cancelling all notifications");
    await _notificationService.cancelAllNotifications();
  }

  // Clean up resources
  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _periodicPromotionTimer?.cancel();
    _abandonedCartTimer?.cancel();
    debugPrint("♻️ NotificationProvider disposed - timers cancelled");
    super.dispose();
  }
}
