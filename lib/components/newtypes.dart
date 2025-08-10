import 'dart:typed_data';
enum PrintColor{
  bw,
  color
}

enum Sides{
  both,
  single,
  four
}
enum BindingType { spiral, soft, nobinding }
class FileData{
  late String name;
  final double size;
  final int pages;
  final Uint8List bytes;
  int copies;
  final String type;
  final String path;
  late String binding;
  late String color;
  late String sides;
  FileData({required this.name, required this.size, required this.pages,
    required this.bytes, required this.copies, required this.type,
    required this.path, required this.binding, required this.color, required this.sides});
}

class OrderData{
  String orderId;
  List<FileData> files;
  int pages;
  double price;
  int time;
  OrderData({required this.orderId, required this.files, required this.pages, required this.price, required this.time});
}