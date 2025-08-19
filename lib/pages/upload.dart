import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:RITArcade/components/total_page.dart';
import '../components/randomcode.dart';
import 'orderconfig.dart';
import '../components/newtypes.dart';
import '../services/setting_service.dart'; // Import global setting

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  List<FileData> files = [];
  bool isLoading = false;
  int pages = 0;
  double size = 0;
  static const int SIZE_LIMIT = 10;

  Future<int> getPdfPageCount(String path) async {
    try{
    final file = File(path);
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    return document.pages.count;
  } catch (e){
      print("Getting pages count faild");
      rethrow;
    }
  }

  void addFiles(List<FileData> newFiles, Sides side, PrintColor color, BindingType binding) {
    for (var file in newFiles) {
      file.color = color == PrintColor.color ? "Color" : "BW";
      file.sides = side == Sides.four ? "Four sides" : side == Sides.both ? "Double side" : "Single side";
      file.binding = binding == BindingType.soft
          ? "Soft Binding"
          : binding == BindingType.spiral
              ? "Spiral Binding"
              : "No Binding";
      files.add(file);
    }
    setState(() {});
  }

  Future<void> nextpage() async {
    String id = generateCode(4);
    if(pages >= 30){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TotalPage(
          order: OrderData(
            orderId: id,
            files: files,
            pages: pages,
            price: 0,
            time: 0,
          ),
        ),
      ),
    );
  } else{
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Pages criteria not met"),
          content: const Text("The order should have atleast 30 pages."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  Future<void> tryGetFilesWithCheck() async {
    if (!SettingsService.liveOrdersEnabled) {
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: const Text("Admin Closed"),
              content: const Text(
                  "Live Orders are currently disabled by the admin."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            ),
      );
      return;
    }
    try {
      await getFiles();
    } catch (e) {
      debugPrint("Something went wrong while getting files");
      showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text("Something went wrong"),
            content: Text("We couldn’t process your file. Please try again."),
          )
      );
    }
  }

  Future<void> getFiles() async {
    setState(() {
      isLoading = true;
    });
    FilePickerResult? result;
    try {
        result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: true,
        allowMultiple: false,
        allowedExtensions: ['pdf', 'jpg', 'png'],
      );
    } catch (e){
      debugPrint("Error fetching files");
      isLoading = false;
      return;
    }

    if (result != null) {
      double temp = 0;
      for (var file in result.files) {
        temp += file.size / (1024 * 1024);
      }

      if (temp + size > SIZE_LIMIT) {
        setState(() {
          isLoading = false;
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("File Size Limit Exceeded"),
              content: const Text("The combined file size exceeds the 10MB limit."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            );
          },
        );
        return;
      }

      List<FileData> newfiles = [];
      int newPageCount = 0;
      for (var file in result.files) {
        var pagecount = 1;
        try{
        if (file.extension == "pdf") {
          pagecount = await getPdfPageCount(file.path!);
        }
        } catch(e){
          debugPrint("Failed to read PDF ${file.name}: $e");
          continue;
        }
        newPageCount += pagecount;
        pages += pagecount;
        double sizep = file.size / (1024 * 1024);
        size += sizep;
        if (file.bytes != null) {
          newfiles.add(FileData(
            name: file.name,
            size: sizep,
            pages: pagecount,
            bytes: file.bytes!,
            copies: 1,
            type: file.extension!,
            path: file.path!,
            sides: "Both sides",
            color: "Black and White",
            binding: "No Binding",
          ));
        }
      }

      if (newfiles.isNotEmpty && mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => PrintConfigDialog(
            pages: newPageCount,
            add: addFiles,
            files: newfiles,
          ),
        );
      }

      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void delete(int ind) {
    size -= files[ind].size;
    pages -= files[ind].pages * files[ind].copies;
    files.removeAt(ind);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: tryGetFilesWithCheck,
                          icon: const Icon(CupertinoIcons.plus),
                        ),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              Text(
                                'Combined size should be less than 10 MB',
                                style: TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    const Divider(thickness: 2),
                    const SizedBox(height: 9),
                    Expanded(
                      child: ListView.builder(
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          if (files[index].path.isEmpty) return const SizedBox.shrink();
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          files[index].name,
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                        Text(
                                          '${(files[index].size.toStringAsFixed(2))} MB',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        Row(
                                          children: [
                                            Text(files[index].color, style: const TextStyle(fontSize: 10)),
                                            Text(' - ${files[index].sides}', style: const TextStyle(fontSize: 10)),
                                            if (files[index].binding != "No Binding")
                                              Text(' - ${files[index].binding}',
                                                  style: const TextStyle(fontSize: 10)),
                                            const Expanded(child: SizedBox()),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          if (files[index].copies > 1) {
                                            setState(() {
                                              files[index].copies -= 1;
                                              pages -= files[index].pages;
                                            });
                                          }
                                        },
                                        icon: const Icon(CupertinoIcons.minus),
                                      ),
                                      Text(files[index].copies.toString()),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            files[index].copies += 1;
                                            pages += files[index].pages;
                                          });
                                        },
                                        icon: const Icon(CupertinoIcons.plus),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            delete(index);
                                          });
                                        },
                                        icon: const Icon(CupertinoIcons.delete),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Divider(thickness: 2),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Size: ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text("${size.toStringAsFixed(2)} MB", style: const TextStyle(fontSize: 20)),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('Pages: ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text("$pages", style: const TextStyle(fontSize: 20)),
                              ],
                            ),
                          ],
                        ),
                        const Expanded(child: SizedBox()),
                        if (files.isNotEmpty)
                          Align(
                            alignment: AlignmentDirectional.bottomEnd,
                            child: FloatingActionButton(
                              backgroundColor: const Color(0xFFE2E2B6),
                              onPressed: nextpage,
                              child: const Icon(CupertinoIcons.arrow_right, color: Colors.black),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
