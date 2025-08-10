import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Add this
import '../components/newtypes.dart';

class FirestoreService {
  final CollectionReference orders =
      FirebaseFirestore.instance.collection('orders');

  Future<void> addOrder(OrderData order) async {
    final filesData = order.files.map((f) => {
          'name': order.orderId + f.name,
          'pages': f.pages,
          'copies': f.copies,
          'binding': f.binding,
          'color': f.color,
          'sides': f.sides,
        }).toList();

    int spiralOrSoftBindingCount = order.files.where((f) {
      final b = f.binding.toLowerCase();
      return b.contains('spiral') || b.contains('soft');
    }).isNotEmpty
        ? 1
        : 0;

    final int timeSeconds =
        (60) + (order.pages * 1) + (spiralOrSoftBindingCount * 15 * 60);

    // ✅ Get current user ID safely
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'unknown'; // fallback if needed

    await orders.add({
      'orderID': order.orderId,
      'userId': userId, // ✅ This line added
      'files': filesData,
      'pages': order.pages,
      'price': order.price,
      'time': timeSeconds,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Only counts documents — low read cost
  Future<int> getCount() async {
    final snapshot = await orders.count().get();
    return snapshot.count ?? 0;
  }

  // Only sums 'time' field using aggregate query — low cost
  Future<int> getTotalTime() async {
    final agg = await orders.aggregate(sum('time')).get();
    final double? sumValue = agg.getSum('time');
    return sumValue?.toInt() ?? 0;
  }

  // Expose raw snapshot only if absolutely needed (expensive read)
  Future<QuerySnapshot> getOrderSnapshot() async {
    return await orders.get(); // use only if full logic is needed
  }
}
