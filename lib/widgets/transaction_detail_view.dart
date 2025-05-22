import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toko_game/models/transaction_model.dart';

class TransactionDetailView extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;

  const TransactionDetailView({
    Key? key,
    required this.transaction,
    this.onCancel,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format date
    final formattedDate =
        DateFormat('dd MMM yyyy, HH:mm').format(transaction.createdAt);

    // Get delivery type flags
    final isDigital = transaction.deliveryType.toLowerCase() == 'digital';
    final isPhysical = transaction.deliveryType.toLowerCase() == 'fisik';
    final isCombined = transaction.deliveryType.toLowerCase() == 'keduanya';

    // Status info
    final isPending = transaction.status.toLowerCase() == 'pending';
    final isCompleted = transaction.status.toLowerCase() == 'completed';
    final isCancelled = transaction.status.toLowerCase() == 'cancelled';

    // Status color
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

    // Format currency
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaction Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order details section
                  _buildInfoRow('Order ID', '#${transaction.id}'),
                  _buildInfoRow('Date', formattedDate),
                  _buildInfoRow('Payment Method', transaction.paymentMethod),
                  _buildStatusRow('Status', transaction.status, statusColor),

                  const Divider(height: 32),

                  // Items section
                  const Text(
                    'Items',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Game items list
                  ...transaction.games
                      .map((game) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Game image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: game.imageUrl.isNotEmpty
                                      ? Image.network(
                                          game.imageUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  _buildGameAvatar(game.title),
                                        )
                                      : _buildGameAvatar(game.title),
                                ),

                                const SizedBox(width: 12),

                                // Game details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        game.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Quantity: ${game.quantity}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        children: [
                                          // Only display type tag for combined delivery or when it matches the transaction delivery type
                                          if ((isCombined) ||
                                              (isDigital &&
                                                  game.type.toLowerCase() ==
                                                      'digital') ||
                                              (isPhysical &&
                                                  game.type.toLowerCase() ==
                                                      'fisik'))
                                            _buildGameTag(
                                                game.type, Colors.purple),

                                          if (game.platform.isNotEmpty)
                                            _buildGameTag(
                                                game.platform, Colors.blue),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Remove price display since it's showing Rp 0
                                // If you want to show prices later when fixed, replace this comment
                              ],
                            ),
                          ))
                      .toList(),

                  const Divider(height: 24),

                  // Total and delivery info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        currencyFormat.format(transaction.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Delivery type
                  _buildInfoRow('Delivery Type',
                      _formatDeliveryType(transaction.deliveryType)),

                  // Digital delivery info (Steam ID)
                  if ((isDigital || isCombined) && transaction.steamId != null)
                    _buildDigitalDeliveryInfo(transaction.steamId!),

                  // Physical delivery info (Address)
                  if ((isPhysical || isCombined) &&
                      transaction.shippingAddress != null)
                    _buildShippingAddressInfo(transaction.shippingAddress!),

                  const SizedBox(height: 24),

                  // Action buttons
                  if (!isCancelled && !isCompleted)
                    Row(
                      children: [
                        // Cancel button
                        if (isPending && onCancel != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onCancel,
                              icon: const Icon(Icons.cancel_outlined,
                                  color: Colors.red),
                              label: const Text('Cancel Order'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),

                        // Add spacing if both buttons are shown
                        if (isPending && onCancel != null && onEdit != null)
                          const SizedBox(width: 12),

                        // Edit button
                        if (onEdit != null)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit Order'),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                      ],
                    ),

                  // Add bottom padding to ensure no overflow
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
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

  // Helper method to build shipping address info section
  Widget _buildShippingAddressInfo(Map<String, dynamic> address) {
    final street = address['street'] ?? '';
    final city = address['city'] ?? '';
    final zipCode = address['zipCode'] ?? '';
    final country = address['country'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              const Text(
                'Shipping Address',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (street.isNotEmpty) Text(street),
                if (city.isNotEmpty || zipCode.isNotEmpty)
                  Text('$city ${zipCode.isNotEmpty ? zipCode : ""}'),
                if (country.isNotEmpty) Text(country),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build digital delivery info section
  Widget _buildDigitalDeliveryInfo(String steamId) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_download_outlined,
                size: 18,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              const Text(
                'Digital Delivery',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.gamepad_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Steam ID: $steamId',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build game avatar when image is not available
  Widget _buildGameAvatar(String title) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _getRandomColor(title),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          _getInitials(title),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  // Helper method to get initials from a string
  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';

    if (words.length == 1) {
      return words[0].substring(0, math.min(2, words[0].length)).toUpperCase();
    }

    return (words[0].isNotEmpty ? words[0][0] : '') +
        (words.length > 1 && words[1].isNotEmpty ? words[1][0] : '')
            .toUpperCase();
  }

  // Helper method to get a random color based on a string
  Color _getRandomColor(String input) {
    final int hash = input.codeUnits.fold(0, (prev, element) => prev + element);
    final hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.85).toColor();
  }

  // Helper to build info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build status row with color
  Widget _buildStatusRow(String label, String value, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          // Fix the status container to fit content width properly
          Wrap(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  value.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
