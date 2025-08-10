import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final List<String> stored = prefs.getStringList(_key) ?? [];
    stored.add(jsonEncode(item.toMap()));
    await prefs.setStringList(_key, stored);
  }

  static Future<List<NotificationItem>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> stored = prefs.getStringList(_key) ?? [];

    final now = DateTime.now();
    final filtered = stored
        .map((e) => NotificationItem.fromMap(jsonDecode(e)))
        .where((n) => now.difference(n.timestamp).inHours < 24)
        .toList();

    final updated = filtered.map((n) => jsonEncode(n.toMap())).toList();
    await prefs.setStringList(_key, updated);

    return filtered;
  }
}
