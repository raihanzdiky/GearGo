import 'package:flutter/material.dart';

import '../data/cart_manager.dart';
import '../database/database_helper.dart';
import '../models/gear_item.dart';
import 'cart_screen.dart';

class WeightCalcScreen extends StatefulWidget {
  const WeightCalcScreen({super.key});

  @override
  State<WeightCalcScreen> createState() => _WeightCalcScreenState();
}

class _WeightCalcScreenState extends State<WeightCalcScreen> {
  List<GearItem> _gears = [];
  final Set<int> _selectedGearIds = {};
  double _bodyWeightKg = 60.0;

  @override
  void initState() {
    super.initState();
    _loadGears();
  }

  Future<void> _loadGears() async {
    final gears = await DatabaseHelper.instance.getAllGears();
    setState(() => _gears = gears);
  }

  double get _maxSafeWeight => _bodyWeightKg * 0.30;

  double get _totalWeight {
    return _gears
        .where((gear) => _selectedGearIds.contains(gear.id))
        .fold(0.0, (sum, item) => sum + item.weightKg);
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverweight = _totalWeight > _maxSafeWeight;
    final bool isWarning =
        _totalWeight >= (_maxSafeWeight * 0.8) && !isOverweight;

    Color statusColor = Colors.green;
    String statusMessage = 'Beban Aman & Ideal (≤ 30% Berat Badan)';

    if (isOverweight) {
      statusColor = Colors.red;
      statusMessage =
          'PERINGATAN: Beban Melebihi Batas Aman (${_maxSafeWeight.toStringAsFixed(1)} kg)!';
    } else if (isWarning) {
      statusColor = Colors.orange;
      statusMessage = 'Perhatian: Beban Mendekati Batas Maksimal Tubuh.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Weight Calculator'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        actions: [
          // Ikon Keranjang di Kanan Atas dengan Badge Total Item Aktif
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, size: 26),
                  onPressed: () async {
                    // Buka CartScreen dan perbarui state saat kembali
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                    setState(() {});
                  },
                  tooltip: 'Lihat Keranjang',
                ),
                if (CartManager.totalBadgeCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF37021),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '${CartManager.totalBadgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Slider Berat Badan
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Berat Badan Penyewa:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_bodyWeightKg.toStringAsFixed(0)} kg (Max ${_maxSafeWeight.toStringAsFixed(1)} kg)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _bodyWeightKg,
                  min: 40,
                  max: 110,
                  divisions: 70,
                  activeColor: const Color(0xFFF37021),
                  onChanged: (val) => setState(() => _bodyWeightKg = val),
                ),
              ],
            ),
          ),

          // Indikator Status Beban
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              border: Border.all(color: statusColor, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${_totalWeight.toStringAsFixed(1)} kg / ${_maxSafeWeight.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (_totalWeight / _maxSafeWeight).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[300],
                  color: statusColor,
                  minHeight: 8,
                ),
                const SizedBox(height: 6),
                Text(
                  statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Tombol "Pilih Semua / Reset" ditaruh di atas daftar item
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Perlengkapan:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4332),
                    fontSize: 14,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_selectedGearIds.length == _gears.length) {
                        _selectedGearIds.clear();
                      } else {
                        _selectedGearIds.addAll(_gears.map((e) => e.id!));
                      }
                    });
                  },
                  icon: Icon(
                    _selectedGearIds.length == _gears.length
                        ? Icons.deselect
                        : Icons.select_all,
                    size: 18,
                    color: const Color(0xFF1B4332),
                  ),
                  label: Text(
                    _selectedGearIds.length == _gears.length
                        ? 'Batalkan Pilihan'
                        : 'Pilih Semua',
                    style: const TextStyle(
                      color: Color(0xFF1B4332),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ListView Daftar Gear
          Expanded(
            child: ListView.builder(
              itemCount: _gears.length,
              itemBuilder: (context, index) {
                final gear = _gears[index];
                final isChecked = _selectedGearIds.contains(gear.id);
                return CheckboxListTile(
                  activeColor: const Color(0xFF1B4332),
                  title: Text(
                    gear.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${gear.category} • Rp ${gear.pricePerDay.toStringAsFixed(0)}/hari',
                  ),
                  secondary: Chip(label: Text('${gear.weightKg} kg')),
                  value: isChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true && gear.id != null) {
                        _selectedGearIds.add(gear.id!);
                      } else {
                        _selectedGearIds.remove(gear.id);
                      }
                    });
                  },
                );
              },
            ),
          ),

          // Tombol Tambah ke Keranjang di Bawah
          if (_selectedGearIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final selectedList = _gears
                        .where((g) => _selectedGearIds.contains(g.id))
                        .toList();

                    // Memasukkan ke CartManager & SQLite secara persisten
                    CartManager.addMultipleToCart(selectedList);

                    setState(() {
                      _selectedGearIds
                          .clear(); // Reset pilihan setelah masuk keranjang
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Berhasil menambahkan ${selectedList.length} item ke keranjang!',
                        ),
                        backgroundColor: const Color(0xFF1B4332),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text(
                    'Masukkan ${_selectedGearIds.length} Item ke Keranjang (${_totalWeight.toStringAsFixed(1)} kg)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
