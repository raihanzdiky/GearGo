class BookingOrder {
  final int? id;
  final String orderCode;
  final int customerId;
  final String renterName;
  final String phoneNumber;
  final int gearId;
  final String gearName;
  final int quantity;
  final String startDate;
  final String endDate;
  final int durationDays;
  final double totalPrice;
  final String guaranteeType; // KTP, KTM, SIM
  final String guaranteeNumber;
  final String? kycPhotoPath; // [BARU] Path foto live camera KTP/KTM/SIM
  int kycVerified; // 0 = Pending, 1 = Approved, 2 = Rejected
  final String paymentMethod;
  int paymentVerified;
  final String deliveryMethod;
  final String? deliveryAddress;
  String? trackingNumber;
  String status;
  double fineAmount;
  String? inspectionNotes;
  int isReviewed;

  BookingOrder({
    this.id,
    required this.orderCode,
    required this.customerId,
    required this.renterName,
    required this.phoneNumber,
    required this.gearId,
    required this.gearName,
    required this.quantity,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.totalPrice,
    required this.guaranteeType,
    required this.guaranteeNumber,
    this.kycPhotoPath,
    this.kycVerified = 0,
    required this.paymentMethod,
    this.paymentVerified = 0,
    required this.deliveryMethod,
    this.deliveryAddress,
    this.trackingNumber,
    this.status = 'Menunggu Konfirmasi',
    this.fineAmount = 0,
    this.inspectionNotes,
    this.isReviewed = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderCode': orderCode,
      'customerId': customerId,
      'renterName': renterName,
      'phoneNumber': phoneNumber,
      'gearId': gearId,
      'gearName': gearName,
      'quantity': quantity,
      'startDate': startDate,
      'endDate': endDate,
      'durationDays': durationDays,
      'totalPrice': totalPrice,
      'guaranteeType': guaranteeType,
      'guaranteeNumber': guaranteeNumber,
      'kycPhotoPath': kycPhotoPath,
      'kycVerified': kycVerified,
      'paymentMethod': paymentMethod,
      'paymentVerified': paymentVerified,
      'deliveryMethod': deliveryMethod,
      'deliveryAddress': deliveryAddress,
      'trackingNumber': trackingNumber,
      'status': status,
      'fineAmount': fineAmount,
      'inspectionNotes': inspectionNotes,
      'isReviewed': isReviewed,
    };
  }

  factory BookingOrder.fromMap(Map<String, dynamic> map) {
    return BookingOrder(
      id: map['id'],
      orderCode: map['orderCode'],
      customerId: map['customerId'],
      renterName: map['renterName'],
      phoneNumber: map['phoneNumber'],
      gearId: map['gearId'],
      gearName: map['gearName'],
      quantity: map['quantity'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      durationDays: map['durationDays'],
      totalPrice: (map['totalPrice'] as num).toDouble(),
      guaranteeType: map['guaranteeType'],
      guaranteeNumber: map['guaranteeNumber'],
      kycPhotoPath: map['kycPhotoPath'],
      kycVerified: map['kycVerified'] ?? 0,
      paymentMethod: map['paymentMethod'],
      paymentVerified: map['paymentVerified'] ?? 0,
      deliveryMethod: map['deliveryMethod'],
      deliveryAddress: map['deliveryAddress'],
      trackingNumber: map['trackingNumber'],
      status: map['status'],
      fineAmount: (map['fineAmount'] as num?)?.toDouble() ?? 0.0,
      inspectionNotes: map['inspectionNotes'],
      isReviewed: map['isReviewed'] ?? 0,
    );
  }
}
