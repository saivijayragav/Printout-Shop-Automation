import 'package:flutter/material.dart';
import 'package:RITArcade/components/preprocessing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/file_clearing.dart';
import '../components/new_types.dart';
import '../services/cloudflare_backend.dart';
import '../services/order_service.dart';
import 'bottom_navigation.dart';
import '../utils/app_exceptions.dart';
import '../components/ui_helpers.dart';

class OrderProcessingPage extends StatefulWidget {
  final OrderData order;
  const OrderProcessingPage({super.key, required this.order});
  @override
  _OrderProcessingPageState createState() => _OrderProcessingPageState();
}

class _OrderProcessingPageState extends State<OrderProcessingPage> {
  bool isLoading = true;
  bool showSuccess = false;
  String? errorMessage; // To store error message for retry UI

  @override
  void initState() {
    super.initState();
    placeOrder();
  }

  Future<void> placeOrder() async {
    setState(() {
      isLoading = true;
      errorMessage = null; // Reset error
    });

    try {
      sanitizeFileName(widget.order.files);

      final prefs = await SharedPreferences.getInstance();
      widget.order.userName = prefs.getString('userName') ?? "Unknown";
      widget.order.phoneNumber = prefs.getString('userPhone') ?? "Unknown";

      // Add timestamp
      widget.order.timestamp = DateTime.now().toIso8601String();

      await uploader(widget.order);
      await OrderService.sendOrderToBackend(widget.order);
      await clearCache(widget.order.files);

      setState(() {
        isLoading = false;
        showSuccess = true;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NextPage()),
      );
    } catch (error) {
      print("Order processing failed: $error");
      setState(() {
        isLoading = false;
        showSuccess = false;

        // Set user-friendly error message based on exception type
        if (error is NetworkException) {
          errorMessage = "No Internet Connection. Please check your network.";
        } else if (error is UploadException) {
          errorMessage = "Failed to upload files. Please try again.";
        } else if (error is BackendException) {
          errorMessage = "Server Error. Please try again later.";
        } else {
          errorMessage = "An unexpected error occurred.";
        }
      });

      // Also show snackbar for immediate feedback
      UIHelpers.showErrorSnackBar(context, errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Order'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Processing your order...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Please wait while we process payment\nand update inventory',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ] else if (errorMessage != null) ...[
              // Error State with Retry
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              Text(
                "Order Failed",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: placeOrder, // Retry action
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text("Retry Order",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
              ),
            ],
            if (showSuccess) ...[
              // Success state
              Container(
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(20),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Thank you for your purchase',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              // Optional: Add animated checkmark or additional styling
              LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 10),
              Text(
                'Redirecting...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Placeholder for the next page
class NextPage extends StatelessWidget {
  const NextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmation'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Expanded(child: SizedBox()),
              const Icon(
                Icons.receipt_long,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              const Text(
                'Order Confirmation Page',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your order has been confirmed!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const Expanded(child: SizedBox()),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MainScaffold(selectedIndex: 3),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Order History',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
