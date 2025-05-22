import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimeZoneProvider with ChangeNotifier {
  String _selectedTimeZone = 'WIB';
  Map<String, int> _timeZoneOffsets = {
    'WIB': 7, // Western Indonesian Time (GMT+7)
    'WITA': 8, // Central Indonesian Time (GMT+8)
    'WIT': 9, // Eastern Indonesian Time (GMT+9)
    'GMT': 0, // Greenwich Mean Time
    'CET': 1, // Central European Time (GMT+1)
    'EST': -5, // Eastern Standard Time (GMT-5)
    'JST': 9, // Japan Standard Time (GMT+9)
    'IST': 5, // India Standard Time (GMT+5)
  };

  TimeZoneProvider() {
    _loadTimeZone();
  }

  String get selectedTimeZone => _selectedTimeZone;
  Map<String, int> get timeZoneOffsets => _timeZoneOffsets;

  // Load saved time zone from preferences
  Future<void> _loadTimeZone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTimeZone = prefs.getString('selected_time_zone');
      if (savedTimeZone != null &&
          _timeZoneOffsets.containsKey(savedTimeZone)) {
        _selectedTimeZone = savedTimeZone;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading time zone: $e');
    }
  }

  // Set time zone and save to preferences
  Future<void> setTimeZone(String timeZone) async {
    if (_timeZoneOffsets.containsKey(timeZone) &&
        _selectedTimeZone != timeZone) {
      _selectedTimeZone = timeZone;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_time_zone', timeZone);
      } catch (e) {
        debugPrint('Error saving time zone: $e');
      }

      notifyListeners();
    }
  }

  // Get current time in the selected time zone
  DateTime getCurrentTimeInSelectedZone() {
    final now = DateTime.now().toUtc();
    final offset =
        _timeZoneOffsets[_selectedTimeZone] ?? 7; // Default to WIB if not found
    return now.add(Duration(hours: offset));
  }

  // Format the time for display
  String getFormattedTime({bool showSeconds = false}) {
    final time = getCurrentTimeInSelectedZone();
    final format = showSeconds ? "HH:mm:ss" : "HH:mm";
    return DateFormat(format).format(time);
  }

  // Get time in a specific time zone
  DateTime getTimeInZone(String timeZone) {
    final now = DateTime.now().toUtc();
    final offset = _timeZoneOffsets[timeZone] ?? 0;
    return now.add(Duration(hours: offset));
  }

  // Format date and time for a specific zone
  String formatTimeForZone(String timeZone, {bool includeDate = false}) {
    final time = getTimeInZone(timeZone);
    final format = includeDate ? "dd MMM yyyy HH:mm" : "HH:mm";
    return DateFormat(format).format(time);
  }
}
