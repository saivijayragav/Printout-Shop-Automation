import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:RITArcade/components/new_types.dart';
import 'package:http/http.dart' as http;

Future<Receipt> getPrice(OrderData order) async {
  final url = Uri.parse(
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api/price/estimate');
  Map<String, List<Map<String, dynamic>>> payload = {"files": []};
  for (var file in order.files) {
    payload["files"]!.add({
      "name": file.name,
      "pages": file.pages,
      "copies": file.copies,
      "binding": file.binding == "Soft Binding" ? 1 : file.binding == "Spiral Binding" ? 0 : -1,
      "color": file.color == "Color" ? 1 : 0,
      "sides": file.sides == "Four sides"
          ? 4
          : file.sides == "Double side"
              ? 2
              : 1
    });
  }
  print(payload);
  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(payload),
  );
  print(response.body);
  if (response.statusCode == 200) {
    return Receipt.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to create receipt.');
  }
}
