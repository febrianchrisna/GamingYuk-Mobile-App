import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:toko_game/models/transaction_model.dart';
import 'package:toko_game/providers/auth_provider.dart';
import 'package:toko_game/providers/time_zone_provider.dart';
import 'package:toko_game/providers/currency_provider.dart';
import 'package:toko_game/services/api_service.dart';
import 'package:toko_game/utils/constants.dart';
import 'package:toko_game/widgets/transaction_detail_view.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) {
        throw Exception('You must be logged in to view transaction history');
      }

      final transactionsData = await _apiService.getTransactions();

      if (!mounted) return;

      final List<TransactionModel> parsedTransactions = transactionsData
          .map((json) => TransactionModel.fromJson(json))
          .toList();

      // Sort transactions by date (newest first)
      parsedTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _transactions = parsedTransactions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      // Handle authentication errors
      if (_errorMessage!.contains('must be logged in') ||
          _errorMessage!.contains('session has expired') ||
          _errorMessage!.contains('Authentication token not found')) {
        _showAuthErrorDialog();
      }
    }
  }

  void _showAuthErrorDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Authentication Required'),
        content: Text(
            _errorMessage ?? 'You need to log in to view your order history.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
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

  Future<void> _viewTransactionDetails(TransactionModel transaction) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: TransactionDetailView(
          transaction: transaction,
          onCancel: transaction.status.toLowerCase() == 'pending'
              ? () => _cancelTransaction(transaction)
              : null,
          onEdit: _canEditTransaction(transaction)
              ? () => _editTransaction(transaction)
              : null,
        ),
      ),
    );
  }

  bool _canEditTransaction(TransactionModel transaction) {
    final status = transaction.status.toLowerCase();
    return status != 'completed' && status != 'cancelled';
  }

  Future<void> _cancelTransaction(TransactionModel transaction) async {
    Navigator.of(context).pop(); // Close the modal

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
            'Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.deleteTransaction(transaction.id);

      // Refresh transactions list
      await _fetchTransactions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to cancel order: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editTransaction(TransactionModel transaction) async {
    // Close the details modal
    Navigator.of(context).pop();

    // Create form controllers
    final _paymentMethodController =
        TextEditingController(text: transaction.paymentMethod);
    final _steamIdController =
        TextEditingController(text: transaction.steamId ?? '');

    // Address controllers
    final _streetController = TextEditingController(
      text: transaction.shippingAddress?['street'] ?? '',
    );
    final _cityController = TextEditingController(
      text: transaction.shippingAddress?['city'] ?? '',
    );
    final _zipCodeController = TextEditingController(
      text: transaction.shippingAddress?['zipCode'] ?? '',
    );
    final _countryController = TextEditingController(
      text: transaction.shippingAddress?['country'] ?? '',
    );

    // Payment method options
    final List<String> paymentMethods = [
      'Credit Card',
      'PayPal',
      'Bank Transfer',
      'E-Wallet',
    ];

    // Determine if this is a digital, physical, or both type of transaction
    final isDigital = transaction.deliveryType.toLowerCase() == 'digital';
    final isPhysical = transaction.deliveryType.toLowerCase() == 'fisik';
    final isBoth = transaction.deliveryType.toLowerCase() == 'keduanya';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Order #${transaction.id}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Method dropdown
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentMethodController.text.isNotEmpty
                    ? _paymentMethodController.text
                    : paymentMethods.first,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: paymentMethods.map((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _paymentMethodController.text = value;
                  }
                },
              ),

              const SizedBox(height: 16),

              // Steam ID (for digital or both)
              if (isDigital || isBoth) ...[
                Row(
                  children: [
                    const Icon(Icons.cloud_download, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Digital Delivery Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _steamIdController,
                  decoration: const InputDecoration(
                    labelText: 'Steam ID',
                    border: OutlineInputBorder(),
                    hintText: 'Enter your Steam ID for digital games',
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Shipping Address (for physical or both)
              if (isPhysical || isBoth) ...[
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Shipping Address',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _streetController,
                  decoration: const InputDecoration(
                    labelText: 'Street Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _zipCodeController,
                        decoration: const InputDecoration(
                          labelText: 'ZIP Code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Prepare data map for the API update
              final updateData = <String, dynamic>{
                'paymentMethod': _paymentMethodController.text,
              };

              // Only add Steam ID if it's a digital or both type
              if (isDigital || isBoth) {
                updateData['steamId'] = _steamIdController.text;
              }

              // Only add shipping address if it's a physical or both type
              if (isPhysical || isBoth) {
                // CHANGE: Add address fields directly to the update data instead of nesting
                updateData['street'] = _streetController.text;
                updateData['city'] = _cityController.text;
                updateData['zipCode'] = _zipCodeController.text;
                updateData['country'] = _countryController.text;
              }

              Navigator.of(context).pop(updateData);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    // If dialog was dismissed without result
    if (result == null) return;

    setState(() => _isLoading = true);

    try {
      // Call the API to update the transaction
      await _apiService.updateTransaction(transaction.id, result);

      // Refresh transactions list
      await _fetchTransactions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to update order: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchTransactions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Orders',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchTransactions,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Orders Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your order history will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTransactions,
      child: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: _transactions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return _buildTransactionCard(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final timeZoneProvider = Provider.of<TimeZoneProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    // Convert transaction date to selected time zone
    final utcDate = transaction.createdAt.toUtc();
    final offset =
        timeZoneProvider.timeZoneOffsets[timeZoneProvider.selectedTimeZone] ??
            7;
    final localDate = utcDate.add(Duration(hours: offset));

    // Get status color
    Color statusColor;
    switch (transaction.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.amber;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.blue;
    }

    final hasMultipleItems = transaction.games.length > 1;
    final primaryGame = transaction.games.first;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and Date row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${transaction.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy').format(localDate),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Game items
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game icon/avatar with image support
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: primaryGame.imageUrl.isNotEmpty
                        ? Image.network(
                            primaryGame.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to colored avatar with initials on error
                              return Container(
                                width: 60,
                                height: 60,
                                color: _getColorFromName(primaryGame.title),
                                child: Center(
                                  child: Text(
                                    _getInitials(primaryGame.title),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        // Fallback to colored avatar with initials if no image URL
                        : Container(
                            width: 60,
                            height: 60,
                            color: _getColorFromName(primaryGame.title),
                            child: Center(
                              child: Text(
                                _getInitials(primaryGame.title),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(width: 12),

                  // Game details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          primaryGame.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        if (hasMultipleItems)
                          Text(
                            '+ ${transaction.games.length - 1} more item${transaction.games.length > 2 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),

                        const SizedBox(height: 4),

                        // Delivery type
                        Row(
                          children: [
                            Icon(
                              transaction.deliveryType.toLowerCase() ==
                                      'digital'
                                  ? Icons.cloud_download_outlined
                                  : Icons.local_shipping_outlined,
                              size: 14,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDeliveryType(transaction.deliveryType),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Status and total row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transaction.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // Total amount with currency conversion
                  Text(
                    currencyProvider.formatPrice(
                        currencyProvider.convertPrice(transaction.totalAmount)),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDeliveryType(String type) {
    switch (type.toLowerCase()) {
      case 'digital':
        return 'Digital Delivery';
      case 'fisik':
        return 'Physical Delivery';
      case 'keduanya':
        return 'Digital & Physical';
      default:
        return 'Delivery';
    }
  }

  // Helper method to get initials from game title
  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, math.min(2, words[0].length)).toUpperCase();
    }

    return (words[0].isNotEmpty ? words[0][0] : '') +
        (words.length > 1 && words[1].isNotEmpty ? words[1][0] : '')
            .toUpperCase();
  }

  // Helper method to get color based on game name
  Color _getColorFromName(String name) {
    if (name.isEmpty) return Colors.grey;

    // Simple hash of the name to generate a color
    final int hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    final hue = (hash % 360).toDouble();

    return HSVColor.fromAHSV(1.0, hue, 0.8, 0.8).toColor();
  }
}
