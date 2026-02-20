import 'package:firebase_core/firebase_core.dart';
import '../main.dart'; // ✅ Import main.dart to access navigatorKey
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_notification_store.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 🔐 Request permission
    await _firebaseMessaging.requestPermission();

    // 🎯 Get FCM token
    final token = await _firebaseMessaging.getToken();

    // Check for user in SharedPreferences since we aren't using FirebaseAuth
    final prefs = await SharedPreferences.getInstance();
    final userPhone = prefs.getString('userPhone');

    if (userPhone != null && token != null) {
      await saveTokenForUser(userPhone);
    } else {
      debugPrint('⚠️ Token or userPhone is null');
    }

    
    const androidInit =
        AndroidInitializationSettings('@drawable/xeroxshoplogo');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        navigatorKey.currentState?.pushNamed('/notifications');
      },
    );

    const channel = AndroidNotificationChannel(
      'channel_id',
      'Xerox Notifications',
      importance: Importance.max,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // ✅ Foreground notification handler using `data` only
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      final title = data['title'] ?? 'No title';
      final body = data['body'] ?? 'No body';

      if (title != 'No title' || body != 'No body') {
        // ✅ Store notification locally
        final item = NotificationItem(
          title: title,
          body: body,
          timestamp: DateTime.now(),
        );
        await NotificationStorageService.addNotification(item);

        // ✅ Notify UI to refresh (if NotificationPage is listening)
        notificationStreamController.add(null);

        await _localNotifications.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'channel_id',
              'Xerox Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // ✅ App opened from background by tapping notification (System Tray)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      navigatorKey.currentState?.pushNamed('/notifications');
    });

    // ✅ Background/terminated state handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }

  // New method to manually save token (e.g., after login)
  static Future<void> saveTokenForUser(String phoneNumber) async {
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      // Use phone number as document ID
      await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .set({
        'fcmToken': token,
        'phoneNumber': phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ Token saved for user: $phoneNumber');
    } else {
      debugPrint('⚠️ Failed to get token for saving');
    }
  }
}

// ✅ Background message handler (must be top-level)
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 [BG] ${message.data['title']}: ${message.data['body']}');

  final data = message.data;
  final title = data['title'] ?? 'No title';
  final body = data['body'] ?? 'No body';

  if (title != 'No title' || body != 'No body') {
    final item = NotificationItem(
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    await NotificationStorageService.addNotification(item);
  }
}
