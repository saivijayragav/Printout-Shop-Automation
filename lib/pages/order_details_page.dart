import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:cloudflare_r2/cloudflare_r2.dart';
import 'package:printing/printing.dart';

// Services & Config Page Import
import '../Service/printer_check.dart';
import 'printer_setup_page.dart';

class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> orderData;
  const OrderDetailPage({super.key, required this.orderData});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool isLoading = true;
  bool hasError = false;
  late Map<String, dynamic> _orderDetails;

  // 🔥 Prevent multiple print clicks
  bool _isPrinting = false;

  // 🔐 Environment Variables (same pattern as old working code)
  static final accountId = dotenv.env['CLOUDFLARE_ACCOUNT_ID']!;
  static final accessKeyId = dotenv.env['CLOUDFLARE_ACCESS_KEY']!;
  static final secretAccessKey = dotenv.env['CLOUDFLARE_SECRET_KEY']!;
  static final bucket = dotenv.env['CLOUDFLARE_BUCKET']!;

  final String baseUrl = "http://${dotenv.env['API_IP']}/api/orders";

  @override
  void initState() {
    super.initState();
    _orderDetails = widget.orderData;
    _initCloudflare();
    _fetchOrderDetailsFromApi();
  }

  Future<void> _fetchOrderDetailsFromApi() async {
    final orderId = widget.orderData['orderId'] ?? widget.orderData['orderID'];
    if (orderId == null) return;

    try {
      final response = await http.get(Uri.parse('$baseUrl/$orderId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("✅ API Response: $data");
        debugPrint("📋 API Response Keys: ${data.keys.toList()}");
        if (mounted) setState(() => _orderDetails = data);
      }
    } catch (e) {
      debugPrint("❌ API Error: $e");
    }
  }

  Future<void> _initCloudflare() async {
    try {
      await CloudFlareR2.init(accountId: accountId, accessKeyId: accessKeyId, secretAccessKey: secretAccessKey);
    } catch (e) {
      setState(() => hasError = true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _formatTs(dynamic ts) {
    if (ts == null) return 'N/A';
    if (ts is String) {
      try {
        final dt = DateTime.parse(ts);
        return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (e) {
        return ts;
      }
    }
    return 'N/A';
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
      debugPrint("⚠️ getDownloadsDirectory failed: $e");
    }
    downloadsDir ??= await getApplicationDocumentsDirectory();

    // Ensure no trailing separator before adding ours
    String basePath = downloadsDir.path;
    while (basePath.endsWith('\\') || basePath.endsWith('/')) {
      basePath = basePath.substring(0, basePath.length - 1);
    }

    final folder = Directory('$basePath${Platform.pathSeparator}rit xerox shop');
    await folder.create(recursive: true);
    debugPrint("📂 Final download folder: ${folder.path}");
    return folder;
  }

  // ☁️ Fetch file bytes from Cloudflare R2
  // R2 key format: {orderId}{filename} — concatenated directly, no separator
  List<String> _r2KeyCandidates(String rawName) {
    final orderId = _orderDetails['orderId']?.toString() ?? _orderDetails['orderID']?.toString() ?? "";
    final trimmed = rawName.trim();
    final decoded = Uri.decodeFull(trimmed).trim();
    final baseName = decoded.split('/').last;
    final cleanOrderId = orderId.trim();

    var fileKey = decoded;
    if (cleanOrderId.isNotEmpty && decoded.startsWith(cleanOrderId)) {
      final afterId = decoded.substring(cleanOrderId.length);
      if (afterId.startsWith('_') || afterId.startsWith('-') || afterId.startsWith('/')) {
        fileKey = afterId.substring(1);
      } else if (afterId.isNotEmpty) {
        fileKey = afterId;
      }
    }

    final names = <String>[
      if (cleanOrderId.isNotEmpty) '$cleanOrderId$fileKey',
      if (cleanOrderId.isNotEmpty) '${cleanOrderId}_$fileKey',
      if (cleanOrderId.isNotEmpty) '$cleanOrderId$baseName',
      if (cleanOrderId.isNotEmpty) '${cleanOrderId}_$baseName',
      trimmed,
      decoded,
      baseName,
    ];

    final seen = <String>{};
    return names.where((name) => name.isNotEmpty && seen.add(name)).toList();
  }

  bool _bytesMatchFileName(String fileName, Uint8List bytes) {
    final lowerName = fileName.toLowerCase();
    if (bytes.isEmpty) return false;

    if (lowerName.endsWith('.pdf')) {
      return bytes.length >= 4 && String.fromCharCodes(bytes.take(4)) == '%PDF';
    }

    if (lowerName.endsWith('.png')) {
      return bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47 &&
          bytes[4] == 0x0D &&
          bytes[5] == 0x0A &&
          bytes[6] == 0x1A &&
          bytes[7] == 0x0A;
    }

    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      return bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
    }

    return true;
  }

  Future<Uint8List?> _fetchFileBytesFromR2(String rawName) async {
    for (final r2Key in _r2KeyCandidates(rawName)) {
      try {
        debugPrint("Fetching from R2: $r2Key");
        final bytes = await CloudFlareR2.getObject(bucket: bucket, objectName: r2Key);
        if (bytes.isNotEmpty) {
          final typedBytes = Uint8List.fromList(bytes);
          if (!_bytesMatchFileName(rawName, typedBytes)) {
            debugPrint("Invalid file bytes for key: $r2Key");
            continue;
          }
          debugPrint("Fetched valid file: $r2Key (${bytes.length} bytes)");
          return typedBytes;
        }
      } catch (e) {
        debugPrint("Failed to fetch key: $r2Key - $e");
      }
    }
    return null;
  }

  // 🔍 Check if file exists locally without downloading
  Future<({File file, Uint8List bytes})?> _getLocalFileIfExists(String rawName) async {
    try {
      String orderId = _orderDetails['orderId']?.toString() ?? 'unknown';
      orderId = orderId.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

      String cleanName = rawName.split('/').last;
      cleanName = Uri.decodeFull(cleanName.trim()).replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      if (cleanName.isEmpty) cleanName = 'file_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final folder = await _getCustomDownloadFolder();
      final orderFolder = Directory('${folder.path}${Platform.pathSeparator}$orderId');
      final file = File('${orderFolder.path}${Platform.pathSeparator}$cleanName');

      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (_bytesMatchFileName(cleanName, bytes)) {
          debugPrint("⚡ Local file found: ${file.path}");
          return (file: file, bytes: bytes);
        }
        debugPrint("Invalid local cache, re-downloading: ${file.path}");
        await file.delete();
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error checking local file: $e");
      return null;
    }
  }

  // 💾 Download file to local disk and return (filePath, bytes)
  Future<({File file, Uint8List bytes})?> _downloadToLocal(String rawName) async {
    try {
      debugPrint("💾 Preparing to save: $rawName");

      final folder = await _getCustomDownloadFolder();

      // Sanitize orderId for folder name
      String orderId = _orderDetails['orderId']?.toString() ?? 'unknown';
      orderId = orderId.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

      final orderFolder = Directory('${folder.path}${Platform.pathSeparator}$orderId');
      await orderFolder.create(recursive: true);

      // Sanitize filename
      String cleanName = rawName.split('/').last;
      cleanName = Uri.decodeFull(cleanName.trim()).replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      if (cleanName.isEmpty) cleanName = 'file_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final file = File('${orderFolder.path}${Platform.pathSeparator}$cleanName');

      // 🧠 Check Cache
      if (await file.exists()) {
        final existingBytes = await file.readAsBytes();
        if (_bytesMatchFileName(cleanName, existingBytes)) {
          debugPrint("⚡ Cache hit: ${file.path}");
          return (file: file, bytes: existingBytes);
        }
        debugPrint("Invalid local cache, re-downloading: ${file.path}");
        await file.delete();
      }

      // ☁️ Fetch
      final bytes = await _fetchFileBytesFromR2(rawName);
      if (bytes == null || bytes.isEmpty) {
        debugPrint("❌ Failed to fetch bytes for: $rawName");
        return null;
      }

      // 💾 Save & Verify
      await file.writeAsBytes(bytes, flush: true);

      final savedBytes = await file.readAsBytes();
      if (await file.exists() && _bytesMatchFileName(cleanName, savedBytes)) {
        debugPrint("✅ Saved successfully: ${file.path}");
        return (file: file, bytes: savedBytes);
      } else {
        debugPrint("❌ Save failed verification: ${file.path}");
        return null;
      }
    } catch (e, stack) {
      debugPrint("❌ _downloadToLocal error: $e\n$stack");
      return null;
    }
  }

  // 💾 Download-only action (button)
  Future<void> _downloadFileOnly(String rawName) async {
    try {
      final result = await _downloadToLocal(rawName);
      if (result == null) throw Exception("Failed to fetch file from server.");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Saved to: ${result.file.path}"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Open the downloaded file
        if (Platform.isWindows) {
          try {
            // Add small delay to ensure file is fully written
            await Future.delayed(const Duration(milliseconds: 300));

            // Use rundll32 to open the file reliably
            await Process.run('rundll32.exe', ['url.dll,FileProtocolHandler', result.file.path]);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Opening file..."),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            debugPrint("Failed to open file: $e");
            // Try alternative method if first fails
            try {
              await Process.run('explorer.exe', [result.file.path]);
            } catch (e2) {
              debugPrint("Alternative open also failed: $e2");
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Download Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Download failed: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 👁️ Preview PDF/Image file in a dialog
  Future<void> _previewFile(String rawName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final bytes = await _fetchFileBytesFromR2(rawName);
      if (mounted) Navigator.pop(context);

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
        // Open PDF with system default viewer
        try {
          final tempDir = await getTemporaryDirectory();
          String fileName = rawName.split('/').last;
          fileName = Uri.decodeFull(fileName.trim()).replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
          if (!fileName.toLowerCase().endsWith('.pdf')) {
            fileName = '$fileName.pdf';
          }
          final tempFile = File('${tempDir.path}${Platform.pathSeparator}$fileName');
          await tempFile.writeAsBytes(bytes, flush: true);

          // Verify file was written correctly
          if (!await tempFile.exists() || await tempFile.length() == 0) {
            throw Exception("Failed to save PDF to temporary location");
          }

          // Open with Windows default PDF viewer
          if (Platform.isWindows) {
            await Process.run('cmd', ['/c', 'start', '""', tempFile.path], runInShell: true);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ Opening PDF..."),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          debugPrint("❌ Error opening PDF: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("❌ Could not open PDF: $e"),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
        return;
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
          SnackBar(content: Text("❌ Preview failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 🖨️ Print to a specific printer chosen by the user
  Future<void> _printToSelectedPrinter(String rawName, int copies, Printer selectedPrinter) async {
    if (_isPrinting) return; // 🚫 prevent multiple clicks
    _isPrinting = true;

    try {
      final lowerName = rawName.toLowerCase();
      if (!lowerName.endsWith('.pdf')) throw Exception("Only PDF files can be printed.");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sending to printer..."),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }

      unawaited(_performPrintJob(rawName, copies, selectedPrinter));

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isPrinting = false;
    }
  }

  // 🚀 Background print job — INSTANT: cache-first, parallel copies, background save
  Future<void> _performPrintJob(String rawName, int copies, Printer selectedPrinter) async {
    try {
      Uint8List? bytes;

      // ⚡ STEP 1: Check local cache FIRST (instant if cached)
      final localResult = await _getLocalFileIfExists(rawName);
      if (localResult != null) {
        bytes = localResult.bytes;
        debugPrint("⚡ Cache hit — printing instantly!");
      } else {
        // ☁️ STEP 2: Fetch from R2 only if not cached
        debugPrint("📥 Cache miss — fetching from R2...");
        bytes = await _fetchFileBytesFromR2(rawName);
        if (bytes == null || bytes.isEmpty) throw Exception("Failed to fetch file");
        debugPrint("✅ Fetched: ${bytes.length} bytes");

        // 💾 STEP 3: Save to local folder in BACKGROUND (don't block printing)
        unawaited(_saveToLocalInBackground(rawName, bytes));
      }

      // 🚀 STEP 4: Fire ALL copies — NO AWAIT (fire-and-forget to OS spooler)
      final jobName = 'Job_${_orderDetails['orderId']}_${rawName.split('/').last}';
      for (int c = 0; c < copies; c++) {
        Printing.directPrintPdf(
          printer: selectedPrinter,
          onLayout: (_) => Future.value(bytes),
          name: '$jobName Copy ${c + 1}',
          usePrinterSettings: true,
        );
      }

      debugPrint("✅ All $copies jobs sent!");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ $copies job(s) sent to printer"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      debugPrint("❌ Print error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // 💾 Save bytes to local folder in background (never blocks caller)
  Future<void> _saveToLocalInBackground(String rawName, Uint8List bytes) async {
    try {
      final folder = await _getCustomDownloadFolder();
      String orderId = _orderDetails['orderId']?.toString() ?? 'unknown';
      orderId = orderId.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final orderFolder = Directory('${folder.path}${Platform.pathSeparator}$orderId');
      await orderFolder.create(recursive: true);

      String cleanName = rawName.split('/').last;
      cleanName = Uri.decodeFull(cleanName.trim()).replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      if (cleanName.isEmpty) cleanName = 'file_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final file = File('${orderFolder.path}${Platform.pathSeparator}$cleanName');
      if (!await file.exists()) {
        await file.writeAsBytes(bytes, flush: true);
        debugPrint("💾 Background save complete: ${file.path}");
      }
    } catch (e) {
      debugPrint("⚠️ Background save failed (non-critical): $e");
    }
  }

  // 🖨️ Show printer selection dialog
  void _showPrinterSelectionDialog(Map<String, dynamic> fileData) async {
    final systemPrinters = await Printing.listPrinters();

    // 🔥 FILTER ONLY REAL PRINTERS
    final availablePrinters = systemPrinters.where((p) {
      final name = p.name.toLowerCase();
      return p.isAvailable &&
          !name.contains("pdf") &&
          !name.contains("fax") &&
          !name.contains("onenote");
    }).toList();

    if (!mounted) return;

    if (availablePrinters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ No physical printers available"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final rawName = fileData['name']?.toString() ?? '';
    final int copies = int.tryParse(fileData['copies']?.toString() ?? '1') ?? 1;

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
                  _printToSelectedPrinter(rawName, copies, printer);
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

  // 🔥 Smart Route & Print all files
  Future<void> _downloadAndSilentPrint(List<dynamic> files) async {
    if (_isPrinting) return; // 🚫 prevent spam clicking
    _isPrinting = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 8),
            Text(
              "Sending Jobs to Printers...",
              style: TextStyle(color: Colors.white, decoration: TextDecoration.none, fontSize: 13),
            )
          ],
        ),
      ),
    );

    try {
      int totalJobsSent = 0;

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

        final jobFuture = _sendJobToSmartPrinter(
          rawName: rawName,
          copies: copies,
          isColorJob: isColorJob,
          isDuplexJob: isDuplexJob,
          documentPages: documentPages,
        );

        printFutures.add(jobFuture);
      }

      final results = await Future.wait(printFutures, eagerError: false);
      totalJobsSent = results.fold(0, (sum, sent) => sum + sent);

      if (mounted && Navigator.canPop(context)) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Sent $totalJobsSent job(s) to printers"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      _isPrinting = false;
    }
  }

  // 🔥 Send single job to smart router — cache-first, parallel, background save
  Future<int> _sendJobToSmartPrinter({
    required String rawName,
    required int copies,
    required bool isColorJob,
    required bool isDuplexJob,
    required int documentPages,
  }) async {
    try {
      Uint8List? bytes;

      // ⚡ STEP 1: Check local cache FIRST (instant if cached)
      final localResult = await _getLocalFileIfExists(rawName);
      if (localResult != null) {
        bytes = localResult.bytes;
        debugPrint("⚡ Cache hit for: $rawName");
      } else {
        // ☁️ STEP 2: Fetch from R2 only if not cached
        debugPrint("📥 Cache miss, fetching: $rawName");
        bytes = await _fetchFileBytesFromR2(rawName);
        if (bytes == null || bytes.isEmpty) {
          debugPrint("❌ Failed to fetch: $rawName");
          return 0;
        }
        // 💾 Save in background (don't block printing)
        unawaited(_saveToLocalInBackground(rawName, bytes));
      }

      // 🔥 STEP 3: Send to smart router immediately
      debugPrint("🔥 Routing $rawName to printer...");
      int sent = await PrinterChecker.printJobAutomated(
        bytes: bytes,
        isColor: isColorJob,
        isDuplex: isDuplexJob,
        copies: copies,
        documentPages: documentPages,
        jobNamePrefix: 'Job_${_orderDetails['orderId']}',
      );

      debugPrint("✅ Job sent: $rawName ($sent copies)");
      return sent;
    } catch (e) {
      debugPrint("❌ Job error: $rawName - $e");
      return 0;
    }
  }

  Widget buildDetailBox(String label, String? value) {
    if (value == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8), color: Colors.white),
      child: RichText(text: TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16), children: [TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black))])),
    );
  }

  Widget buildFileSummary(Map<String, dynamic> fileData, int index) {
    final rawName = fileData['name']?.toString() ?? '';
    final fileName = Uri.decodeFull(rawName.trim()).replaceAll('%20', ' ');
    final String pages = fileData['pages']?.toString() ?? fileData['pageCount']?.toString() ?? 'N/A';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: Colors.blueGrey.shade300, width: 1.5), borderRadius: BorderRadius.circular(12), color: const Color(0xFFF8F9FB), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("📄 File ${index + 1}: $fileName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          buildDetailBox("Color", fileData['color']),
          buildDetailBox("Side", fileData['sides']),
          buildDetailBox("Pages", pages),
          buildDetailBox("Binding", fileData['binding']),
          buildDetailBox("Copies", fileData['copies']?.toString()),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text("Preview"),
                onPressed: () => _previewFile(rawName),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100, foregroundColor: Colors.blue.shade800),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.download, size: 18),
                label: const Text("Download"),
                onPressed: () => _downloadFileOnly(rawName),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple.shade100, foregroundColor: Colors.deepPurple),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.print, size: 18),
                label: const Text("Choose Printer"),
                onPressed: () => _showPrinterSelectionDialog(fileData),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade100, foregroundColor: Colors.teal.shade800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _orderDetails;
    final files = data['files'] as List<dynamic>? ?? [];
    final seen = <String>{};
    final uniqueFiles = files.where((file) {
      final name = file['name']?.toString() ?? '';
      if (seen.contains(name)) return false;
      seen.add(name); return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'), backgroundColor: Colors.blue, foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configure Printers',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PrinterSetupPage()));
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text("Error loading configuration."))
              : Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("🧾 Order Summary", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            buildDetailBox("Order ID", data['orderId']?.toString()),
                            buildDetailBox("Date/Time", _formatTs(data['timestamp'])),
                            buildDetailBox("Name", data['userName']),
                            buildDetailBox("Phone", data['phoneNumber']),
                            const SizedBox(height: 16),
                            const Divider(thickness: 1),
                            ...List.generate(uniqueFiles.length, (i) => buildFileSummary(uniqueFiles[i] as Map<String, dynamic>, i)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20, left: 0, right: 0,
                      child: Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.print, color: Colors.black),
                          label: const Text("Smart Route & Print", style: TextStyle(color: Colors.black)),
                          onPressed: () => _downloadAndSilentPrint(uniqueFiles),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
