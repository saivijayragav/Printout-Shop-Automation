import 'package:RITArcade/services/payment_model.dart';
import 'package:RITArcade/services/payment_service.dart';
import 'package:flutter/material.dart';


class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final PaymentService _paymentService = PaymentService();
  List<Payment> _payments = [];
  Set<int> _selectedIds = {}; // selected payment IDs

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final payments = await _paymentService.getAllPayments();
    setState(() {
      _payments = payments;
      _selectedIds.clear();
    });
  }

  Future<void> _clearPayments() async {
    await _paymentService.clearPayments();
    await _loadPayments();
  }

  Future<void> _deleteSelectedPayments() async {
    for (int id in _selectedIds) {
      await _paymentService.deletePaymentById(id);
    }
    await _loadPayments();
  }

  bool _isSelected(int? id) => id != null && _selectedIds.contains(id);

  void _toggleSelection(int? id) {
    if (id == null) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedIds.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment History"),
        backgroundColor: Colors.transparent,
        actions: [
          if (hasSelection)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Selected',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Selected Payments?'),
                    content: const Text('Are you sure you want to delete the selected payment records?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _deleteSelectedPayments();
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear All History',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear All History?'),
                  content: const Text('Are you sure you want to delete all payment records?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _clearPayments();
                      },
                      child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _payments.isEmpty
            ? const Center(child: Text("No payment records found."))
            : ListView.builder(
                itemCount: _payments.length,
                itemBuilder: (context, index) {
                  final payment = _payments[index];
                  final selected = _isSelected(payment.id);
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: CheckboxListTile(
                      value: selected,
                      onChanged: (_) => _toggleSelection(payment.id),
                      title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Text('Order ID: ${payment.customProcessId}'),
                                    Text("Payment ID: ${payment.paymentId}")]),
                      subtitle: Text(
                        "Status: ${payment.status}\nTime: ${payment.timestamp}",
                        style: const TextStyle(fontSize: 14),
                      ),
                      secondary: Icon(
                        payment.status == "Success" ? Icons.check_circle : Icons.cancel,
                        color: payment.status == "Success" ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
