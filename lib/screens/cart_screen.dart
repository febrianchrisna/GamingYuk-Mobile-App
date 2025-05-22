import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:toko_game/providers/cart_provider.dart';
import 'package:toko_game/providers/notification_provider.dart';
import 'package:toko_game/screens/checkout_screen.dart';
import 'package:toko_game/utils/constants.dart';
import 'package:toko_game/utils/database_helper.dart';
import 'package:toko_game/widgets/price_text.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshCart();
  }

  Future<void> _refreshCart() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbHelper = DatabaseHelper();

      // First check the database structure and log the state
      debugPrint("Fixing database structure in cart screen...");
      await dbHelper.fixDatabaseStructure();

      debugPrint("Database state before refresh:");
      await dbHelper.logDatabaseState();

      // Then refresh the cart
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider
          .resetAndRefreshCart(); // Use resetAndRefreshCart for more reliable refresh

      // Log the state again after refresh
      debugPrint("Database state after refresh:");
      await dbHelper.logDatabaseState();
    } catch (e) {
      debugPrint("Error refreshing cart: $e");
      debugPrint("Stack trace: ${StackTrace.current}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Keranjang',
            onPressed: _refreshCart,
          ),
          if (cartItems.isNotEmpty)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'clear') {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Bersihkan Keranjang'),
                      content: const Text(
                          'Apakah Anda yakin ingin mengosongkan keranjang?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () {
                            cartProvider.clear();
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('Bersihkan'),
                        ),
                      ],
                    ),
                  );
                } else if (value == 'remind') {
                  // Send a cart reminder notification
                  final notificationProvider =
                      Provider.of<NotificationProvider>(context, listen: false);

                  // Add debug information
                  debugPrint(
                      "🔔 Cart reminder requested manually for ${cartItems.length} items");

                  notificationProvider
                      .sendCartReminderNotification(cartItems)
                      .then((success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Pengingat berhasil diatur untuk item di keranjangmu'
                            : 'Gagal mengirim pengingat, cek izin notifikasi'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text('Bersihkan Keranjang'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'remind',
                  child: ListTile(
                    leading: Icon(Icons.notifications_active),
                    title: Text('Remind Me Later'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Keranjang Anda kosong',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Jelajahi game dan tambahkan item ke keranjang Anda',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.home);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Jelajahi GamingYuk'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: item.imageUrl.isNotEmpty
                                        ? Image.network(
                                            item.imageUrl,
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const Icon(Icons.broken_image,
                                                    size: 64,
                                                    color: Colors.grey),
                                          )
                                        : const Icon(Icons.broken_image,
                                            size: 64, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        PriceText(
                                          priceInIdr: item.price,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tipe: ${item.type.capitalize()}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildQuantityButton(
                                    icon: Icons.remove,
                                    onTap: () {
                                      cartProvider
                                          .decreaseQuantity(item.gameId);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildQuantityButton(
                                    icon: Icons.add,
                                    onTap: () {
                                      cartProvider.addItem(
                                        gameId: item.gameId,
                                        title: item.title,
                                        price: item.price,
                                        imageUrl: item.imageUrl,
                                        type: item.type,
                                        platform: item.platform,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () {
                                      cartProvider.removeItem(item.gameId);
                                    },
                                    iconSize: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Total: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                              PriceText(
                                priceInIdr: cartProvider.totalAmount,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // Schedule a reminder notification if the user doesn't
                                  // complete checkout within 1 minute (for testing)
                                  final notificationProvider =
                                      Provider.of<NotificationProvider>(context,
                                          listen: false);

                                  debugPrint(
                                      "🔔 Setting up abandoned cart reminder");

                                  notificationProvider
                                      .scheduleAbandonedCartReminder(cartItems)
                                      .then((scheduled) {
                                    debugPrint(
                                        "⏰ Abandoned cart reminder ${scheduled ? 'scheduled' : 'failed to schedule'}");

                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CheckoutScreen(),
                                      ),
                                    );
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Checkout',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.grey[800],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? "${this[0].toUpperCase()}${substring(1)}" : '';
  }
}
