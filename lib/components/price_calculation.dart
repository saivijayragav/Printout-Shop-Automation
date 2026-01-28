import 'package:cloud_firestore/cloud_firestore.dart';
import 'new_types.dart'; // Contains OrderData and FileData classes

class Pricing {
  final double printPrice;
  final double colorPrice;
  final double softBindingPrice;
  final double spiralBindingPrice;
  final double singleSide;
  final double doubleSide;
  final double fourSide;

  Pricing({
    required this.printPrice,
    required this.colorPrice,
    required this.softBindingPrice,
    required this.spiralBindingPrice,
    required this.singleSide,
    required this.doubleSide,
    required this.fourSide,
  });

  factory Pricing.fromMap(Map<String, dynamic> map) {
    return Pricing(
      printPrice: (map['printPrice'] ?? 1.2).toDouble(),
      colorPrice: (map['colorPrice'] ?? 5.0).toDouble(),
      softBindingPrice: (map['softBindingPrice'] ?? 30.0).toDouble(),
      spiralBindingPrice: (map['spiralBindingPrice'] ?? 35.0).toDouble(),
      singleSide: (map['singleSide'] ?? 1.0).toDouble(),
      doubleSide: (map['doubleSide'] ?? 1.0).toDouble(),
      fourSide: (map['fourSide'] ?? 2.5).toDouble(),
    );
  }
}

/// 🔁 Fetch Pricing data from Firestore (settings/pricing document)
Future<Pricing> fetchPricingFromFirestore() async {
  try {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('settings').doc('pricing').get();

    if (snapshot.exists) {
      return Pricing.fromMap(snapshot.data() as Map<String, dynamic>);
    } else {
      throw Exception("Pricing document not found.");
    }
  } catch (e) {
    throw Exception("Failed to fetch pricing: $e");
  }
}

/// 💰 Calculate total amount based on user order and Firestore pricing
Future<double> calculateTotal(OrderData order) async {
  final pricing = await fetchPricingFromFirestore();
  double total = 0;

  for (var file in order.files) {
    double fileCost = file.pages * pricing.printPrice;

    // ✅ Add color price if selected
    if (file.color == "Color") {
      fileCost += file.pages * (pricing.colorPrice - pricing.printPrice);
    }

    // ✅ Add binding price
    if (file.binding == "Soft Binding") {
      fileCost += pricing.softBindingPrice;
    } else if (file.binding == "Spiral Binding") {
      fileCost += pricing.spiralBindingPrice;
    }

    // ✅ Apply sides multiplier
    if (file.sides == "Double Side") {
      fileCost *= pricing.doubleSide;
    } else if (file.sides == "Four Side") {
      if (pricing.fourSide != 0) {
        fileCost /= pricing.fourSide;
      }
    }

    // ✅ Multiply by number of copies
    total += fileCost * file.copies;
  }

  return total;
}
