import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import '../services/local_notification_store.dart'; // ✅ Import shared notification store

final StreamController<void> notificationStreamController = StreamController<void>.broadcast();

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();

  // ✅ Call this in main() before runApp
  static Future<void> initializeFCM(BuildContext context, Function onTapNotificationPage) async {
    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings('@drawable/xeroxshoplogo');
    const initSettings = InitializationSettings(android: androidInit);

    await localNotifications.initialize(initSettings,
      onDidReceiveNotificationResponse: (response) {
        onTapNotificationPage(); // Navigate to NotificationPage
      },
    );

    // 🔄 Common function to show and store notification
    Future<void> _showAndStore(RemoteMessage message) async {
      final notification = message.notification;
      if (notification != null) {
        final item = NotificationItem(
          title: notification.title ?? "No title",
          body: notification.body ?? "No body",
          timestamp: DateTime.now(),
        );

        await NotificationStorageService.addNotification(item);

        const androidDetails = AndroidNotificationDetails(
          'channel_id',
          'Xerox Notifications',
          icon: '@drawable/xeroxshoplogo',
          importance: Importance.max,
          priority: Priority.high,
        );

        const notifDetails = NotificationDetails(android: androidDetails);

        await localNotifications.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          item.title,
          item.body,
          notifDetails,
        );

        // 🔔 Notify NotificationPage
        notificationStreamController.add(null);
      }
    }

    // App in foreground
    FirebaseMessaging.onMessage.listen((message) async {
      await _showAndStore(message);
    });

    // App opened from background by tapping notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await _showAndStore(message);
      onTapNotificationPage();
    });

    // App launched from terminated state
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await _showAndStore(initialMessage);
      onTapNotificationPage();
    }
  }
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
      appBar: AppBar(title: const Text("Notifications", style: TextStyle(fontSize: 22)), backgroundColor: Colors.transparent),
      body: notifications.isEmpty
          ? const Center(child: Text("No notifications received."))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (_, index) {
                final n = notifications[index];
                return ListTile(
                  leading: const Icon(Icons.notifications_active, color: Colors.green),
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
