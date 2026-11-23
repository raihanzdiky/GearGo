import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/gear_item.dart';
import '../widgets/gear_card.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<GearItem> _allGears = [];
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  final List<String> _categories = [
    'Semua',
    'Tenda',
    'Carrier',
    'Sleeping Bag',
    'Sepatu Gunung',
    'Alat Masak',
  ];

  @override
  void initState() {
    super.initState();
    _loadGears();
  }

  Future<void> _loadGears() async {
    final gears = await DatabaseHelper.instance.getAllGears();
    setState(() {
      _allGears = gears;
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari tenda, carrier, sepatu gunung...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          SizedBox(
            height: 45,
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
          const SizedBox(height: 8),
          Expanded(
            child: _filteredGears.isEmpty
                ? const Center(child: Text('Peralatan tidak ditemukan.'))
                : ListView.builder(
                    itemCount: _filteredGears.length,
                    itemBuilder: (context, index) {
                      final gear = _filteredGears[index];
                      return GearCard(
                        gear: gear,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(gear: gear),
                            ),
                          );
                          _loadGears(); // Refresh stok dari SQLite
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
