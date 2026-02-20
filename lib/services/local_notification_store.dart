import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart'; // For debugPrint

final StreamController<void> notificationStreamController =
    StreamController<void>.broadcast();

class NotificationItem {
  final String title;
  final String body;
  final DateTime timestamp;

  NotificationItem({
    required this.title,
    required this.body,
    required this.timestamp,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      title: map['title'],
      body: map['body'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
      };
}

class NotificationStorageService {
  static const _key = 'stored_notifications';

  static Future<void> addNotification(NotificationItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> stored = prefs.getStringList(_key) ?? [];
      stored.add(jsonEncode(item.toMap()));
      await prefs.setStringList(_key, stored);
      debugPrint(
          '✅ [Storage] Added notification: ${item.title}. Total: ${stored.length}');
    } catch (e) {
      debugPrint('❌ [Storage] Error adding notification: $e');
    }
  }

  static Future<List<NotificationItem>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> stored = prefs.getStringList(_key) ?? [];
      debugPrint('📂 [Storage] Retrieving ${stored.length} notifications');

      final filtered =
          stored.map((e) => NotificationItem.fromMap(jsonDecode(e))).toList();

      return filtered;
    } catch (e) {
      debugPrint('❌ [Storage] Error retrieving notifications: $e');
      return [];
    }
  }

  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    debugPrint('🗑️ [Storage] Cleared notifications');
  }
}
