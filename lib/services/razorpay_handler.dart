import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RazorpayHandler {
  late Razorpay _razorpay;
  final Function(PaymentSuccessResponse) onSuccess;
  final Function(PaymentFailureResponse) onFailure;
  final Function(ExternalWalletResponse) onExternalWallet;

  RazorpayHandler({
    required this.onSuccess,
    required this.onFailure,
    required this.onExternalWallet,
  });

  void init() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void openCheckout({
    required double amount, // Provided in Rupee
    required String name,
    required String description,
    String? email,
    String? contact,
  }) {
    int amountInPaise = (amount * 100).round();
    var options = {
      'key': dotenv.env['RAZORPAY_KEY_ID'] ?? '',
      'amount': amountInPaise,
      'name': name,
      'description': description,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': contact ?? '',
        'email': email ?? 'test@razorpay.com'
      },
      'external': {
        'wallets': ['paytm'],
        'upi': true,
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
    }
  }
}
