import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'payment_model.dart';

class PaymentService {
  static const String _storageKey = 'payment_history';

  Future<void> insertPayment(Payment payment) async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(_storageKey);
    print('🔐 insertPayment: about to save ${payment.toMap()}');
    List<Map<String, dynamic>> paymentList = [];

    if (storedData != null) {
      try {
        List<dynamic> decoded = jsonDecode(storedData);
        paymentList = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        paymentList = [];
      }
    }

    // Assign a unique ID if not set
    final newId = DateTime.now().millisecondsSinceEpoch;
    paymentList.insert(0, {
      ...payment.toMap(),
      'id': newId,
    });
    print('💾 Final list about to be saved → ${jsonEncode(paymentList)}');
    await prefs.setString(_storageKey, jsonEncode(paymentList));
  }

  Future<List<Payment>> getAllPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(_storageKey);
    print('📥 Raw storedData = $storedData');
    if (storedData == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(storedData);
      return jsonList.map((e) => Payment.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearPayments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> deletePaymentById(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(_storageKey);

    if (storedData == null) return;

    List<Map<String, dynamic>> paymentList =
        (jsonDecode(storedData) as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

    paymentList.removeWhere((payment) => payment['id'] == id);

    await prefs.setString(_storageKey, jsonEncode(paymentList));
  }
}
