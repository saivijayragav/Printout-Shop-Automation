import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../components/new_types.dart';
import 'dart:io';
import '../utils/app_exceptions.dart';

class OrderService {
  static Future<void> sendOrderToBackend(OrderData order) async {
    final baseUrl =
        dotenv.env['ORDER_API_URL'] ?? 'http://localhost:8080/api/orders';
    final url = Uri.parse(baseUrl);
    
    try {
      print(order.toJson());
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(order.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw BackendException(
            'Server error (${response.statusCode}): ${response.body}');
      }
    } on SocketException {
      throw NetworkException("Failed to connect to order server.");
    } catch (e) {
      print("Error sending order to backend: $e");
      if (e is AppException) rethrow; // Pass through our custom exceptions
      throw BackendException("Unexpected error: $e");
    }
  }
}
