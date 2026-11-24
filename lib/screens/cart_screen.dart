import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/cart_manager.dart';
import '../database/database_helper.dart';
import '../models/booking_order.dart';
import '../widgets/gear_image_widget.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _guaranteeNumController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  String _guaranteeType = 'KTP';
  String _paymentMethod = 'QRIS';
  String _deliveryMethod = 'Ambil Mandiri ke Toko';
  String? _kycLivePhotoPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: DatabaseHelper.currentUser?.fullName ?? '',
    );
    _phoneController = TextEditingController(
      text: DatabaseHelper.currentUser?.phone ?? '',
    );
  }

  int get _durationDays {
    final diff = _endDate.difference(_startDate).inDays;
    return diff < 1 ? 1 : diff;
  }

  double get _selectedTotalPrice {
    return CartManager.selectedItems.fold(
      0.0,
      (sum, item) =>
          sum + (item.gear.pricePerDay * item.quantity * _durationDays),
    );
  }

  bool get _isAllSelected =>
      CartManager.items.isNotEmpty &&
      CartManager.items.every((item) => item.isSelected);

  Future<void> _captureKycPhoto() async {
    // Hanya membuka kamera secara real-time (tanpa galeri)
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo != null) {
      final savedPath = await GearImageHelper.saveImagePermanently(photo.path);
      setState(() {
        _kycLivePhotoPath = savedPath;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _checkoutSelected() async {
    final selected = CartManager.selectedItems;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 peralatan untuk disewa!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Validasi wajib foto kamera langsung KYC
    if (_kycLivePhotoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Wajib memotret kartu identitas (KTP/KTM/SIM) secara langsung dengan kamera!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final batchCode =
        'GG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final isDigitalPaid = _paymentMethod != 'Bayar Tunai di Tempat (COD)';

    for (int i = 0; i < selected.length; i++) {
      final item = selected[i];
      final order = BookingOrder(
        orderCode: selected.length > 1 ? '$batchCode-${i + 1}' : batchCode,
        customerId: DatabaseHelper.currentUser?.id ?? 1,
        renterName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        gearId: item.gear.id!,
        gearName: item.gear.name,
        quantity: item.quantity,
        startDate: _startDate.toString().substring(0, 10),
        endDate: _endDate.toString().substring(0, 10),
        durationDays: _durationDays,
        totalPrice: item.gear.pricePerDay * item.quantity * _durationDays,
        guaranteeType: _guaranteeType,
        guaranteeNumber: _guaranteeNumController.text.trim(),
        kycPhotoPath: _kycLivePhotoPath,
        paymentMethod: _paymentMethod,
        paymentVerified: isDigitalPaid ? 1 : 0,
        deliveryMethod: _deliveryMethod,
        deliveryAddress: _deliveryMethod == 'Pengiriman Online'
            ? _addressController.text.trim()
            : 'Ambil di Store GearGo',
        status: 'Menunggu Verifikasi KYC',
      );

      await DatabaseHelper.instance.insertOrder(order, item.gear.stock);
    }

    CartManager.removeSelectedItems();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Berhasil menyewa ${selected.length} item! Menunggu verifikasi KYC oleh Owner.',
        ),
        backgroundColor: const Color(0xFF1B4332),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Sewa'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: CartManager.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 72,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Keranjang sewa masih kosong.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          activeColor: const Color(0xFF1B4332),
                          value: _isAllSelected,
                          onChanged: (val) {
                            setState(() {
                              for (var item in CartManager.items) {
                                item.isSelected = val ?? false;
                              }
                            });
                          },
                        ),
                        const Text(
                          'Pilih Semua Peralatan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    ...CartManager.items.map(
                      (item) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Checkbox(
                                activeColor: const Color(0xFF1B4332),
                                value: item.isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    item.isSelected = val ?? false;
                                  });
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.gear.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Rp ${item.gear.pricePerDay.toStringAsFixed(0)}/hari • Stok: ${item.gear.stock}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFF37021),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (item.quantity > 1) {
                                      item.quantity--;
                                    } else {
                                      CartManager.removeItem(item.gear.id!);
                                    }
                                  });
                                },
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 20,
                                ),
                                onPressed: item.quantity < item.gear.stock
                                    ? () => setState(() => item.quantity++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Divider(height: 28),
                    const Text(
                      'Detail Penyewaan & Verifikasi KYC Live',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    OutlinedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        'Tanggal: ${_startDate.toString().substring(0, 10)} s/d ${_endDate.toString().substring(0, 10)} ($_durationDays Hari)',
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap Penyewa *',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor WhatsApp *',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _guaranteeType,
                            decoration: const InputDecoration(
                              labelText: 'Jenis KYC',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                            items: ['KTP', 'KTM', 'SIM']
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _guaranteeType = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _guaranteeNumController,
                            decoration: const InputDecoration(
                              labelText: 'Nomor NIK / NIM / SIM *',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Nomor identitas wajib diisi'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // KOTAK FOTO LIVE CAMERA KYC (KHUSUS KAMERA LANGSUNG)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _kycLivePhotoPath == null
                              ? Colors.red.shade300
                              : const Color(0xFF1B4332),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_user,
                                color: Color(0xFF1B4332),
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Foto Asli $_guaranteeType (Live Camera Wajib) *',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_kycLivePhotoPath != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: GearImageDisplay(
                                imagePath: _kycLivePhotoPath,
                                width: double.infinity,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              height: 110,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4EFE6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 36,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Foto harus diambil langsung menggunakan kamera\nuntuk validasi keaslian identitas',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B4332),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _captureKycPhoto,
                              icon: const Icon(Icons.camera_alt),
                              label: Text(
                                _kycLivePhotoPath == null
                                    ? 'Potret $_guaranteeType Sekarang'
                                    : 'Potret Ulang $_guaranteeType',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Metode Pembayaran',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      items:
                          [
                                'QRIS',
                                'Transfer Bank',
                                'Bayar Tunai di Tempat (COD)',
                              ]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: _deliveryMethod,
                      decoration: const InputDecoration(
                        labelText: 'Opsi Pengambilan / Pengiriman',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      items: ['Ambil Mandiri ke Toko', 'Pengiriman Online']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _deliveryMethod = v!),
                    ),

                    if (_deliveryMethod == 'Pengiriman Online') ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Alamat Lengkap Pengiriman *',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            _deliveryMethod == 'Pengiriman Online' &&
                                (v == null || v.isEmpty)
                            ? 'Alamat wajib diisi'
                            : null,
                      ),
                    ],

                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4332).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total (${CartManager.selectedItems.length} Item Terpilih):',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Rp ${_selectedTotalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF37021),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF37021),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _checkoutSelected,
                        child: const Text(
                          'Sewa Barang Terpilih Sekarang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
