import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/booking_order.dart';
import 'login_screen.dart';

class PassportScreen extends StatefulWidget {
  const PassportScreen({super.key});

  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen> {
  List<BookingOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final orders = await DatabaseHelper.instance.getAllOrders();
    setState(() => _orders = orders);
  }

  @override
  Widget build(BuildContext context) {
    final userName = DatabaseHelper.currentUser?.fullName ?? 'Petualang GearGo';
    final bool hasRentals = _orders.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gear Passport & Riwayat'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar / Ganti Akun',
            onPressed: () {
              DatabaseHelper.currentUser = null;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 36,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Status: Terverifikasi • Skor Reputasi: 98/100',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lencana Reputasi (Gear Passport)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildBadge('Damage-Free Rental', true),
                const SizedBox(width: 8),
                _buildBadge('Trusted Adventurer', true),
                const SizedBox(width: 8),
                _buildBadge('5-Star Renter', hasRentals),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Riwayat Penyewaan (Database SQLite)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _orders.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Belum ada transaksi penyewaan.'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.receipt_long,
                            color: Color(0xFF1B4332),
                          ),
                          title: Text(
                            '${order.gearName} (${order.quantity}x)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Penyewa: ${order.renterName} • ${order.durationDays} Hari\n'
                            'Total: Rp ${order.totalPrice.toStringAsFixed(0)} | Catatan: ${order.notes ?? "-"}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              await DatabaseHelper.instance.deleteOrder(order);
                              _loadOrders();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String title, bool unlocked) {
    return Expanded(
      child: Container(
        height: 95,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: unlocked ? Colors.amber[50] : Colors.grey[200],
          border: Border.all(
            color: unlocked ? const Color(0xFFF37021) : Colors.grey,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              unlocked ? Icons.verified : Icons.lock_outline,
              color: unlocked ? const Color(0xFFF37021) : Colors.grey,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
