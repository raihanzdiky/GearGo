class BookingOrder {
  final int? id;
  final String renterName;
  final String phoneNumber;
  final int gearId;
  final String gearName;
  final int quantity;
  final int durationDays;
  final double totalPrice;
  final String? notes;
  final String bookingDate;

  BookingOrder({
    this.id,
    required this.renterName,
    required this.phoneNumber,
    required this.gearId,
    required this.gearName,
    required this.quantity,
    required this.durationDays,
    required this.totalPrice,
    this.notes,
    required this.bookingDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'renterName': renterName,
      'phoneNumber': phoneNumber,
      'gearId': gearId,
      'gearName': gearName,
      'quantity': quantity,
      'durationDays': durationDays,
      'totalPrice': totalPrice,
      'notes': notes,
      'bookingDate': bookingDate,
    };
  }

  factory BookingOrder.fromMap(Map<String, dynamic> map) {
    return BookingOrder(
      id: map['id'],
      renterName: map['renterName'],
      phoneNumber: map['phoneNumber'],
      gearId: map['gearId'],
      gearName: map['gearName'],
      quantity: map['quantity'],
      durationDays: map['durationDays'],
      totalPrice: (map['totalPrice'] as num).toDouble(),
      notes: map['notes'],
      bookingDate: map['bookingDate'],
    );
  }
}
