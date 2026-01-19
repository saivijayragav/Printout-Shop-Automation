import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:RITArcade/pages/bottomnavigation.dart';
import 'package:RITArcade/pages/upload.dart';
import 'package:RITArcade/services/payment_history_page.dart';
import 'package:RITArcade/pages/loadingpage.dart';
import 'package:RITArcade/pages/login_page.dart';
import 'package:RITArcade/pages/no_internet.dart';
import 'package:RITArcade/pages/notification_page.dart';
import 'package:RITArcade/services/firebase_messaging_service.dart';
import 'theme.dart';
import 'services/local_notification_store.dart';
import 'services/setting_service.dart';


/// ✅ Handle background notifications
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final notification = message.notification;
  if (notification != null) {
    final item = NotificationItem(
      title: notification.title ?? "No title",
      body: notification.body ?? "No body",
      timestamp: DateTime.now(),
    );
    await NotificationStorageService.addNotification(item);
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Load environment variables
  await dotenv.load(fileName: ".env");

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  // ✅ Set background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await SettingsService.initialize(); 

  // ✅ Optionally: register token service
  await FirebaseMessagingService.initialize();

  runApp(const XeroxShopApp());
}

// ✅ Global key for navigation on notification tap
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class XeroxShopApp extends StatelessWidget {
  const XeroxShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ Required for NotificationPage navigation
      theme: CustomTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoadingPage(),
        '/login': (context) => LoginPage(),
        '/home': (context) => MainScaffold(),
        '/upload': (context) => UploadPage(),
        '/payment_history': (context) => const OrderHistoryPage(),
        // Add route if you want: '/notifications': (_) => const NotificationPage(),
      },
    );
  }
}

