class GearItem {
  final int? id;
  final String unitCode;
  final String name;
  final String category;
  final double pricePerDay;
  final double weightKg;
  int stock;
  final double rating;
  final String imageAsset; // Menyimpan path asset ATAU path file foto produk
  final String? description;
  final String? lastRentedDate;
  final String? lastCleanedDate;
  final String? waterproofStatus;
  final String? maintenanceNotes;
  final String? passportPhotoPath; // [BARU] Path foto live kamera Gear Passport

  GearItem({
    this.id,
    required this.unitCode,
    required this.name,
    required this.category,
    required this.pricePerDay,
    required this.weightKg,
    required this.stock,
    this.rating = 5.0,
    this.imageAsset = 'assets/images/logo_geargo.png',
    this.description,
    this.lastRentedDate,
    this.lastCleanedDate,
    this.waterproofStatus,
    this.maintenanceNotes,
    this.passportPhotoPath,
  });

  bool isAvailable() => stock > 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unitCode': unitCode,
      'name': name,
      'category': category,
      'pricePerDay': pricePerDay,
      'weightKg': weightKg,
      'stock': stock,
      'rating': rating,
      'imageAsset': imageAsset,
      'description': description,
      'lastRentedDate': lastRentedDate ?? '-',
      'lastCleanedDate': lastCleanedDate ?? 'Baru',
      'waterproofStatus': waterproofStatus ?? 'Teruji Baik',
      'maintenanceNotes': maintenanceNotes ?? 'Siap digunakan',
      'passportPhotoPath': passportPhotoPath,
    };
  }

  factory GearItem.fromMap(Map<String, dynamic> map) {
    return GearItem(
      id: map['id'],
      unitCode: map['unitCode'] ?? 'UNIT-01',
      name: map['name'],
      category: map['category'],
      pricePerDay: (map['pricePerDay'] as num).toDouble(),
      weightKg: (map['weightKg'] as num).toDouble(),
      stock: map['stock'],
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      imageAsset: map['imageAsset'] ?? 'assets/images/logo_geargo.png',
      description: map['description'],
      lastRentedDate: map['lastRentedDate'],
      lastCleanedDate: map['lastCleanedDate'],
      waterproofStatus: map['waterproofStatus'],
      maintenanceNotes: map['maintenanceNotes'],
      passportPhotoPath: map['passportPhotoPath'],
    );
  }
}
