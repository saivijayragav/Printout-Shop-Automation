import 'dart:async';
import 'package:flutter/material.dart';
import 'package:RITArcade/services/firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

// FCM related imports
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userEmail;
  int _count = 0;
  String _estimatedTime = 'Loading...';

  FirestoreService firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    getCounts();
    _loadSavedEmail();
    _initFCM(); // ✅ Initialize FCM
  }

  Future<void> getCounts() async {
    final snapshot = await firestoreService.getOrderSnapshot();

    final uniqueOrderIds = <String>{};
    int totalPages = 0;
    int totalCopies = 0;
    int specialBindingCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final orderId = data['orderID'];
      final pages = int.tryParse(data['pages']?.toString() ?? '0') ?? 0;

      if (orderId != null && !uniqueOrderIds.contains(orderId)) {
        uniqueOrderIds.add(orderId);
        totalPages += pages;

        final files = data['files'] as List<dynamic>?;
        if (files != null) {
          for (var file in files) {
            final fileMap = file as Map<String, dynamic>;
            final copies = int.tryParse(fileMap['copies']?.toString() ?? '1') ?? 1;
            final binding = (fileMap['binding'] ?? '').toString().toLowerCase();

            totalCopies += copies;
            if (binding.contains('spiral') || binding.contains('soft')) {
              specialBindingCount++;
            }
          }
        }
      }
    }

    final totalOrders = uniqueOrderIds.length;
    _count = totalOrders;

    final totalSeconds = (totalOrders * 60) +
        (totalPages * 1) +
        (totalCopies * 15) +
        (specialBindingCount * 15 * 60);

    String formatted;
    if (totalSeconds >= 3600) {
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      final seconds = totalSeconds % 60;
      formatted = "$hours hr${minutes > 0 ? ' $minutes min' : ''}${seconds > 0 ? ' $seconds sec' : ''}";
    } else if (totalSeconds >= 60) {
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      formatted = "$minutes min${seconds > 0 ? ' $seconds sec' : ''}";
    } else {
      formatted = "$totalSeconds sec";
    }

    setState(() {
      _estimatedTime = 'Estimated Time: 1 day $formatted';
    });
  }

  Future<void> _loadSavedEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('savedEmail');
    setState(() {
      userEmail = email;
    });
  }

  // ✅ NEW: Firebase Messaging Initialization
  Future<void> _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Ask permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');
    } else {
      print('❌ Notification permission denied');
      return;
    }

    // Get FCM token
    String? token = await messaging.getToken();
    print('📱 FCM Token: $token');

    // Save to Firestore (if logged in)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }

    // Handle foreground notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notification.body ?? '📩 New message')),
        );
      }
    });

    // Handle tap when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📨 App opened from notification');
      // Navigate if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userEmail == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String userInitial =
        userEmail!.isNotEmpty ? userEmail![0].toUpperCase() : '';

    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Image(
                  image: AssetImage('assets/queue.png'),
                  width: 70,
                  height: 70),
              Text('$_count',
                  style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text('Orders in queue', style: TextStyle(color: Colors.grey[300])),
              const SizedBox(height: 20),
              Text(
                _estimatedTime,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              const Text(
                "*No refund will be provided",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
