import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:toko_game/utils/constants.dart';
import 'package:toko_game/utils/secure_storage.dart';
import 'package:toko_game/utils/database_helper.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  Map<String, dynamic>? _userData;
  final DatabaseHelper _dbHelper;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  Map<String, dynamic>? get userData => _userData;

  AuthProvider({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper {
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final token = await SecureStorage.getTokenAsync();
      if (token != null) {
        _userData = await SecureStorage.getUserDataAsync();
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      print('Auth check error: $e');
    }
  }

  // Add this method to verify API connectivity
  Future<bool> _checkApiConnection() async {
    try {
      // Try a simple GET request to check if API is reachable
      final response = await http
          .get(Uri.parse(ApiConstants.baseUrl))
          .timeout(const Duration(seconds: 5));

      print('API check status: ${response.statusCode}');
      return response.statusCode <
          500; // Consider any non-server error as "connected"
    } catch (e) {
      print('API connection check failed: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      _isLoading = false;
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          // Match the actual API response structure
          // API returns "accessToken" and "safeUserData" instead of "token" and "user"
          final token = data['accessToken'];
          final userData = data['safeUserData'];

          if (token == null) {
            _error = 'Invalid response: Token is missing';
            notifyListeners();
            return false;
          }

          if (userData == null) {
            _error = 'Invalid response: User data is missing';
            notifyListeners();
            return false;
          }

          // Save token and user data
          await SecureStorage.saveToken(token);
          await SecureStorage.saveUserData(userData);

          _userData = userData;
          _isAuthenticated = true;
          notifyListeners();
          return true;
        } catch (e) {
          print('Error parsing login response: $e');
          _error = 'Invalid response format from server';
          notifyListeners();
          return false;
        }
      } else {
        print('Login failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');

        try {
          final data = json.decode(response.body);
          _error = data['message'] ?? 'Failed to login. Please try again.';
        } catch (e) {
          _error = 'Failed to login. Please try again.';
        }
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      if (e is SocketException) {
        _error = 'No internet connection. Please check your network settings.';
      } else if (e is TimeoutException) {
        _error =
            'Server is taking too long to respond. Please try again later.';
      } else if (e is http.ClientException) {
        _error = 'Connection issue. Please check your internet and try again.';
      } else {
        _error = 'An unexpected error occurred. Please try again.';
      }
      print('Login error: $e'); // For debugging
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Use development mode if enabled
    if (ApiConstants.devMode) {
      print('DEVELOPMENT MODE: Using local registration');
      await Future.delayed(
          const Duration(seconds: 1)); // Simulate network delay

      _isLoading = false;

      // Always succeed in dev mode
      _error = null;
      notifyListeners();
      return true;
    }

    // First check if API is reachable
    final apiAvailable = await _checkApiConnection();
    if (!apiAvailable) {
      _isLoading = false;
      _error =
          'Cannot connect to server. Please check your internet connection or try again later.';
      notifyListeners();
      return false;
    }

    try {
      // Log request details (for debugging)
      final apiUrl = '${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}';
      print('Attempting registration to: $apiUrl');

      // Add timeout to prevent hanging on network issues
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'username': username,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      _isLoading = false;

      if (response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        print('Registration failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');

        try {
          final data = json.decode(response.body);
          _error = data['message'] ?? 'Registration failed. Please try again.';
        } catch (e) {
          _error = 'Registration failed. Please try again.';
        }
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      if (e is SocketException) {
        _error = 'No internet connection. Please check your network settings.';
      } else if (e is TimeoutException) {
        _error =
            'Server is taking too long to respond. Please try again later.';
      } else if (e is http.ClientException) {
        _error = 'Connection issue. Please check your internet and try again.';
      } else {
        _error = 'An unexpected error occurred. Please try again.';
      }
      print('Registration error: $e'); // For debugging
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get token asynchronously
      final token = await SecureStorage.getTokenAsync();
      if (token == null) {
        _error = 'Authentication token missing. Please login again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('Updating profile with data: $updateData');

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profileEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Profile update response: $data');

        // Update user data based on response format
        if (data['data'] != null) {
          _userData = Map<String, dynamic>.from(data['data']);
          await SecureStorage.saveUserData(_userData!);
        } else if (data['user'] != null) {
          _userData = Map<String, dynamic>.from(data['user']);
          await SecureStorage.saveUserData(_userData!);
        } else {
          // Fallback if the response format is different
          final updatedData = Map<String, dynamic>.from(_userData ?? {});
          updateData.forEach((key, value) {
            updatedData[key] = value;
          });
          _userData = updatedData;
          await SecureStorage.saveUserData(_userData!);
        }

        notifyListeners();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Failed to update profile.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error updating profile: $e');
      _isLoading = false;
      _error = 'Network error. Please check your connection.';
      notifyListeners();
      return false;
    }
  }

  // Helper method to recursively process all ID fields and ensure they're strings
  void _processAllIdFields(dynamic data) {
    if (data is Map<String, dynamic>) {
      data.forEach((key, value) {
        if (key == 'id' || key.endsWith('Id') || key.endsWith('_id')) {
          data[key] = value?.toString();
        } else if (value is Map || value is List) {
          _processAllIdFields(value);
        }
      });
    } else if (data is List) {
      for (var i = 0; i < data.length; i++) {
        _processAllIdFields(data[i]);
      }
    }
  }

  Future<void> logout() async {
    await SecureStorage.logout();
    _isAuthenticated = false;
    _userData = null;
    notifyListeners();
  }
}
