import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../components/new_types.dart';

class OrderService {
  static Future<void> sendOrderToBackend(OrderData order) async {
    final baseUrl =
        dotenv.env['ORDER_API_URL'] ?? 'http://localhost:8080/api/orders';
    final url = Uri.parse(baseUrl);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(order.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to place order: ${response.body}');
      }
    } catch (e) {
      print("Error sending order to backend: $e");
      rethrow;
    }
  }
}
