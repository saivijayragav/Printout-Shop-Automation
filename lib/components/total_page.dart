import 'package:flutter/material.dart';
import 'package:RITArcade/components/pagegenerator.dart';
import 'package:RITArcade/components/pricecalculation.dart';
import 'package:RITArcade/components/timecalculation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';
import 'package:RITArcade/services/payment_service.dart';
import 'package:RITArcade/services/payment_model.dart';
import '../pages/bottomnavigation.dart';
import '../pages/orderprocessing.dart';
import 'newtypes.dart';
import 'dart:typed_data';

class TotalPage extends StatefulWidget {
  final OrderData order;
  const TotalPage({super.key, required this.order});

  @override
  State<TotalPage> createState() => _TotalPageState();
}

class _TotalPageState extends State<TotalPage> {
  late Razorpay _razorpay;
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _prepareOrder(); // 🛠 Setup with front page + price
  }

  Future<void> _prepareOrder() async {
    // ✅ Check if front page already added (assuming '.pdf' is the name)
    bool frontPageExists = widget.order.files.any((f) => f.name == '.pdf');

    if (!frontPageExists) {
      // ✅ Add front page to files
      Uint8List front = await generatePdfWithCode(widget.order.orderId);
      widget.order.files.add(FileData(
        name: '.pdf',
        size: front.lengthInBytes / (1024 * 1024),
        pages: 1,
        bytes: front,
        copies: 1,
        type: 'pdf',
        path: '',
        sides: "Single Side",
        color: "Black and White",
        binding: "No Binding",
      ));
    }

    // ✅ Recalculate total page count
    int totalPages = 0;
    for (var file in widget.order.files) {
      totalPages += file.pages * file.copies;
    }
    widget.order.pages = totalPages;

    // ✅ Recalculate price
    double price = await calculateTotal(widget.order);

    setState(() {
      widget.order.price = price;
      widget.order.time = calculateTime(widget.order);
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _proceedToPayment() async {
    int amountInPaise = (widget.order.price * 100).round();
    var options = {
      'key': "rzp_test_QzO1IADyDArzhi",
      'amount': amountInPaise,
      'name': 'Arcade Xerox Shop',
      'description': 'Printing Service',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {'contact': '', 'email': 'test@razorpay.com'},
      'external': {
        'wallets': ['paytm'],
        'upi': true,
      }
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await _savePayment(
      "Success",
      response.paymentId ?? "N/A",
      response.orderId ?? "N/A",
      response.signature ?? "N/A",
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Payment Successful (Test Mode)")),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderProcessingPage(order: widget.order),
      ),
    );
  }

  Future<void> _handlePaymentError(PaymentFailureResponse response) async {
    await _savePayment(
      "Failure",
      response.code.toString(),
      "N/A",
      response.message ?? "N/A",
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Payment Failed: ${response.message}")),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainScaffold(selectedIndex: 3),
      ),
      (route) => false,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("💼 Wallet Used: ${response.walletName}")),
    );
  }

  Future<void> _savePayment(
      String status, String paymentId, String orderId, String signature) async {
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final payment = Payment(
      status: status,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
      customProcessId: widget.order.orderId,
      timestamp: now,
    );
    await _paymentService.insertPayment(payment);
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Total Amount")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            _buildRow("Total Pages :", "${widget.order.pages}"),
            const SizedBox(height: 30),
            const Divider(thickness: 1),
            _buildRow("Total Price :",
                "₹${widget.order.price.toStringAsFixed(2)}",
                isBold: true),
            const Spacer(),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _proceedToPayment,
                    child: const Text("Proceed",
                        style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
