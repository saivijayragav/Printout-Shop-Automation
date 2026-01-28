import 'package:flutter/material.dart';
import 'package:RITArcade/components/page_generator.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';
import 'package:RITArcade/services/payment_service.dart';
import 'package:RITArcade/services/payment_model.dart';
import 'package:RITArcade/services/razorpay_handler.dart';
import '../pages/bottom_navigation.dart';
import '../pages/order_processing.dart';
import 'new_types.dart';
import 'dart:typed_data';

class TotalPage extends StatefulWidget {
  final OrderData order;
  const TotalPage({super.key, required this.order});

  @override
  State<TotalPage> createState() => _TotalPageState();
}

class _TotalPageState extends State<TotalPage> {
  late RazorpayHandler _razorpayHandler;
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _razorpayHandler = RazorpayHandler(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
    _razorpayHandler.init();

    _prepareOrder(); // 🛠 Setup with front page + price
  }

  Future<void> _prepareOrder() async {
    int totalPages = 0;
    for (var file in widget.order.files) {
      totalPages += file.pages * file.copies;
    }
    widget.order.pages = totalPages;
  }

  @override
  void dispose() {
    _razorpayHandler.dispose();
    super.dispose();
  }

  void _proceedToPayment() async {
    _razorpayHandler.openCheckout(
      amount: widget.order.price,
      name: 'Arcade Xerox Shop',
      description: 'Printing Service',
    );
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
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If receipt is missing, show basic summary (fallback)
    if (widget.order.receipt == null || widget.order.receipt!.items.isEmpty) {
      return _buildFallbackView();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Order Summary")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.order.receipt!.items.length,
              itemBuilder: (context, index) {
                final item = widget.order.receipt!.items[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              "₹${item.cost.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0, // gap between adjacent chips
                          runSpacing: 4.0, // gap between lines
                          children: [
                            _buildInfoBadge("${item.pages} pgs"),
                            // Assuming sides: 1=Single, 2=Double etc.
                            // You might need a helper maps int -> text if needed
                            _buildInfoBadge(item.sides == 1
                                ? "1 Side"
                                : item.sides == 2
                                    ? "2 Sides"
                                    : "${item.sides} Sides"),
                            _buildInfoBadge(
                                item.colorRate > 0 ? "Color" : "B&W"),
                            if (item.bindingNote != "No Binding" &&
                                item.bindingNote.isNotEmpty)
                              _buildInfoBadge(item.bindingNote),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E2B6),
        borderRadius: BorderRadius.circular(4),
      ),
      child:
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.black)),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF6EACDA),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Payable",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
                      Text("₹${widget.order.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _proceedToPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.black,
              ),
              child: const Text("Proceed to Pay",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackView() {
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
            _buildRow(
                "Total Price :", "₹${widget.order.price.toStringAsFixed(2)}",
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
