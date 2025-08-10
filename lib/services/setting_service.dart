import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsService {
  static bool _liveOrdersEnabled = true;

  static bool get liveOrdersEnabled => _liveOrdersEnabled;

  static Future<void> initialize() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('settings')
          .doc('config')
          .get();

      _liveOrdersEnabled = snapshot.data()?['liveOrdersEnabled'] ?? false;
    } catch (e) {
      _liveOrdersEnabled = false; // fallback
    }
  }
}
