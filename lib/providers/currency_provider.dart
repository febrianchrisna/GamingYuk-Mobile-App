import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  String _selectedCurrency = 'IDR';

  // Currency rates relative to IDR
  final Map<String, double> _currencyRates = {
    'IDR': 1.0, // Indonesian Rupiah (base)
    'USD': 0.000064, // US Dollar
    'EUR': 0.000059, // Euro
    'JPY': 0.0096, // Japanese Yen
    'SGD': 0.000086, // Singapore Dollar
    'GBP': 0.000050, // British Pound
  };

  CurrencyProvider() {
    _loadCurrency();
  }

  String get selectedCurrency => _selectedCurrency;

  Map<String, double> get currencyRates => _currencyRates;

  // Load saved currency from preferences
  Future<void> _loadCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrency = prefs.getString('selected_currency');
      if (savedCurrency != null && _currencyRates.containsKey(savedCurrency)) {
        _selectedCurrency = savedCurrency;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading currency: $e');
    }
  }

  // Set currency and save to preferences
  Future<void> setCurrency(String currency) async {
    if (_currencyRates.containsKey(currency) && _selectedCurrency != currency) {
      _selectedCurrency = currency;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_currency', currency);
      } catch (e) {
        debugPrint('Error saving currency: $e');
      }

      notifyListeners();
    }
  }

  // Convert price from base IDR to selected currency
  double convertPrice(double priceInIdr) {
    if (_selectedCurrency == 'IDR') {
      return priceInIdr;
    }

    final rate = _currencyRates[_selectedCurrency] ?? 1.0;
    return priceInIdr * rate;
  }

  // Format price according to selected currency
  String formatPrice(double price) {
    late NumberFormat formatter;

    switch (_selectedCurrency) {
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
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    }

    return formatter.format(price);
  }
}
