import 'dart:async';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../services/local_notification_store.dart'; // ✅ Import shared notification store

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();

  // ✅ Call this in main() before runApp
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationItem> notifications = [];
  late final StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    loadNotifications();

    // ⏱️ Listen for new notification signals
    _subscription = notificationStreamController.stream.listen((_) {
      loadNotifications();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> loadNotifications() async {
    final data = await NotificationStorageService.getNotifications();
    setState(() => notifications = data.reversed.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontSize: 22)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.blueAccent),
            onPressed: () async {
              await NotificationStorageService.clearNotifications();
              notificationStreamController.add(null);
            },
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(child: Text("No notifications received."))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (_, index) {
                final n = notifications[index];
                return ListTile(
                  leading: const Icon(Icons.notifications_active,
                      color: Colors.green),
                  title: Text(n.title),
                  subtitle: Text(n.body),
                  trailing: Text(
                    DateFormat('MMM d, h:mm a').format(n.timestamp),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
    );
  }
}
