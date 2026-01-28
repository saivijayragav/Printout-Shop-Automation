import 'package:flutter/material.dart';
import 'package:RITArcade/components/preprocessing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/file_clearing.dart';
import '../components/new_types.dart';
import '../services/cloudflare_backend.dart';
import '../services/order_service.dart';
import 'bottom_navigation.dart';

class OrderProcessingPage extends StatefulWidget {
  final OrderData order;
  const OrderProcessingPage({super.key, required this.order});
  @override
  _OrderProcessingPageState createState() => _OrderProcessingPageState();
}

class _OrderProcessingPageState extends State<OrderProcessingPage> {
  bool isLoading = true; // Start with loading true
  bool showSuccess = false;

  @override
  void initState() {
    super.initState();
    // Automatically start processing when page loads
    placeOrder();
  }

  // Function to handle order placement
  Future<void> placeOrder() async {
    try {
      sanitizeFileName(widget.order.files); // Change the file names

      // 1. Get User Details
      final prefs = await SharedPreferences.getInstance();
      widget.order.userName = prefs.getString('userName') ?? "Unknown";
      widget.order.phoneNumber = prefs.getString('userPhone') ?? "Unknown";

      // 2. Upload to Cloudflare
      await uploader(widget.order);

      // 3. Send Data to Backend
      await OrderService.sendOrderToBackend(widget.order);

      // 4. Clear local cache
      await clearCache(widget.order.files);

      // Show success message
      setState(() {
        isLoading = false;
        showSuccess = true;
      });

      // Wait for 2 seconds to show success message, then navigate
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      // Navigate to next page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NextPage()),
      );
    } catch (error) {
      // Handle error
      print("Order processing failed: $error");
      setState(() {
        isLoading = false;
        showSuccess = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
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
              // Loading state
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
