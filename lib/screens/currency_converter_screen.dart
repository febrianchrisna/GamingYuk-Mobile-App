import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:toko_game/providers/currency_provider.dart';
import 'package:toko_game/utils/constants.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double _result = 0;
  bool _hasConverted = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = '1000000'; // Initial value (1 million IDR)

    // Get the current app currency
    final currencyProvider =
        Provider.of<CurrencyProvider>(context, listen: false);
    _toCurrency = currencyProvider.selectedCurrency;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _convertCurrency() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final currencyProvider =
        Provider.of<CurrencyProvider>(context, listen: false);
    final rates = currencyProvider.currencyRates;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Convert to IDR first if not already IDR
    double amountInIdr;
    if (_fromCurrency == 'IDR') {
      amountInIdr = amount;
    } else {
      amountInIdr = amount / rates[_fromCurrency]!;
    }

    // Convert from IDR to target currency
    double convertedAmount;
    if (_toCurrency == 'IDR') {
      convertedAmount = amountInIdr;
    } else {
      convertedAmount = amountInIdr * rates[_toCurrency]!;
    }

    setState(() {
      _result = convertedAmount;
      _hasConverted = true;
    });
  }

  String _formatCurrency(double amount, String currencyCode) {
    final currencyProvider =
        Provider.of<CurrencyProvider>(context, listen: false);

    // Use the provider's formatting function
    if (currencyCode == 'IDR') {
      return currencyProvider.formatPrice(amount);
    }

    // Temporarily set provider's currency to format in a different currency
    late NumberFormat formatter;

    switch (currencyCode) {
      case 'IDR':
        formatter = NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        break;
      case 'USD':
        formatter = NumberFormat.currency(
            locale: 'en_US', symbol: '\$', decimalDigits: 2);
        break;
      case 'EUR':
        formatter = NumberFormat.currency(
            locale: 'de_DE', symbol: '€', decimalDigits: 2);
        break;
      case 'JPY':
        formatter = NumberFormat.currency(
            locale: 'ja_JP', symbol: '¥', decimalDigits: 0);
        break;
      case 'SGD':
        formatter = NumberFormat.currency(
            locale: 'en_SG', symbol: 'S\$', decimalDigits: 2);
        break;
      case 'GBP':
        formatter = NumberFormat.currency(
            locale: 'en_GB', symbol: '£', decimalDigits: 2);
        break;
      default:
        formatter = NumberFormat.currency(
            locale: 'en_US', symbol: '\$', decimalDigits: 2);
    }

    return formatter.format(amount);
  }

  void _applyToCurrency() {
    final currencyProvider =
        Provider.of<CurrencyProvider>(context, listen: false);
    currencyProvider.setCurrency(_toCurrency);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('App currency changed to $_toCurrency'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final rates = currencyProvider.currencyRates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Convert between currencies',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Enter an amount and select currencies to convert',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 24),

            // Amount input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.monetization_on_outlined),
              ),
            ),

            const SizedBox(height: 24),

            // Currency selection
            Row(
              children: [
                // From currency
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'From',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _fromCurrency,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: rates.keys.map((currency) {
                              return DropdownMenuItem<String>(
                                value: currency,
                                child: Text(currency),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _fromCurrency = value;
                                  if (_hasConverted) {
                                    _convertCurrency();
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Swap button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        final temp = _fromCurrency;
                        _fromCurrency = _toCurrency;
                        _toCurrency = temp;
                        if (_hasConverted) {
                          _convertCurrency();
                        }
                      });
                    },
                    icon: const Icon(Icons.swap_horiz),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                      foregroundColor: AppColors.primaryColor,
                    ),
                  ),
                ),

                // To currency
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'To',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _toCurrency,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: rates.keys.map((currency) {
                              return DropdownMenuItem<String>(
                                value: currency,
                                child: Text(currency),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _toCurrency = value;
                                  if (_hasConverted) {
                                    _convertCurrency();
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Convert button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _convertCurrency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Convert',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Result
            if (_hasConverted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _formatCurrency(
                          double.parse(_amountController.text), _fromCurrency),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(Icons.arrow_downward),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(_result, _toCurrency),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Exchange rate info
            if (_hasConverted)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Exchange Rate: 1 $_fromCurrency = ${_formatCurrency(rates[_toCurrency]! / rates[_fromCurrency]!, _toCurrency)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Apply currency to app button
            if (_hasConverted &&
                _toCurrency != currencyProvider.selectedCurrency)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 20),
                child: ElevatedButton.icon(
                  onPressed: _applyToCurrency,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('Apply $_toCurrency to entire app'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Current app currency
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current app currency: ${currencyProvider.selectedCurrency}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
