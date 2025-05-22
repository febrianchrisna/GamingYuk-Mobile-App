import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:toko_game/models/game_model.dart';
import 'package:toko_game/providers/cart_provider.dart';
import 'package:toko_game/providers/notification_provider.dart'; // Add this import
import 'package:toko_game/services/api_service.dart';
import 'package:toko_game/utils/constants.dart';
import 'package:toko_game/widgets/custom_button.dart';
import 'package:toko_game/widgets/loading_widget.dart';
import 'package:toko_game/widgets/price_text.dart';

class GameDetailScreen extends StatefulWidget {
  final String gameId;

  const GameDetailScreen({
    super.key,
    required this.gameId,
  });

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final ApiService _apiService = ApiService();
  GameModel? _game;
  bool _isLoading = true;
  String? _error;
  String _selectedType = 'digital'; // default to digital

  @override
  void initState() {
    super.initState();
    _loadGameDetails();
  }

  Future<void> _loadGameDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final game = await _apiService.getGameById(widget.gameId);

      setState(() {
        _game = game;
        _isLoading = false;

        // Set initial type based on availability
        if (game.hasDigital) {
          _selectedType = 'digital';
        } else if (game.hasFisik) {
          _selectedType = 'physical';
        }
      });
    } catch (e) {
      setState(() {
        // Provide a user-friendly error message
        if (e.toString().contains('Game not found')) {
          _error =
              'Game not found. It may have been removed or is unavailable.';
        } else if (e.toString().contains('404')) {
          _error =
              'Unable to find the requested game. Please try another game.';
        } else {
          _error =
              'Failed to load game details. Please check your internet connection.';
        }
        print('Detailed error: $e');
        _isLoading = false;
      });
    }
  }

  // Completely rewritten to be more reliable
  void _addToCart() {
    if (_game == null) {
      print("Cannot add null game to cart");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Game information is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print("\n===== GAME DETAIL: ADD TO CART =====");
      print("Game ID: ${_game!.id}");
      print("Game Title: ${_game!.title}");
      print("Game Price: ${_game!.price}");
      print("Selected Type: $_selectedType");

      // Safety checks for all values
      final String safeId = _game!.id.isNotEmpty ? _game!.id : "unknown_game";
      final String safeTitle =
          _game!.title.isNotEmpty ? _game!.title : "Unknown Game";
      final double safePrice = _game!.price > 0 ? _game!.price : 0.0;
      final String safeImageUrl =
          _game!.imageUrl.isNotEmpty ? _game!.imageUrl : "";
      final String safeType =
          _selectedType.isNotEmpty ? _selectedType : "digital";
      final String safePlatform =
          _game!.platform.isNotEmpty ? _game!.platform : "Unknown";

      // Get cart provider
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // Add to cart
      cartProvider.addItem(
        gameId: safeId,
        title: safeTitle,
        price: safePrice,
        imageUrl: safeImageUrl,
        type: safeType,
        platform: safePlatform,
      );

      // Show success message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${_game!.title} added to cart'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.cart);
            },
          ),
        ),
      );

      print("===== END GAME DETAIL: ADD TO CART =====\n");
    } catch (e) {
      print("ERROR adding to cart in game detail: $e");
      print("Stack trace: ${StackTrace.current}");

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error ?? 'An error occurred',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadGameDetails,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? _buildErrorView()
              : _buildGameDetails(),
    );
  }

  Widget _buildGameDetails() {
    if (_game == null) return const SizedBox.shrink();

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return CustomScrollView(
      slivers: [
        // App Bar with game image
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(
              tag: 'game-${_game!.id}',
              child: Stack(
                fit: StackFit.expand,
                children: [
                  (_game!.imageUrl != null && _game!.imageUrl.isNotEmpty)
                      ? Image.network(
                          _game!.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child:
                                    Icon(Icons.image_not_supported, size: 60),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 60),
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Game details
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and platform
                Text(
                  _game!.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _game!.platform,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _game!.category,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Price and publisher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PriceText(
                      priceInIdr: _game!.price,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Text(
                      'Publisher: ${_game!.publisher}',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Available types
                if (_game!.hasDigital || _game!.hasFisik)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Types',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_game!.hasDigital)
                            _buildTypeOption('Digital', 'digital'),
                          const SizedBox(width: 16),
                          if (_game!.hasFisik)
                            _buildTypeOption('Physical', 'physical'),
                        ],
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Release date
                Text(
                  'Release Date: ${DateFormat('dd MMMM yyyy').format(_game!.releaseDate)}',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 24),

                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _game!.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // Add to cart button
                CustomButton(
                  text: 'Add to Cart',
                  onPressed: _addToCart,
                  icon: Icons.shopping_cart,
                ),

                // Add a reminder button for new games
                if (_isNewRelease())
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: OutlinedButton.icon(
                      onPressed: _scheduleReleaseNotification,
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Get Notified on Release'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 0),
                        side: const BorderSide(color: AppColors.primaryColor),
                        foregroundColor: AppColors.primaryColor,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption(String label, String value) {
    final isSelected = _selectedType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey[400]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value == 'digital' ? Icons.cloud_download : Icons.inventory_2,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Check if game is a new release or coming soon
  bool _isNewRelease() {
    if (_game == null) return false;

    final now = DateTime.now();
    final releaseDate = _game!.releaseDate;

    // Check if the game is released in the future or within the last 7 days
    return releaseDate.isAfter(now) || now.difference(releaseDate).inDays <= 7;
  }

  // Schedule a notification for game release
  void _scheduleReleaseNotification() async {
    if (_game == null) return;

    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    // If the game is already released, send a notification immediately
    // Otherwise schedule it for the release date
    final now = DateTime.now();
    DateTime notificationTime;

    if (_game!.releaseDate.isAfter(now)) {
      // Schedule for release date
      notificationTime = _game!.releaseDate;
    } else {
      // Send a notification in 5 seconds (for demo purposes)
      notificationTime = DateTime.now().add(const Duration(seconds: 5));
    }

    await notificationProvider.scheduleNewReleaseReminder(
      _game!.title,
      notificationTime,
      _game!.id,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _game!.releaseDate.isAfter(now)
              ? 'You\'ll be notified when ${_game!.title} releases!'
              : 'Notification set for ${_game!.title}!',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}
