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
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';


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
  bool _isLoadingDetails = false;
  // Printer configs
  List<PrinterConfig> _availablePrinters = [];
  bool _isPrinterReady = false;

  // Per-file download/print progress tracking
  final Map<String, double> _fileProgress = {};  // fileName -> 0.0 to 1.0
  final Map<String, String> _fileStatus = {};    // fileName -> status text

  // Cloudflare Getters
  String get baseUrl => "${dotenv.env['API_IP']}/api/orders/summary";
  String get apiBase => "${dotenv.env['API_IP']}/api/orders";
  String get accountId => dotenv.env['CLOUDFLARE_ACCOUNT_ID'] ?? '';
  String get accessKeyId => dotenv.env['CLOUDFLARE_ACCESS_KEY'] ?? '';
  String get secretAccessKey => dotenv.env['CLOUDFLARE_SECRET_KEY'] ?? '';
  String get bucket => dotenv.env['CLOUDFLARE_BUCKET'] ?? '';

  @override
  void initState() {
    super.initState();
    _initCloudflare();
    _loadPrinters();
    fetchOrdersFromApi();
  }

  Future<void> _initCloudflare() async {
    try {
      if (accountId.isEmpty || accessKeyId.isEmpty) {
        debugPrint("⚠️ WARNING: Cloudflare keys are empty! Check your .env file.");
        return;
      }
      await CloudFlareR2.init(
        accountId: accountId,
        accessKeyId: accessKeyId,
        secretAccessKey: secretAccessKey
      );
      debugPrint("✅ Cloudflare R2 Initialized Successfully.");
    } catch (e) {
      debugPrint("❌ Cloudflare Init Error: $e");
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

  void _fetchOrderDetails(String orderId) async {
    setState(() => _isLoadingDetails = true);
    try {
      debugPrint("📂 Fetching order details from API for: $orderId");

      // Use backend API to get full order details with real file metadata
      final response = await http.get(Uri.parse('$apiBase/info/$orderId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _selectedOrder = {
              ...?_selectedOrder,
              ...data,
            };
          });
          debugPrint("✅ Order details loaded. Files: ${data['files']?.length ?? 0}");
        }
      } else {
        debugPrint("❌ API returned ${response.statusCode}: ${response.body}");
        if (mounted) {
          setState(() {
            _selectedOrder = {...?_selectedOrder, 'files': []};
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Exception fetching order details: $e");
      if (mounted) {
        setState(() {
          _selectedOrder = {...?_selectedOrder, 'files': []};
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> fetchOrdersFromApi() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Sort: Newest first based on timestamp
        data.sort((a, b) {
           String tA = a['timestamp'] ?? '';
           String tB = b['timestamp'] ?? '';
           return tB.compareTo(tA);
        });

        setState(() {
          _cachedOrders = data;
          _isLoading = false;
          if (_selectedOrder == null && _cachedOrders.isNotEmpty) {
            _selectedOrder = _cachedOrders.first;
            debugPrint("📋 First order selected: ${_selectedOrder!['orderId']}");
            debugPrint("📄 Files in summary: ${_selectedOrder!['files']}");
            // Try to fetch full details, but continue if it fails
            _fetchOrderDetails(_selectedOrder!['orderId'].toString());
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
          const SnackBar(content: Text("API connection error. Check terminal logs."), backgroundColor: Colors.red),
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
      final DateTime dt = DateTime.parse(timestampStr).toLocal();
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete failed. Check terminal logs.")));
      }
    }
  }

  // --- Cloudflare R2 Logic (Simplified) ---
  Future<Uint8List?> _fetchFileBytesFromR2(dynamic fileSource, String orderIdStr) async {
    final String rawName;
    if (fileSource is Map) {
      rawName = fileSource['name']?.toString() ?? '';
    } else {
      rawName = fileSource.toString();
    }

    final variants = {"", rawName.trim(), Uri.decodeFull(rawName.trim())};

    for (final name in variants) {
      try {
        debugPrint("☁️ Fetching from R2: $name");
        final bytes = await CloudFlareR2.getObject(bucket: bucket, objectName: name);
        if (bytes.isNotEmpty) {
          debugPrint("✅ Fetched: $name (${bytes.length} bytes)");
          return Uint8List.fromList(bytes);
        }
      } catch (e) {
        debugPrint("⚠️ Failed key: $name");
      }
    }
    debugPrint("❌ All R2 keys failed for: $rawName");
    return null;
  }

  Future<Directory> _getCustomDownloadFolder() async {
    Directory? downloadsDir;
    try {
      if (Platform.isWindows) {
        downloadsDir = await getDownloadsDirectory();
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      downloadsDir = await getApplicationDocumentsDirectory();
    }
    downloadsDir ??= await getApplicationDocumentsDirectory();

    final folder = Directory('${downloadsDir.path}${Platform.pathSeparator}rit xerox shop');
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder;
  }

  String _cleanPathPart(String value, {String fallback = 'file.pdf'}) {
    final cleaned = Uri.decodeFull(value.trim()).replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return cleaned.isEmpty ? fallback : cleaned;
  }

  Future<({File file, Uint8List bytes})?> _prepareLocalFile(dynamic fileSource, String orderIdStr) async {
    final folder = await _getCustomDownloadFolder();
    final cleanOrderId = _cleanPathPart(orderIdStr, fallback: 'unknown');
    final orderFolder = Directory('${folder.path}${Platform.pathSeparator}$cleanOrderId');
    if (!await orderFolder.exists()) await orderFolder.create(recursive: true);

    final fileName = fileSource is Map ? (fileSource['name']?.toString() ?? '') : fileSource.toString();
    final cleanNameLocal = _cleanPathPart(
      fileName.split('/').last,
      fallback: 'file_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    final file = File('${orderFolder.path}${Platform.pathSeparator}$cleanNameLocal');

    if (await file.exists()) {
      final existingBytes = await file.readAsBytes();
      if (existingBytes.isNotEmpty) {
        debugPrint("Cache hit: ${file.path}");
        return (file: file, bytes: existingBytes);
      }
    }

    final bytes = await _fetchFileBytesFromR2(fileSource, orderIdStr);
    if (bytes == null || bytes.isEmpty) return null;

    await file.writeAsBytes(bytes, flush: true);
    if (await file.exists() && await file.length() > 0) {
      debugPrint("Saved locally: ${file.path}");
      return (file: file, bytes: bytes);
    }
    return null;
  }

  Future<void> _downloadFileOnly(dynamic fileSource, String orderIdStr) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⏳ Downloading from Cloudflare..."), duration: Duration(seconds: 1)));

    try {
      final result = await _prepareLocalFile(fileSource, orderIdStr);
      if (result == null) throw Exception("File not found in Cloudflare bucket.");

      debugPrint("Download ready locally: ${result.file.path}");
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Saved to: ${result.file.path}"), backgroundColor: Colors.green));
          if (Platform.isWindows) Process.run('explorer.exe', ['/select,', result.file.path]);
      }
    } catch (e) {
      debugPrint("Download failed: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Download failed. Check terminal logs."), backgroundColor: Colors.red));
    }
  }

  /// 🖨️ INSTANT silent print: Fetch from R2 → Fire all copies in parallel → Notify
  Future<void> _printToSelectedPrinter(Map<String, dynamic> fileData, String orderIdStr, Printer selectedPrinter) async {
    final rawName = fileData['name']?.toString() ?? '';
    final int copies = int.tryParse(fileData['copies']?.toString() ?? '1') ?? 1;
    final fileKey = '${orderIdStr}_$rawName';

    // Show inline status
    if (mounted) {
      setState(() {
        _fileProgress[fileKey] = 0.3;
        _fileStatus[fileKey] = 'Fetching file...';
      });
    }

    try {
      // ☁️ STEP 1: Fetch bytes directly from R2 (no local storage)
      debugPrint("📥 Fetching '$rawName' from R2...");
      final bytes = await _fetchFileBytesFromR2(fileData, orderIdStr);

      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          setState(() {
            _fileProgress.remove(fileKey);
            _fileStatus[fileKey] = '❌ Download failed';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Failed to fetch file"), backgroundColor: Colors.red),
          );
        }
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _fileStatus.remove(fileKey));
        });
        return;
      }

      // Update progress
      if (mounted) {
        setState(() {
          _fileProgress[fileKey] = 0.7;
          _fileStatus[fileKey] = 'Sending $copies copy(s) to ${selectedPrinter.name}...';
        });
      }

      // 🚀 STEP 2: Fire ALL copies — NO AWAIT (fire-and-forget to OS spooler)
      debugPrint("🖨️ Sending $copies copies to ${selectedPrinter.name}...");
      for (int c = 0; c < copies; c++) {
        Printing.directPrintPdf(
          printer: selectedPrinter,
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'Job_${orderIdStr}_${rawName.split('/').last}_Copy_${c + 1}',
          usePrinterSettings: true,
        );
      }

      // ✅ STEP 3: Notify IMMEDIATELY (don't wait for print to finish)
      debugPrint("✅ $copies job(s) dispatched to ${selectedPrinter.name}");
      if (mounted) {
        setState(() {
          _fileProgress[fileKey] = 1.0;
          _fileStatus[fileKey] = '✅ Sent $copies job(s) to ${selectedPrinter.name}';
          _printStatus = "Queued to ${selectedPrinter.name}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Sent $copies job(s) to ${selectedPrinter.name}"), backgroundColor: Colors.green),
        );
      }

      // Clear status after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() {
          _fileStatus.remove(fileKey);
          _fileProgress.remove(fileKey);
        });
      });

    } catch (e) {
      debugPrint("❌ Print failed for '$rawName': $e");
      if (mounted) {
        setState(() {
          _fileProgress.remove(fileKey);
          _fileStatus[fileKey] = '❌ Failed: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Print failed: $e"), backgroundColor: Colors.redAccent),
        );
      }
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _fileStatus.remove(fileKey));
      });
    }
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

      // Send all jobs in PARALLEL for maximum speed
      final printFutures = <Future<int>>[];

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

        // Create async job (fetch from R2 + print — no local storage)
        printFutures.add(() async {
          debugPrint("📥 Fetching '$rawName' from R2...");
          final bytes = await _fetchFileBytesFromR2(fileData, orderIdStr);
          if (bytes == null || bytes.isEmpty) {
            debugPrint("❌ Failed to fetch '$rawName' from R2");
            return 0;
          }

          int sent = await PrinterChecker.printJobAutomated(
            bytes: bytes,
            isColor: isColorJob,
            isDuplex: isDuplexJob,
            copies: copies,
            documentPages: documentPages,
            jobNamePrefix: 'Job_$orderIdStr',
          );
          debugPrint("✅ Sent $sent job(s) for '$rawName'");
          return sent;
        }());
      }

      // Wait for all parallel jobs to complete
      final results = await Future.wait(printFutures, eagerError: false);
      totalJobsSent = results.fold(0, (sum, sent) => sum + sent);

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Complete! Routed $totalJobsSent jobs."), backgroundColor: Colors.green));
        setState(() => _printStatus = "Pending / Queued to Printer");
      }

    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      debugPrint("❌ Smart print failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Print failed. Check terminal logs."), backgroundColor: Colors.redAccent));
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
          // LEFT PANEL
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

          // RIGHT PANEL (Order Details Page/View)
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
              final String oid = order['orderId']?.toString() ?? 'N/A';
              if (oid != 'N/A') {
                debugPrint("📋 Order tapped: $oid");
                setState(() {
                  _selectedOrder = order;
                  _printStatus = "";
                });
                // Always fetch fresh details when order is selected
                _fetchOrderDetails(oid);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

  // --- ORDER DETAIL VIEW (Right Panel) ---

  Widget _buildOrderDetailsView() {
    final data = _selectedOrder!;
    final orderIdStr = data['orderId']?.toString() ?? 'N/A';

    debugPrint("🔍 Building Order Details View for Order: $orderIdStr");
    debugPrint("📊 Data keys: ${data.keys.toList()}");
    debugPrint("📄 Raw files data: ${data['files']}");
    debugPrint("📄 Raw files type: ${data['files'].runtimeType}");

    // Extracting files reliably
    List<dynamic> files = [];
    try {
      if (data['files'] != null) {
        if (data['files'] is String && (data['files'] as String).isNotEmpty) {
          debugPrint("🔄 Files is String, attempting to decode...");
          files = json.decode(data['files']);
          debugPrint("✅ Successfully decoded files from String: ${files.length} items");
        } else if (data['files'] is List) {
          files = List.from(data['files']);
          debugPrint("✅ Files is already a List: ${files.length} items");
        } else if (data['files'] is Map) {
          // If files is a single map, wrap it in a list
          files = [data['files']];
          debugPrint("✅ Files is a Map, wrapped in list");
        }
      }
    } catch (e) {
      debugPrint("❌ Error processing files: $e");
      files = [];
    }

    debugPrint("📊 Extracted files count: ${files.length}");
    if (files.isNotEmpty) {
      debugPrint("📄 First file: ${files.first}");
    }

    // Deduplicate files safely to prevent duplicates in UI
    final seen = <String>{};
    final uniqueFiles = files.where((file) {
      if (file is! Map) {
        debugPrint("⚠️ Skipping non-Map file: $file");
        return false;
      }
      final name = file['name']?.toString() ?? '';
      if (name.isEmpty) {
        debugPrint("⚠️ Skipping file with empty name");
        return false;
      }
      if (seen.contains(name)) {
        debugPrint("⚠️ Skipping duplicate file: $name");
        return false;
      }
      seen.add(name);
      debugPrint("✅ Including file: $name");
      return true;
    }).toList();

    debugPrint("📊 Unique files count: ${uniqueFiles.length}");

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

           if (_printStatus.isNotEmpty)
             Chip(
               label: Text(_printStatus, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               backgroundColor: _printStatus.contains('Done') ? Colors.green : Colors.amber.shade800,
             ),

           const SizedBox(height: 20),

           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.teal.shade200)),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text("Customer Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.teal)),
                 const SizedBox(height: 10),

                 // UPDATED to map correctly to your JSON response
                 _buildInfoRow('Name', data['userName']),
                 _buildInfoRow('Mobile Number', data['phoneNumber']),
                 _buildInfoRow('Total Pages', data['totalPages']?.toString()),
                 _buildInfoRow('Total Price', data['totalPrice'] != null ? '₹${data['totalPrice']}' : 'N/A'),
                 _buildInfoRow('Date & Time', formatTimestamp(data['timestamp'])),
               ],
             ),
           ),
           const SizedBox(height: 24),

           const Text("Documents", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.teal)),
           const SizedBox(height: 10),

           Expanded(
             child: _isLoadingDetails
               ? const Center(child: CircularProgressIndicator())
               : uniqueFiles.isEmpty
                 ? const Center(child: Text("No documents found for this order", style: TextStyle(color: Colors.grey, fontSize: 16)))
                 : ListView.builder(
                     itemCount: uniqueFiles.length,
                     itemBuilder: (context, idx) => _buildFileSummaryBox(uniqueFiles[idx] as Map<String, dynamic>, orderIdStr),
                   )
           ),

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

  /// Preview a PDF file in a dialog
  Future<void> _previewFile(dynamic fileSource, String orderIdStr) async {
    final rawName = fileSource is Map ? fileSource['name']?.toString() ?? '' : fileSource.toString();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final bytes = await _fetchFileBytesFromR2(fileSource, orderIdStr);
      if (mounted) Navigator.pop(context); // close loading

      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Could not fetch file for preview"), backgroundColor: Colors.red),
          );
        }
        return;
      }

      final lowerName = rawName.toLowerCase();
      final isPdf = lowerName.endsWith('.pdf');
      final isImage = lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg') || lowerName.endsWith('.png');

      if (!mounted) return;

      if (isPdf) {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            insetPadding: const EdgeInsets.all(20),
            child: SizedBox(
              width: MediaQuery.of(ctx).size.width * 0.8,
              height: MediaQuery.of(ctx).size.height * 0.85,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: Colors.indigo,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(Uri.decodeFull(rawName.split('/').last), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PdfPreview(
                      build: (_) async => bytes,
                      allowPrinting: false,
                      allowSharing: false,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                      useActions: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (isImage) {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(Uri.decodeFull(rawName.split('/').last)),
                  automaticallyImplyLeading: false,
                  actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))],
                ),
                Image.memory(bytes, fit: BoxFit.contain),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Preview not supported for this file type. Use Download instead.")),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      debugPrint("❌ Preview error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Preview failed. Check terminal logs."), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildFileSummaryBox(Map<String, dynamic> fileData, String orderIdStr) {
    final rawName = fileData['name']?.toString() ?? '';
    final fileName = Uri.decodeFull(rawName.trim()).replaceAll('%20', ' ');
    final String pages = fileData['pages']?.toString() ?? fileData['pageCount']?.toString() ?? 'N/A';
    final fileKey = '${orderIdStr}_$rawName';
    final double? progress = _fileProgress[fileKey];
    final String? status = _fileStatus[fileKey];
    final bool isProcessing = progress != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isProcessing ? Colors.blue.shade50 : Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isProcessing ? Colors.blue.shade300 : Colors.blueGrey.shade100)
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

          // Inline progress bar (shown during download/print)
          if (isProcessing || status != null) ...[
            const SizedBox(height: 10),
            if (isProcessing)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress! >= 1.0 ? Colors.green : Colors.blue,
                  ),
                ),
              ),
            if (status != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: status.contains('Done') ? Colors.green.shade700
                         : status.contains('Failed') ? Colors.red.shade700
                         : Colors.blue.shade700,
                  ),
                ),
              ),
            if (isProcessing)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                ),
              ),
          ],

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Preview button
              ElevatedButton.icon(
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text("Preview"),
                onPressed: isProcessing ? null : () => _previewFile(fileData, orderIdStr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade100,
                  foregroundColor: Colors.blue.shade800,
                ),
              ),
              const SizedBox(width: 8),
              // Download button
              ElevatedButton.icon(
                icon: const Icon(Icons.download, size: 18),
                label: const Text("Download"),
                onPressed: isProcessing ? null : () => _downloadFileOnly(fileData, orderIdStr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade100,
                  foregroundColor: Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 8),
              // Print to specific printer button
              ElevatedButton.icon(
                icon: const Icon(Icons.print, size: 18),
                label: const Text("Choose Printer"),
                onPressed: isProcessing ? null : () => _showPrinterSelectionDialog(fileData, orderIdStr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade100,
                  foregroundColor: Colors.teal.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show dialog listing available printers for user to pick one
  void _showPrinterSelectionDialog(Map<String, dynamic> fileData, String orderIdStr) async {
    final systemPrinters = await Printing.listPrinters();
    final availablePrinters = systemPrinters.where((p) => p.isAvailable).toList();

    if (!mounted) return;

    if (availablePrinters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ No printers available"), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Select Printer"),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availablePrinters.length,
            itemBuilder: (_, i) {
              final printer = availablePrinters[i];
              return ListTile(
                leading: Icon(Icons.print, color: printer.isDefault ? Colors.green : Colors.grey),
                title: Text(printer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(printer.isDefault ? "Default Printer" : "Available"),
                onTap: () {
                  Navigator.pop(ctx);
                  _printToSelectedPrinter(fileData, orderIdStr, printer);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        ],
      ),
    );
  }
}
