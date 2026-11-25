import 'package:flutter/material.dart';

import '../data/cart_manager.dart';
import '../database/database_helper.dart';
import '../models/gear_item.dart';
import '../widgets/gear_image_widget.dart';
import 'cart_screen.dart';
import 'detail_screen.dart';
import 'smart_checklist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<GearItem> _allGears = [];
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  List<String> _categories = ['Semua']; // Otomatis terisi dari database

  @override
  void initState() {
    super.initState();
    _loadGears();
  }

  Future<void> _loadGears() async {
    final gears = await DatabaseHelper.instance.getAllGears();
    final dbCategories = await DatabaseHelper.instance.getDistinctCategories();
    setState(() {
      _allGears = gears;
      _categories = ['Semua', ...dbCategories];
      // Reset ke 'Semua' jika kategori yang sedang dipilih sudah dihapus Owner
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = 'Semua';
      }
    });
  }

  List<GearItem> get _filteredGears {
    return _allGears.where((gear) {
      final matchesCategory =
          _selectedCategory == 'Semua' || gear.category == _selectedCategory;
      final matchesSearch = gear.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GearGo', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Your Gear, Your Adventure',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        actions: [
          // Tombol Keranjang dengan Badge Jumlah Item
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                  _loadGears();
                },
              ),
              if (CartManager.totalBadgeCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF37021),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${CartManager.totalBadgeCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Smart Gear Checklist
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.checklist_rtl,
                  color: Color(0xFFF37021),
                  size: 34,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bingung Bawa Alat Apa?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Gunakan Smart Gear Checklist sesuai gunung & durasi!',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF37021),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SmartChecklistScreen(),
                      ),
                    );
                    _loadGears();
                  },
                  child: const Text(
                    'Cek',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Kolom Pencarian
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari tenda, carrier, sepatu gunung...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filter Kategori
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1B4332),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedCategory = category),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Daftar Katalog Peralatan
          Expanded(
            child: _filteredGears.isEmpty
                ? const Center(child: Text('Peralatan tidak ditemukan.'))
                : ListView.builder(
                    itemCount: _filteredGears.length,
                    itemBuilder: (context, index) {
                      final gear = _filteredGears[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailScreen(gear: gear),
                              ),
                            );
                            _loadGears();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Menampilkan Gambar Barang (Asset Bawaan / Galeri / Kamera Owner)
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4EFE6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: GearImageDisplay(
                                      imagePath: gear.imageAsset,
                                      width: 68,
                                      height: 68,
                                      fit: gear.imageAsset.startsWith('assets/')
                                          ? BoxFit.contain
                                          : BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1B4332)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              gear.unitCode,
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1B4332),
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Icon(
                                            Icons.star,
                                            color: gear.rating > 0
                                                ? Colors.amber
                                                : Colors.grey[400],
                                            size: 15,
                                          ),
                                          Text(
                                            gear.rating > 0
                                                ? ' ${gear.rating.toStringAsFixed(1)}'
                                                : ' Baru',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: gear.rating > 0
                                                  ? Colors.black87
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        gear.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Rp ${gear.pricePerDay.toStringAsFixed(0)} / hari • Stok: ${gear.stock}',
                                        style: const TextStyle(
                                          color: Color(0xFFF37021),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Tombol Quick Add ke Keranjang
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_shopping_cart,
                                    color: Color(0xFF1B4332),
                                  ),
                                  tooltip: 'Tambah ke Keranjang',
                                  onPressed: gear.isAvailable()
                                      ? () {
                                          setState(() {
                                            CartManager.addToCart(gear);
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              duration: const Duration(
                                                seconds: 1,
                                              ),
                                              content: Text(
                                                '${gear.name} masuk keranjang!',
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
