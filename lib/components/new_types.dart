import 'dart:typed_data';

enum PrintColor { bw, color }

enum Sides { both, single, four }

enum BindingType { spiral, soft, nobinding }

class FileData {
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
  FileData(
      {required this.name,
      required this.size,
      required this.pages,
      required this.bytes,
      required this.copies,
      required this.type,
      required this.path,
      required this.binding,
      required this.color,
      required this.sides});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
      'pages': pages,
      'copies': copies,
      'type': type,
      'path': path,
      'binding': binding,
      'color': color,
      'sides': sides,
    };
  }
}

class OrderData {
  String orderId;
  List<FileData> files;
  int pages;
  double price;
  Receipt? receipt;
  String? userName;
  String? phoneNumber;
  String? transactionId;
  String? timestamp;

  OrderData({
    required this.orderId,
    required this.files,
    required this.pages,
    required this.price,
    this.receipt,
    this.userName,
    this.phoneNumber,
    this.transactionId,
    this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'files': files.map((f) => f.toJson()).toList(),
      'pages': pages,
      'price': price,
      'receipt': receipt?.toJson(),
      'userName': userName,
      'phoneNumber': phoneNumber,
      'transactionId': transactionId,
      'timestamp': timestamp,
    };
  }
}

class ItemPrice {
  final String description;
  final int pages;
  final double bwRate;
  final double colorRate;
  final double cost;
  final int sides;
  final String bindingNote;

  ItemPrice(
      {required this.description,
      required this.pages,
      required this.bwRate,
      required this.colorRate,
      required this.cost,
      required this.bindingNote,
      required this.sides});

  factory ItemPrice.fromJson(Map<String, dynamic> json) {
    return ItemPrice(
      description: json['description'] as String,
      sides: json['sides'] as int,
      pages: json['pages'] as int,
      bwRate: (json['bwRate'] as num).toDouble(),
      colorRate: (json['colorRate'] as num).toDouble(),
      cost: (json['cost'] as num).toDouble(),
      bindingNote: json['bindingNote'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'pages': pages,
      'bwRate': bwRate,
      'colorRate': colorRate,
      'cost': cost,
      'sides': sides,
      'bindingNote': bindingNote,
    };
  }
}

class Receipt {
  final String totalPrice;
  final String currency;
  final List<ItemPrice> items;

  Receipt({
    required this.totalPrice,
    required this.currency,
    required this.items,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      totalPrice: json['totalPrice'].toString(),
      currency: json['currency'] as String,
      items: (json['items'] as List)
          .map((item) => ItemPrice.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPrice': totalPrice,
      'currency': currency,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}
