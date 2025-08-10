import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 🔐 Request permission
    await _firebaseMessaging.requestPermission();

    // 🎯 Get FCM token
    final token = await _firebaseMessaging.getToken();
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    if (userId != null && token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ Token saved for user: $userId');
    } else {
      debugPrint('⚠️ Token or userId is null');
    }

    // ✅ Init local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);

    // ✅ Setup notification channel
    const channel = AndroidNotificationChannel(
      'channel_id',
      'Xerox Notifications',
      importance: Importance.max,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // ✅ Foreground notification handler using `data` only
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      final title = data['title'] ?? 'No title';
      final body = data['body'] ?? 'No body';

      if (title != 'No title' || body != 'No body') {
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

    // ✅ Background/terminated state handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }
}

// ✅ Background message handler (must be top-level)
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 [BG] ${message.data['title']}: ${message.data['body']}');
}
