import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/gear_item.dart';
import '../models/booking_order.dart';

class DetailScreen extends StatefulWidget {
  final GearItem gear;

  const DetailScreen({super.key, required this.gear});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _notesController = TextEditingController();

  int _quantity = 1;
  int _durationDays = 1;

  @override
  void initState() {
    super.initState();
    // Otomatis mengisi data dari user yang login (jika ada)
    _nameController = TextEditingController(
      text: DatabaseHelper.currentUser?.fullName ?? '',
    );
    _phoneController = TextEditingController(
      text: DatabaseHelper.currentUser?.phone ?? '',
    );
  }

  double get _totalPrice => widget.gear.pricePerDay * _quantity * _durationDays;

  Future<void> _submitBooking() async {
    if (_formKey.currentState!.validate()) {
      if (!widget.gear.isAvailable() || widget.gear.stock < _quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stok tidak mencukupi!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final newOrder = BookingOrder(
        renterName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        gearId: widget.gear.id!,
        gearName: widget.gear.name,
        quantity: _quantity,
        durationDays: _durationDays,
        totalPrice: _totalPrice,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        bookingDate: DateTime.now().toString().substring(0, 16),
      );

      await DatabaseHelper.instance.insertOrder(newOrder, widget.gear.stock);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking berhasil disimpan ke database!'),
          backgroundColor: Color(0xFF1B4332),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail & Form Penyewaan'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.gear.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Kategori: ${widget.gear.category} | Berat: ${widget.gear.weightKg} kg | Stok: ${widget.gear.stock}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(widget.gear.description ?? 'Tidak ada deskripsi tambahan.'),
              const Divider(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jumlah Unit:'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: _quantity < widget.gear.stock
                            ? () => setState(() => _quantity++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Durasi Sewa (Hari):'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _durationDays > 1
                            ? () => setState(() => _durationDays--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_durationDays Hari',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _durationDays++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 28),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap Penyewa *',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor WhatsApp *',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? 'Nomor WhatsApp wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan Pengambilan (Opsional)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4332).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Biaya Sewa:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rp ${_totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF37021),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: widget.gear.isAvailable() ? _submitBooking : null,
                  child: const Text(
                    'Konfirmasi Sewa Sekarang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
