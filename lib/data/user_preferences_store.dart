import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesStore {
  UserPreferencesStore._();

  static final UserPreferencesStore instance = UserPreferencesStore._();

  String _keyFor(String email, String suffix) {
    final normalized = email.trim().toLowerCase();
    return 'user.$normalized.$suffix';
  }

  Future<void> saveProfileImageBytes({
    required String userEmail,
    required List<int> bytes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = base64Encode(bytes);
    await prefs.setString(_keyFor(userEmail, 'profile_image_b64'), encoded);
  }

  Future<List<int>?> getProfileImageBytes({required String userEmail}) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_keyFor(userEmail, 'profile_image_b64'));
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRouteRemindersEnabled({
    required String userEmail,
    required bool enabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFor(userEmail, 'route_reminders_enabled'), enabled);
  }

  Future<bool?> getRouteRemindersEnabled({required String userEmail}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFor(userEmail, 'route_reminders_enabled'));
  }

  Future<void> saveNotificationsEnabled({
    required String userEmail,
    required bool enabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFor(userEmail, 'notifications_enabled'), enabled);
  }

  Future<bool?> getNotificationsEnabled({required String userEmail}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFor(userEmail, 'notifications_enabled'));
  }

  Future<void> saveProfileFieldLastUpdatedAt({
    required String userEmail,
    required String field,
    required DateTime changedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(userEmail, 'profile_field_last_updated_$field'),
      changedAt.toIso8601String(),
    );
  }

  Future<DateTime?> getProfileFieldLastUpdatedAt({
    required String userEmail,
    required String field,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(userEmail, 'profile_field_last_updated_$field'));
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<List<Map<String, String>>> getPendingNotifications({
    required String userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(userEmail, 'pending_notifications_json'));
    if (raw == null || raw.trim().isEmpty) {
      return <Map<String, String>>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <Map<String, String>>[];
      }

      return decoded.whereType<Map>().map<Map<String, String>>((entry) {
        return {
          'title': (entry['title'] ?? '').toString(),
          'body': (entry['body'] ?? '').toString(),
          'kind': (entry['kind'] ?? '').toString(),
          'created_at': (entry['created_at'] ?? '').toString(),
        };
      }).toList();
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  Future<void> savePendingNotifications({
    required String userEmail,
    required List<Map<String, String>> notifications,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(userEmail, 'pending_notifications_json'),
      jsonEncode(notifications),
    );
  }

  Future<void> addPendingNotification({
    required String userEmail,
    required String title,
    required String body,
    required String kind,
  }) async {
    final pending = await getPendingNotifications(userEmail: userEmail);
    pending.add({
      'title': title,
      'body': body,
      'kind': kind,
      'created_at': DateTime.now().toIso8601String(),
    });
    await savePendingNotifications(userEmail: userEmail, notifications: pending);
  }

  Future<bool> getDeliveryFlag({
    required String userEmail,
    required String flag,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFor(userEmail, 'delivery_flag_$flag')) ?? false;
  }

  Future<void> setDeliveryFlag({
    required String userEmail,
    required String flag,
    required bool value,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFor(userEmail, 'delivery_flag_$flag'), value);
  }
}
