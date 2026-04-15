import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloudflare_r2/cloudflare_r2.dart';
import 'package:path_provider/path_provider.dart';

// Custom Imports
import '../widgets/customappbar.dart';
import '../widgets/custom_drawer.dart';
import '../Service/notification_service.dart';
import '../Service/printer_check.dart';
import 'printer_setup_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _liveOrdersEnabled = true;
  List<dynamic> _cachedOrders = [];
  bool _isLoading = false;
  Map<String, dynamic>? _selectedOrder;
  String _printStatus = "";
  
  // Printer configs
  List<PrinterConfig> _availablePrinters = [];
  bool _isPrinterReady = false;

  final String baseUrl = "http://${dotenv.env['API_IP']}/api/orders/summary";

  // Cloudflare R2
  static final accountId = dotenv.env['CLOUDFLARE_ACCOUNT_ID']!;
  static final accessKeyId = dotenv.env['CLOUDFLARE_ACCESS_KEY']!;
  static final secretAccessKey = dotenv.env['CLOUDFLARE_SECRET_KEY']!;
  static final bucket = dotenv.env['CLOUDFLARE_BUCKET']!;

  @override
  void initState() {
    super.initState();
    _initCloudflare();
    _loadPrinters();
    fetchOrdersFromApi();
  }

  Future<void> _initCloudflare() async {
    try {
      await CloudFlareR2.init(accountId: accountId, accessKeyId: accessKeyId, secretAccessKey: secretAccessKey);
    } catch (e) {
      debugPrint("Cloudflare Init Error: $e");
    }
  }

  Future<void> _loadPrinters() async {
    try {
      final configs = await PrinterChecker.loadConfigs();
      if (mounted) {
        setState(() {
          _availablePrinters = configs;
          _isPrinterReady = configs.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint("Load printers error: $e");
    }
  }

  void toggleLiveOrder(bool value) {
    setState(() => _liveOrdersEnabled = value);
    if (value) refreshData();
  }

  Future<void> fetchOrdersFromApi() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Sort: Oldest first (Ascending)
        data.sort((a, b) {
           String tA = a['timestamp'] ?? '';
           String tB = b['timestamp'] ?? '';
           return tA.compareTo(tB); 
        });

        setState(() {
          _cachedOrders = data;
          _isLoading = false;
          // Optionally auto-select the first order if none selected
          if (_selectedOrder == null && _cachedOrders.isNotEmpty) {
            _selectedOrder = _cachedOrders.first;
          } else if (_cachedOrders.isEmpty) {
            _selectedOrder = null;
          }
        });
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error fetching API: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("API Connection Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void refreshData() {
    fetchOrdersFromApi();
  }

  String formatTimestamp(String? timestampStr) {
    if (timestampStr == null || timestampStr.isEmpty) return 'No Timestamp';
    try {
      final DateTime dt = DateTime.parse(timestampStr);
      final DateTime now = DateTime.now();
      final bool isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final DateTime yesterday = now.subtract(const Duration(days: 1));
      final bool isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;

      final String timePart = DateFormat('hh:mm a').format(dt);

      if (isToday) return "Today, $timePart";
      if (isYesterday) return "Yesterday, $timePart";
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (e) {
      return timestampStr; 
    }
  }

  Future<void> triggerNotificationSequence(String rawPhoneNumber, String orderId) async {
    try {
      String cleanPhone = rawPhoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.length > 10) {
        cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
      }

      print("🔍 Looking up Firestore user: $cleanPhone");
      final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(cleanPhone).get();

      if (!docSnapshot.exists) {
        print("⚠️ User document NOT found");
        return;
      }

      final data = docSnapshot.data();
      final String? token = data?['fcmToken'];

      if (token == null || token.isEmpty) {
        print("⚠️ FCM token missing or empty");
        return;
      }

      print("📲 FCM Token found: ${token.substring(0, 20)}...");
      await NotificationService.sendOrderReadyNotification(token: token, orderId: orderId);
      print("✅ Notification SENT to mobile app");
    } catch (e) {
      print("❌ Notification error: $e");
    }
  }

  void markAsPrinted(Map<String, dynamic> order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mark as Printed"),
        content: const Text("Send notification to user and mark locally?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes", style: TextStyle(color: Colors.green))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        String? phone = order['phoneNumber'];
        String orderId = order['orderId']?.toString() ?? 'N/A';

        // Send Notification if phone exists
        if (phone != null && phone.isNotEmpty) {
          await triggerNotificationSequence(phone, orderId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("✅ Order marked & Notification sent to $phone")),
            );
          }
        }
        
        setState(() {
          _printStatus = "Printed / Done";
          // If you need to hit an api to update status, do it here. 
          // e.g. await http.put("$baseUrl/$orderId/status", ...)
        });
        
        refreshData();
      } catch (e) {
        debugPrint("❌ markAsPrinted error: $e");
      }
    }
  }

  void deleteOrder(Map<String, dynamic> order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Order"),
        content: const Text("Are you sure you want to delete this order?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final orderId = order['orderId'];
        final response = await http.delete(Uri.parse("$baseUrl/$orderId"));
        if (response.statusCode == 200 || response.statusCode == 204) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order deleted $orderId"), backgroundColor: Colors.red.shade400));
          if (_selectedOrder?['orderId'] == orderId) setState(() => _selectedOrder = null);
          refreshData();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete Failed: $e")));
      }
    }
  }

  // --- Printing & File Logic from OrderDetailsPage ---

  Future<Uint8List?> _fetchFileBytesFromR2(String rawName, String orderIdStr) async {
    final variants = {"$orderIdStr${rawName.trim()}", rawName.trim(), Uri.decodeFull(rawName.trim())};
    for (final name in variants) {
      try {
        debugPrint("☁️ Fetching fresh file from server: $name");
        final bytes = await CloudFlareR2.getObject(bucket: bucket, objectName: name);
        if (bytes.isNotEmpty) {
          return Uint8List.fromList(bytes); 
        }
      } catch (e) { 
        debugPrint("⚠️ Failed key: $name"); 
      }
    }
    return null;
  }

  Future<void> _downloadAndSilentPrint(List<dynamic> files, String orderIdStr) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 10),
            Text("Fetching & Routing Smart Job...", style: TextStyle(color: Colors.white, decoration: TextDecoration.none, fontSize: 14))
          ],
        ),
      ),
    );

    try {
      int totalJobsSent = 0;

      for (var fileData in files) {
        if (fileData is! Map) continue;
        
        final rawName = fileData['name']?.toString() ?? '';
        final int copies = int.tryParse(fileData['copies']?.toString() ?? '1') ?? 1;
        
        final String reqColor = fileData['color']?.toString().toLowerCase() ?? '';
        final bool isColorJob = reqColor.contains('color') || reqColor.contains('colour');
        
        final String sides = fileData['sides']?.toString().toLowerCase() ?? '';
        final bool isDuplexJob = sides.contains('double') || sides.contains('back') || sides.contains('two');

        final String pagesStr = fileData['pages']?.toString() ?? fileData['pageCount']?.toString() ?? '1';
        final int documentPages = int.tryParse(pagesStr) ?? 1;

        final bytes = await _fetchFileBytesFromR2(rawName, orderIdStr);

        if (bytes != null && bytes.isNotEmpty) {
          int sent = await PrinterChecker.printJobAutomated(
            bytes: bytes,
            isColor: isColorJob,
            isDuplex: isDuplexJob,
            copies: copies,
            documentPages: documentPages,
            jobNamePrefix: 'Job_$orderIdStr',
          );
          totalJobsSent += sent;
        } else {
          debugPrint("❌ Failed to fetch bytes from server for: $rawName");
        }
      }

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Complete! Routed $totalJobsSent jobs directly from server."), backgroundColor: Colors.green));
        setState(() {
          _printStatus = "Pending / Queued to Printer";
        });
      }

    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      String errorMessage = e.toString().replaceAll("Exception:", "").trim();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ $errorMessage"), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 5)));
      }
    }
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: const CustomDrawer(),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          // LEFT PANEL: List of Orders (1/3 of width)
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey.shade300, width: 2)),
              ),
              child: Column(
                children: [
                   _buildLeftPanelHeader(),
                   Expanded(
                     child: _isLoading 
                        ? const Center(child: CircularProgressIndicator()) 
                        : _buildOrderList(),
                   )
                ],
              ),
            ),
          ),
          
          // RIGHT PANEL: Order Details & Action (2/3 of width)
          Expanded(
            flex: 2,
            child: _selectedOrder == null 
              ? const Center(child: Text("Select an order from the list to view details", style: TextStyle(fontSize: 18, color: Colors.grey)))
              : _buildOrderDetailsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanelHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Orders List", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.blue),
                onPressed: refreshData,
                tooltip: "Refresh Orders",
              )
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Live', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: _liveOrdersEnabled ? Colors.green : Colors.red, shape: BoxShape.circle),
              ),
              Switch(value: _liveOrdersEnabled, onChanged: toggleLiveOrder),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    if (_cachedOrders.isEmpty) {
      return const Center(child: Text("No orders available."));
    }
    
    return ListView.builder(
      itemCount: _cachedOrders.length,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemBuilder: (context, index) {
        final order = _cachedOrders[index];
        final orderId = order['orderId']?.toString() ?? 'N/A';
        final userName = order['userName'] ?? 'Unknown User';
        final isSelected = _selectedOrder?['orderId'] == orderId;

        return Card(
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isSelected ? Colors.teal : Colors.transparent, width: 2),
          ),
          color: isSelected ? Colors.teal.shade50 : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedOrder = order;
                _printStatus = ""; // reset local status
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Order ID highlighted in bold
                   Text(
                     orderId, 
                     style: TextStyle(
                       fontSize: 24, 
                       fontWeight: FontWeight.w900, 
                       color: isSelected ? Colors.teal.shade800 : Colors.deepOrange.shade700
                     )
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Text(userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(formatTimestamp(order['timestamp']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                       ],
                     ),
                   )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Right Panel UI
  Widget _buildOrderDetailsView() {
    final data = _selectedOrder!;
    final files = data['files'] as List<dynamic>? ?? [];
    final orderIdStr = data['orderId']?.toString() ?? 'N/A';
    
    // Deduplicate files
    final seen = <String>{};
    final uniqueFiles = files.where((file) {
      final name = file['name']?.toString() ?? '';
      if (seen.contains(name)) return false;
      seen.add(name); return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               const Text("Order Details", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.teal)),
               IconButton(
                 icon: const Icon(Icons.print_outlined, color: Colors.grey),
                 tooltip: "Configure Printers",
                 onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterSetupPage())).then((_) => _loadPrinters()),
               )
             ]
           ),
           const Divider(thickness: 2),
           
           // Status & Print Chip Row
           Wrap(
             spacing: 12,
             runSpacing: 10,
             crossAxisAlignment: WrapCrossAlignment.center,
             children: [
               if (_printStatus.isNotEmpty) 
                 Chip(
                   label: Text(_printStatus, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   backgroundColor: _printStatus.contains('Done') ? Colors.green : Colors.amber.shade800,
                 ),
               
               // Show available printer chips
               if (_availablePrinters.isNotEmpty)
                 ..._availablePrinters.map((p) => ActionChip(
                   avatar: const Icon(Icons.print, size: 16, color: Colors.white),
                   label: Text("Smart Print (${p.osPrinterName})", style: const TextStyle(color: Colors.white)),
                   backgroundColor: Colors.blueAccent,
                   onPressed: () => _downloadAndSilentPrint(uniqueFiles, orderIdStr),
                 )).toList()
               else
                 ActionChip(
                   avatar: const Icon(Icons.warning, size: 16, color: Colors.white),
                   label: const Text("No Printer Configured", style: TextStyle(color: Colors.white)),
                   backgroundColor: Colors.redAccent,
                   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterSetupPage())).then((_) => _loadPrinters()),
                 ),
             ],
           ),
           
           const SizedBox(height: 20),
           
           // Customer Info Block
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.teal.shade200)),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text("Customer Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.teal)),
                 const SizedBox(height: 10),
                 _buildInfoRow('Name', data['userName']),
                 _buildInfoRow('Mobile Number', data['phoneNumber']),
                 _buildInfoRow('Price', data['price'] != null ? '₹${data['price']}' : 'N/A'),
                 _buildInfoRow('Time', formatTimestamp(data['timestamp'])),
               ],
             ),
           ),
           const SizedBox(height: 24),
           
           // Document Details Block (List of Items)
           const Text("Documents", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.teal)),
           const SizedBox(height: 10),
           
           Expanded(
             child: uniqueFiles.isEmpty 
               ? const Text("No files requested.")
               : ListView.builder(
                   itemCount: uniqueFiles.length,
                   itemBuilder: (context, idx) => _buildFileSummaryBox(uniqueFiles[idx] as Map<String, dynamic>),
                 )
           ),
           
           // Action Buttons at Bottom
           Container(
             padding: const EdgeInsets.only(top: 16),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text("Delete Order", style: TextStyle(color: Colors.red)),
                    onPressed: () => deleteOrder(data),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text("Mark as Printed", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
                    ),
                    onPressed: () => markAsPrinted(data),
                  )
               ],
             ),
           )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
          Expanded(child: Text(value ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildFileSummaryBox(Map<String, dynamic> fileData) {
    final rawName = fileData['name']?.toString() ?? '';
    final fileName = Uri.decodeFull(rawName.trim()).replaceAll('%20', ' ');
    final String pages = fileData['pages']?.toString() ?? fileData['pageCount']?.toString() ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade100)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
          const SizedBox(height: 8),
          Row(
            children: [
               Expanded(child: _buildInfoRow("Color", fileData['color'])),
               Expanded(child: _buildInfoRow("Sides", fileData['sides'])),
            ],
          ),
          Row(
            children: [
               Expanded(child: _buildInfoRow("Pages", pages)),
               Expanded(child: _buildInfoRow("Copies", fileData['copies']?.toString())),
            ],
          ),
        ],
      ),
    );
  }
}