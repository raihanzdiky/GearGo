import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/gear_item.dart';
import '../models/booking_order.dart';
import '../models/review_model.dart';
import '../database/database_helper.dart';
import '../data/cart_manager.dart';
import '../widgets/gear_image_widget.dart';
import 'cart_screen.dart';

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
  final _guaranteeNumController = TextEditingController();
  final _addressController = TextEditingController();

  int _quantity = 1;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  String _guaranteeType = 'KTP';
  String _paymentMethod = 'QRIS';
  String _deliveryMethod = 'Ambil Mandiri ke Toko';
  String? _kycLivePhotoPath;
  final ImagePicker _picker = ImagePicker();
  List<ReviewModel> _reviews = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: DatabaseHelper.currentUser?.fullName ?? '',
    );
    _phoneController = TextEditingController(
      text: DatabaseHelper.currentUser?.phone ?? '',
    );
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (widget.gear.id != null) {
      final data = await DatabaseHelper.instance.getReviewsByGear(
        widget.gear.id!,
      );
      setState(() => _reviews = data);
    }
  }

  int get _durationDays {
    final diff = _endDate.difference(_startDate).inDays;
    return diff < 1 ? 1 : diff;
  }

  double get _totalPrice => widget.gear.pricePerDay * _quantity * _durationDays;

  Future<void> _captureKycPhoto() async {
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

  void _addToCartOnly() {
    CartManager.addToCart(widget.gear, quantity: _quantity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.gear.name} (${_quantity}x) ditambahkan ke Keranjang!',
        ),
        backgroundColor: const Color(0xFF1B4332),
        action: SnackBarAction(
          label: 'Buka Keranjang',
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

  Future<void> _submitDirectBooking() async {
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

    final orderCode =
        'GG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final isDigitalPaid = _paymentMethod != 'Bayar Tunai di Tempat (COD)';

    final newOrder = BookingOrder(
      orderCode: orderCode,
      customerId: DatabaseHelper.currentUser?.id ?? 1,
      renterName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      gearId: widget.gear.id!,
      gearName: widget.gear.name,
      quantity: _quantity,
      startDate: _startDate.toString().substring(0, 10),
      endDate: _endDate.toString().substring(0, 10),
      durationDays: _durationDays,
      totalPrice: _totalPrice,
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

    await DatabaseHelper.instance.insertOrder(newOrder, widget.gear.stock);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pesanan $orderCode berhasil dibuat! Menunggu verifikasi KYC Owner.',
        ),
        backgroundColor: const Color(0xFF1B4332),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = widget.gear.isAvailable();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gear.name),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Lihat Keranjang',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Produk + Gambar Utama Produk (Klik untuk Perbesar)
              Row(
                children: [
                  GestureDetector(
                    onTap: () => GearImageHelper.showZoomablePreview(
                      context,
                      imagePath: widget.gear.imageAsset,
                      title: widget.gear.name,
                    ),
                    child: Stack(
                      children: [
                        Container(
                          width: 85,
                          height: 85,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: GearImageDisplay(
                              imagePath: widget.gear.imageAsset,
                              width: 85,
                              height: 85,
                              fit: widget.gear.imageAsset.startsWith('assets/')
                                  ? BoxFit.contain
                                  : BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kode Unit: ${widget.gear.unitCode}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF37021),
                          ),
                        ),
                        Text(
                          widget.gear.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rp ${widget.gear.pricePerDay.toStringAsFixed(0)}/hari • Stok: ${widget.gear.stock}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.gear.description ?? '',
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 16),

              // FITUR UNGGULAN: GEAR PASSPORT
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4332).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF1B4332).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_user,
                          color: Color(0xFF1B4332),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'GEAR PASSPORT (Riwayat Perawatan Unit)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4332),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Text(
                      '• Terakhir Dicuci/Steril: ${widget.gear.lastCleanedDate ?? "-"}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    Text(
                      '• Uji Waterproofing: ${widget.gear.waterproofStatus ?? "-"}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    Text(
                      '• Catatan Teknisi: ${widget.gear.maintenanceNotes ?? "-"}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    if (widget.gear.passportPhotoPath != null &&
                        widget.gear.passportPhotoPath!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Color(0xFFF37021),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Foto Kondisi Fisik Terbaru (Ketuk untuk Perbesar):',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B4332),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => GearImageHelper.showZoomablePreview(
                          context,
                          imagePath: widget.gear.passportPhotoPath,
                          title: 'Gear Passport: ${widget.gear.unitCode}',
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: GearImageDisplay(
                            imagePath: widget.gear.passportPhotoPath,
                            width: double.infinity,
                            height: 170,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // FORMULIR PENYEWAAN & VALIDASI KYC LIVE CAMERA
              if (isAvailable) ...[
                const Text(
                  'Atur Jumlah & Opsi Sewa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    const Text('Jumlah Unit: '),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _quantity < widget.gear.stock
                          ? () => setState(() => _quantity++)
                          : null,
                    ),
                  ],
                ),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1B4332),
                      side: const BorderSide(
                        color: Color(0xFF1B4332),
                        width: 1.5,
                      ),
                    ),
                    onPressed: _addToCartOnly,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text(
                      'Tambah ke Keranjang (Sewa Beberapa Barang)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const Divider(height: 28),
                const Text(
                  'Atau Sewa Langsung Item Ini (Wajib KYC Live):',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                          labelText: 'Jaminan KYC',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                        items: ['KTP', 'KTM', 'SIM']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _guaranteeType = v!),
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
                        GestureDetector(
                          onTap: () => GearImageHelper.showZoomablePreview(
                            context,
                            imagePath: _kycLivePhotoPath,
                            title: 'Foto KYC ($_guaranteeType)',
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: GearImageDisplay(
                              imagePath: _kycLivePhotoPath,
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
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
                      ['QRIS', 'Transfer Bank', 'Bayar Tunai di Tempat (COD)']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
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
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4332).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Biaya Sewa:',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF37021),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _submitDirectBooking,
                    child: const Text(
                      'Sewa Langsung Item Ini',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Text(
                'Ulasan Penyewa Sebelumnya:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_reviews.isEmpty)
                const Text(
                  'Belum ada ulasan untuk unit ini.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ..._reviews.map(
                  (rev) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                rev.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '⭐ ${rev.rating}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(rev.comment),
                          if (rev.ownerReply != null &&
                              rev.ownerReply!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Balasan Toko: ${rev.ownerReply}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
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
