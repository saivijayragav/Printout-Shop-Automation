import 'dart:io';
import 'package:flutter/material.dart';

class CartPage extends StatelessWidget {
  final List<File> uploadedFiles;
  final Function(File) onFileDeleted;

  const CartPage({
    Key? key,
    required this.uploadedFiles,
    required this.onFileDeleted,
  }) : super(key: key);

  double calculateTotalSizeMB() {
    return uploadedFiles.fold(0.0, (prev, file) {
      final size = file.lengthSync() / (1024 * 1024);
      return prev + size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Cart"),
        backgroundColor: Colors.indigo[900],
      ),
      body: Column(
        children: [
          Expanded(
            child: uploadedFiles.isEmpty
                ? Center(child: Text("No uploaded files"))
                : ListView.builder(
                    itemCount: uploadedFiles.length,
                    itemBuilder: (context, index) {
                      final file = uploadedFiles[index];
                      final fileSize = file.lengthSync() / (1024 * 1024);

                      return ListTile(
                        title: Text(file.path.split('/').last),
                        subtitle: Text("${fileSize.toStringAsFixed(2)} MB"),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            onFileDeleted(file);
                            Navigator.pop(context); // return to refresh
                          },
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Total Size: ${calculateTotalSizeMB().toStringAsFixed(2)} MB",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: uploadedFiles.isNotEmpty
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Proceeding to Checkout")),
                          );
                        }
                      : null,
                  child: Text("Checkout"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Back to Home"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
