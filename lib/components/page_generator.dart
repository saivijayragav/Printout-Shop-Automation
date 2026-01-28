import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;


Future<pw.Font> loadFont() async {
  final fontData = await rootBundle.load("assets/fonts/Itim-Regular.ttf");
  return pw.Font.ttf(fontData);
}


Future<Uint8List> generatePdfWithCode(String code) async {
  final font = await loadFont();
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Text(
            code,
            style: pw.TextStyle(font: font, fontSize: 40, fontWeight: pw.FontWeight.bold),
          ),
        );
      },
    ),
  );

  return await pdf.save();
}
