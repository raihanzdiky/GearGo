import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/gear_item.dart';
import '../data/cart_manager.dart';
import 'cart_screen.dart';

class SmartChecklistScreen extends StatefulWidget {
  const SmartChecklistScreen({super.key});

  @override
  State<SmartChecklistScreen> createState() => _SmartChecklistScreenState();
}

class _SmartChecklistScreenState extends State<SmartChecklistScreen> {
  String _selectedTrip = 'Pendakian 2 Hari 1 Malam (2H1M)';
  List<GearItem> _allGears = [];
  final Set<int> _checkedIds = {};

  final List<String> _standardCategories = [
    'Tenda',
    'Carrier',
    'Sleeping Bag',
    'Sepatu Gunung',
    'Alat Masak',
  ];

  final Map<String, List<String>> _recommendations = {
    'Camping Ceria (1 Hari / Santai)': ['Tenda', 'Alat Masak'],
    'Pendakian 2 Hari 1 Malam (2H1M)': [
      'Tenda',
      'Carrier',
      'Sleeping Bag',
      'Alat Masak',
    ],
    'Ekspedisi Gunung Tinggi (3H2M+)': [
      'Tenda',
      'Carrier',
      'Sleeping Bag',
      'Sepatu Gunung',
      'Alat Masak',
    ],
    'Semua Katalog & Kategori Baru (Lengkap)': [],
  };

  @override
  void initState() {
    super.initState();
    _loadGears();
  }

  Future<void> _loadGears() async {
    final gears = await DatabaseHelper.instance.getAllGears();
    setState(() {
      _allGears = gears;
      _autoSelectRecommended();
    });
  }

  List<GearItem> get _recommendedGears {
    if (_selectedTrip == 'Semua Katalog & Kategori Baru (Lengkap)') {
      return _allGears;
    }

    final baseCats = _recommendations[_selectedTrip] ?? [];
    return _allGears.where((g) {
      // Cocok dengan kategori standar perjalanan ATAU merupakan kategori baru buatan Owner
      final isBaseMatch = baseCats.contains(g.category);
      final isCustomOwnerCategory = !_standardCategories.contains(g.category);
      return isBaseMatch || isCustomOwnerCategory;
    }).toList();
  }

  void _autoSelectRecommended() {
    _checkedIds.clear();
    for (var gear in _recommendedGears) {
      if (gear.id != null && gear.isAvailable()) {
        _checkedIds.add(gear.id!);
      }
    }
  }

  bool get _isAllChecked {
    final availableIds = _recommendedGears
        .where((g) => g.id != null && g.isAvailable())
        .map((g) => g.id!)
        .toList();
    if (availableIds.isEmpty) return false;
    return availableIds.every((id) => _checkedIds.contains(id));
  }

  void _toggleSelectAll() {
    setState(() {
      if (_isAllChecked) {
        _checkedIds.clear();
      } else {
        for (var gear in _recommendedGears) {
          if (gear.id != null && gear.isAvailable()) {
            _checkedIds.add(gear.id!);
          }
        }
      }
    });
  }

  void _addCheckedToCart() {
    final selectedGears = _recommendedGears
        .where(
          (g) => g.id != null && _checkedIds.contains(g.id) && g.isAvailable(),
        )
        .toList();

    if (selectedGears.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Centang minimal 1 peralatan yang tersedia terlebih dahulu!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    CartManager.addMultipleToCart(selectedGears);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${selectedGears.length} item berhasil masuk ke Keranjang Sewa!',
        ),
        backgroundColor: const Color(0xFF1B4332),
        action: SnackBarAction(
          label: 'Lihat Keranjang',
          textColor: Colors.amber,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recommended = _recommendedGears;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Gear Checklist'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang Data Katalog',
            onPressed: _loadGears,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Jenis & Durasi Perjalanan:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedTrip,
              isExpanded: true,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              items: _recommendations.keys
                  .map(
                    (trip) => DropdownMenuItem(value: trip, child: Text(trip)),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedTrip = val!;
                  _autoSelectRecommended();
                });
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Peralatan Direkomendasikan (${_checkedIds.length} dipilih):',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _toggleSelectAll,
                  icon: Icon(
                    _isAllChecked ? Icons.deselect : Icons.select_all,
                    size: 18,
                    color: const Color(0xFF1B4332),
                  ),
                  label: Text(
                    _isAllChecked ? 'Batal Semua' : 'Pilih Semua',
                    style: const TextStyle(
                      color: Color(0xFF1B4332),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            Expanded(
              child: recommended.isEmpty
                  ? const Center(child: Text('Belum ada peralatan di katalog.'))
                  : ListView.builder(
                      itemCount: recommended.length,
                      itemBuilder: (context, index) {
                        final gear = recommended[index];
                        final isAvailable = gear.isAvailable();
                        final isChecked =
                            gear.id != null && _checkedIds.contains(gear.id);
                        final isNewCategory = !_standardCategories.contains(
                          gear.category,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: CheckboxListTile(
                            activeColor: const Color(0xFF1B4332),
                            value: isChecked,
                            onChanged: isAvailable && gear.id != null
                                ? (val) {
                                    setState(() {
                                      if (val == true) {
                                        _checkedIds.add(gear.id!);
                                      } else {
                                        _checkedIds.remove(gear.id!);
                                      }
                                    });
                                  }
                                : null,
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    gear.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isNewCategory)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF37021)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      gear.category,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFF37021),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              '${gear.category} • ${gear.weightKg} kg • Rp ${gear.pricePerDay.toStringAsFixed(0)}/hari\n'
                              '${isAvailable ? "Stok Tersedia: ${gear.stock} unit" : "Stok Habis"}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isAvailable
                                    ? Colors.black87
                                    : Colors.red,
                              ),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),

            SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF37021),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _addCheckedToCart,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text(
                    'Masukkan ${_checkedIds.length} Item ke Keranjang',
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
      ),
    );
  }
}
