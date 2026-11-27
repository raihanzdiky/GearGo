import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/booking_order.dart';
import '../models/review_model.dart';
import 'login_screen.dart';
import '../data/cart_manager.dart';
import '../widgets/toast_helper.dart';

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
    final userId = DatabaseHelper.currentUser?.id;
    if (userId != null) {
      final orders = await DatabaseHelper.instance.getOrdersByCustomer(userId);
      setState(() => _orders = orders);
    } else {
      setState(() => _orders = []);
    }
  }

  void _showReviewDialog(BookingOrder order) {
    int selectedRating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Beri Ulasan: ${order.gearName}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Pilih Rating Kualitas Alat:'),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setDialogState(() {
                            selectedRating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Icon(
                            index < selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 34,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Tulis pengalaman sewa Anda',
                    border: OutlineInputBorder(),
                  ),
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
                final user = DatabaseHelper.currentUser;
                final review = ReviewModel(
                  orderId: order.id!,
                  gearId: order.gearId,
                  userName: user?.fullName ?? order.renterName,
                  rating: selectedRating.toDouble(),
                  comment: commentCtrl.text.trim().isEmpty
                      ? 'Alat sangat bersih dan berfungsi dengan baik!'
                      : commentCtrl.text.trim(),
                  createdAt: DateTime.now().toString().substring(0, 10),
                );
                await DatabaseHelper.instance.insertReview(review, order.id!);
                if (!mounted) return;
                Navigator.pop(context);
                _loadOrders();
                ToastHelper.show(context, 'Terima kasih atas ulasan Anda!');
              },
              child: const Text('Kirim Ulasan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = DatabaseHelper.currentUser?.fullName ?? 'Petualang GearGo';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya & Gear Passport'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kartu Profil & Reputasi Penyewa
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
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 32, color: Color(0xFF1B4332)),
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
                      const Text(
                        'Verified Renter • Skor Reputasi: 99/100',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Daftar Transaksi & Status Penyewaan:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (_orders.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Belum ada pesanan penyewaan.'),
              ),
            )
          else
            ..._orders.map(
              (order) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.orderCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: order.status.startsWith('Ditolak')
                                    ? Colors.red[700]
                                    : (order.status == 'Selesai'
                                          ? Colors.green[600]
                                          : const Color(0xFFF37021)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.status,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${order.gearName} (${order.quantity}x)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Jadwal: ${order.startDate} s/d ${order.endDate}'),
                      Text(
                        'Jaminan: ${order.guaranteeType} (${order.guaranteeNumber}) • ${order.kycVerified == 1 ? "KYC Terverifikasi" : "Menunggu Verifikasi"}',
                      ),
                      Text(
                        'Pembayaran: ${order.paymentMethod} (${order.paymentVerified == 1 ? "Lunas" : "Bayar di Tempat"})',
                      ),
                      Text('Opsi Serah Terima: ${order.deliveryMethod}'),
                      if (order.trackingNumber != null &&
                          order.trackingNumber!.isNotEmpty)
                        Text(
                          'No. Resi Kurir: ${order.trackingNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      if (order.fineAmount > 0)
                        Text(
                          'Denda Keterlambatan/Kerusakan: Rp ${order.fineAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Alur 5: Customer mengajukan pengembalian barang
                          if (order.status == 'Sedang Disewa')
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                order.status = 'Proses Pengembalian';
                                await DatabaseHelper.instance.updateOrder(
                                  order,
                                );
                                _loadOrders();
                              },
                              icon: const Icon(
                                Icons.assignment_return,
                                size: 18,
                              ),
                              label: const Text('Ajukan Pengembalian'),
                            ),

                          // Alur 6: Customer memberi rating & ulasan setelah Selesai
                          if (order.status == 'Selesai' &&
                              order.isReviewed == 0)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF37021),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _showReviewDialog(order),
                              icon: const Icon(Icons.star, size: 18),
                              label: const Text('Beri Rating & Ulasan'),
                            ),
                          if (order.isReviewed == 1)
                            const Text(
                              '✓ Sudah Diulas',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
