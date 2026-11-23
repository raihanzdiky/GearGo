import 'package:flutter/material.dart';

import '../models/gear_item.dart';

class GearCard extends StatelessWidget {
  final GearItem gear;
  final VoidCallback onTap;

  const GearCard({super.key, required this.gear, required this.onTap});

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tenda':
        return Icons.holiday_village;
      case 'Carrier':
        return Icons.backpack;
      case 'Sleeping Bag':
        return Icons.bed;
      case 'Sepatu Gunung':
        return Icons.hiking;
      default:
        return Icons.outdoor_grill;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Kotak Ikon Kategori
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4332).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(gear.category),
                  size: 32,
                  color: const Color(0xFF1B4332),
                ),
              ),
              const SizedBox(width: 14),
              // Informasi Produk
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gear.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${gear.category} • Berat: ${gear.weightKg} kg',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rp ${gear.pricePerDay.toStringAsFixed(0)} / hari',
                          style: const TextStyle(
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: gear.isAvailable()
                                ? Colors.green[100]
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            gear.isAvailable()
                                ? 'Stok: ${gear.stock}'
                                : 'Habis',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: gear.isAvailable()
                                  ? Colors.green[800]
                                  : Colors.red[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
