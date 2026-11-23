import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/gear_item.dart';
import '../models/booking_order.dart';
import 'login_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  List<GearItem> _gears = [];
  List<BookingOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final gears = await DatabaseHelper.instance.getAllGears();
    final orders = await DatabaseHelper.instance.getAllOrders();
    setState(() {
      _gears = gears;
      _orders = orders;
    });
  }

  void _showAddGearDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    String category = 'Tenda';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Peralatan Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Alat'),
              ),
              DropdownButtonFormField<String>(
                value: category,
                items:
                    [
                          'Tenda',
                          'Carrier',
                          'Sleeping Bag',
                          'Sepatu Gunung',
                          'Alat Masak',
                        ]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                onChanged: (val) => category = val!,
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Sewa / Hari (Rp)',
                ),
              ),
              TextField(
                controller: weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Berat (kg)'),
              ),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah Stok'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4332),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                final newGear = GearItem(
                  name: nameCtrl.text.trim(),
                  category: category,
                  pricePerDay: double.tryParse(priceCtrl.text) ?? 30000,
                  weightKg: double.tryParse(weightCtrl.text) ?? 1.0,
                  stock: int.tryParse(stockCtrl.text) ?? 1,
                  description: 'Ditambahkan oleh Pemilik Toko',
                );
                await DatabaseHelper.instance.insertGear(newGear);
                if (!mounted) return;
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Pemilik Toko'),
          backgroundColor: const Color(0xFF1B4332),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Keluar Akun',
              onPressed: () {
                DatabaseHelper.currentUser = null;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Color(0xFFF37021),
            tabs: [
              Tab(icon: Icon(Icons.inventory), text: 'Inventaris Alat'),
              Tab(icon: Icon(Icons.receipt), text: 'Pesanan Masuk'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFF37021),
          foregroundColor: Colors.white,
          onPressed: _showAddGearDialog,
          icon: const Icon(Icons.add),
          label: const Text('Tambah Alat'),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Daftar Inventaris Alat (CRUD)
            ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _gears.length,
              itemBuilder: (context, index) {
                final gear = _gears[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      gear.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${gear.category} • Rp ${gear.pricePerDay.toStringAsFixed(0)}/hari • Stok: ${gear.stock}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.green,
                          ),
                          tooltip: 'Tambah Stok (+1)',
                          onPressed: () async {
                            await DatabaseHelper.instance.updateGearStock(
                              gear.id!,
                              gear.stock + 1,
                            );
                            _loadData();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Hapus Alat',
                          onPressed: () async {
                            await DatabaseHelper.instance.deleteGear(gear.id!);
                            _loadData();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Tab 2: Daftar Pesanan dari Customer
            _orders.isEmpty
                ? const Center(child: Text('Belum ada pesanan dari customer.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.shopping_bag,
                            color: Color(0xFF1B4332),
                          ),
                          title: Text('${order.gearName} (${order.quantity}x)'),
                          subtitle: Text(
                            'Penyewa: ${order.renterName} (${order.phoneNumber})\n'
                            'Durasi: ${order.durationDays} Hari • Total: Rp ${order.totalPrice.toStringAsFixed(0)}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
