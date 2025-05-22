import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:toko_game/providers/auth_provider.dart';
import 'package:toko_game/providers/cart_provider.dart';
import 'package:toko_game/screens/home_screen.dart';
import 'package:toko_game/services/api_service.dart';
import 'package:toko_game/utils/constants.dart';
import 'package:toko_game/widgets/custom_button.dart';
import 'package:toko_game/widgets/price_text.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  String _selectedPaymentMethod = 'Credit Card';
  final List<String> _paymentMethods = [
    'Credit Card',
    'PayPal',
    'Bank Transfer',
    'E-Wallet',
  ];

  // Physical delivery info
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();

  // Digital delivery info
  final _steamIdController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prefillUserInfo();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _steamIdController.dispose();
    super.dispose();
  }

  Future<void> _prefillUserInfo() async {
    final userData = Provider.of<AuthProvider>(context, listen: false).userData;

    if (userData != null) {
      // Load Steam ID for digital games
      if (userData['steamId'] != null) {
        _steamIdController.text = userData['steamId'];
      }

      // Direct field access for address instead of checking for nested 'address' object
      // These fields are at the root level in the user object based on your backend API
      if (userData['street'] != null) {
        _addressController.text = userData['street'];
      }

      if (userData['city'] != null) {
        _cityController.text = userData['city'];
      }

      if (userData['zipCode'] != null) {
        _zipCodeController.text = userData['zipCode'];
      }

      if (userData['country'] != null) {
        _countryController.text = userData['country'];
      }

      // Debug log to verify that the address info is loaded
      debugPrint(
          'Loaded profile address: Street: ${_addressController.text}, City: ${_cityController.text}, ZIP: ${_zipCodeController.text}, Country: ${_countryController.text}');
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user is logged in
      if (!authProvider.isAuthenticated) {
        throw Exception('You must be logged in to place an order');
      }

      // Determine delivery type
      String deliveryType;
      if (cartProvider.hasDigitalItems() && cartProvider.hasPhysicalItems()) {
        deliveryType = 'keduanya';
      } else if (cartProvider.hasPhysicalItems()) {
        deliveryType = 'fisik';
      } else {
        deliveryType = 'digital';
      }

      // Additional validation for required fields based on delivery type
      if ((deliveryType == 'fisik' || deliveryType == 'keduanya') &&
          (_addressController.text.isEmpty ||
              _cityController.text.isEmpty ||
              _zipCodeController.text.isEmpty ||
              _countryController.text.isEmpty)) {
        throw Exception(
            'Please complete all shipping address fields for physical items');
      }

      if ((deliveryType == 'digital' || deliveryType == 'keduanya') &&
          _steamIdController.text.isEmpty) {
        throw Exception('Steam ID is required for digital items');
      }

      // Prepare shipping address if needed
      Map<String, dynamic>? shippingAddress;
      if (deliveryType == 'fisik' || deliveryType == 'keduanya') {
        shippingAddress = {
          'street': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'zipCode': _zipCodeController.text.trim(),
          'country': _countryController.text.trim(),
        };
      }

      // Prepare steam ID if needed
      String? steamId;
      if (deliveryType == 'digital' || deliveryType == 'keduanya') {
        steamId = _steamIdController.text.trim();
      }

      // Prepare games data and ensure all fields are correctly formatted
      final gameItems = cartProvider.getItemsForCheckout();

      // Log request data for debugging
      debugPrint('Creating transaction with:');
      debugPrint('Delivery Type: $deliveryType');
      debugPrint('Payment Method: $_selectedPaymentMethod');
      debugPrint('Total Amount: ${cartProvider.totalAmount}');
      debugPrint('Games Count: ${gameItems.length}');
      if (steamId != null) debugPrint('Steam ID: $steamId');
      if (shippingAddress != null)
        debugPrint('Shipping Address: $shippingAddress');

      // Create transaction with structured data
      final result = await _apiService.createTransaction(
        games: gameItems,
        totalAmount: cartProvider.totalAmount,
        currency: 'IDR', // Always use IDR as the default currency
        paymentMethod: _selectedPaymentMethod,
        deliveryType: deliveryType,
        steamId: steamId,
        shippingAddress: shippingAddress,
      );

      // Response should be a map with transaction details
      debugPrint(
          'Transaction created successfully: ${result.toString().substring(0, math.min(100, result.toString().length))}...');

      // Clear cart after successful order
      cartProvider.clear();

      if (mounted) {
        // Show success message and navigate to home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      String errorMsg = e.toString();
      debugPrint('Checkout error: $errorMsg');

      // Parse specific error messages from the server
      if (errorMsg.contains('400')) {
        if (errorMsg.contains('insufficient stock')) {
          errorMsg =
              'Some items are out of stock. Please remove them and try again.';
        } else if (errorMsg.contains('address')) {
          errorMsg =
              'Please provide a complete shipping address for physical items.';
        } else if (errorMsg.contains('steamId')) {
          errorMsg = 'Steam ID is required for digital games.';
        } else if (errorMsg.contains('not available')) {
          errorMsg =
              'One or more items in your cart are not available in the selected format.';
        } else {
          errorMsg =
              'There was a problem with your order. Please check your information and try again.';
        }
      }

      // Handle auth errors
      if (errorMsg.contains('session has expired') ||
          errorMsg.contains('not have permission') ||
          errorMsg.contains('Authentication token not found')) {
        // Handle auth errors - navigate to login
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication error. Please log in again.';
        });

        // Show dialog asking user to log in again
        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Authentication Required'),
              content: Text(_errorMessage ?? errorMsg),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    // Log user out and redirect to login
                    authProvider.logout().then((_) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => false,
                      );
                    });
                  },
                  child: const Text('Login Again'),
                ),
              ],
            ),
          );
        }
      } else {
        // Handle regular errors
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
        });

        // Show error in a snackbar for better visibility
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'DISMISS',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.items;

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final hasDigitalItems = cartProvider.hasDigitalItems();
    final hasPhysicalItems = cartProvider.hasPhysicalItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order summary
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Order Summary',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Divider(),
                                  // Use the CartItem model properties directly
                                  ListView.builder(
                                    itemCount: cartItems.length,
                                    itemBuilder: (context, index) {
                                      final item = cartItems[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Row(
                                          children: [
                                            Text(
                                              '${item.quantity}x',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            PriceText(
                                              priceInIdr:
                                                  item.price * item.quantity,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      PriceText(
                                        priceInIdr: cartProvider.totalAmount,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Payment method
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Payment Method',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _selectedPaymentMethod,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    items: _paymentMethods.map((method) {
                                      return DropdownMenuItem<String>(
                                        value: method,
                                        child: Text(method),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedPaymentMethod = value;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Digital delivery information
                          if (hasDigitalItems)
                            Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.cloud_download,
                                          color: AppColors.primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Digital Delivery',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _steamIdController,
                                      decoration: const InputDecoration(
                                        labelText: 'Steam ID',
                                        border: OutlineInputBorder(),
                                        hintText:
                                            'Enter your Steam ID for digital games',
                                      ),
                                      validator: hasDigitalItems
                                          ? (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Steam ID is required for digital games';
                                              }
                                              return null;
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Physical delivery information
                          if (hasPhysicalItems)
                            Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.local_shipping_outlined,
                                          color: AppColors.primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Shipping Address',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _addressController,
                                      decoration: const InputDecoration(
                                        labelText: 'Street Address',
                                        border: OutlineInputBorder(),
                                        hintText: 'Enter your street address',
                                      ),
                                      validator: hasPhysicalItems
                                          ? (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Street address is required';
                                              }
                                              return null;
                                            }
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _cityController,
                                            decoration: const InputDecoration(
                                              labelText: 'City',
                                              border: OutlineInputBorder(),
                                              hintText: 'Enter your city',
                                            ),
                                            validator: hasPhysicalItems
                                                ? (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'City is required';
                                                    }
                                                    return null;
                                                  }
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _zipCodeController,
                                            decoration: const InputDecoration(
                                              labelText: 'ZIP Code',
                                              border: OutlineInputBorder(),
                                              hintText: 'Enter ZIP code',
                                            ),
                                            validator: hasPhysicalItems
                                                ? (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'ZIP code is required';
                                                    }
                                                    return null;
                                                  }
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _countryController,
                                      decoration: const InputDecoration(
                                        labelText: 'Country',
                                        border: OutlineInputBorder(),
                                        hintText: 'Enter your country',
                                      ),
                                      validator: hasPhysicalItems
                                          ? (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Country is required';
                                              }
                                              return null;
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Error message
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[300]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Place order button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((255 * 0.05).toInt()),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: CustomButton(
                      text: 'Place Order',
                      onPressed: _placeOrder,
                      isLoading: _isLoading,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
