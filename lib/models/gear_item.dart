class GearItem {
  final int? id;
  final String name;
  final String category;
  final double pricePerDay;
  final double weightKg;
  int stock;
  final String? description;

  GearItem({
    this.id,
    required this.name,
    required this.category,
    required this.pricePerDay,
    required this.weightKg,
    required this.stock,
    this.description,
  });

  bool isAvailable() => stock > 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'pricePerDay': pricePerDay,
      'weightKg': weightKg,
      'stock': stock,
      'description': description,
    };
  }

  factory GearItem.fromMap(Map<String, dynamic> map) {
    return GearItem(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      pricePerDay: (map['pricePerDay'] as num).toDouble(),
      weightKg: (map['weightKg'] as num).toDouble(),
      stock: map['stock'],
      description: map['description'],
    );
  }
}
