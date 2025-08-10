class Payment {
  final int? id;
  final String status;
  final String paymentId;
  final String orderId;
  final String signature;
  final String timestamp;
  final String customProcessId;

  Payment({
    this.id,
    required this.status,
    required this.paymentId,
    required this.orderId,
    required this.customProcessId,
    required this.signature,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status,
      'paymentId': paymentId,
      'orderId': orderId,
      'customProcessId': customProcessId,
      'signature': signature,
      'timestamp': timestamp,
    };
  }

  static Payment fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      status: map['status'],
      paymentId: map['paymentId'],
      orderId: map['orderId'],
      customProcessId: map['customProcessId'],
      signature: map['signature'],
      timestamp: map['timestamp'],
    );
  }
}
