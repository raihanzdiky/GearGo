import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../database/database_helper.dart';
import '../models/gear_item.dart';
import '../models/booking_order.dart';
import '../models/review_model.dart';
import '../widgets/gear_image_widget.dart';
import '../widgets/toast_helper.dart';
import 'login_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  List<GearItem> _gears = [];
  List<BookingOrder> _orders = [];
  List<ReviewModel> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final gears = await DatabaseHelper.instance.getAllGears();
    final orders = await DatabaseHelper.instance.getAllOrders();
    final reviews = await DatabaseHelper.instance.getAllReviews();
    setState(() {
      _gears = gears;
      _orders = orders;
      _reviews = reviews;
    });
  }

  // Helper untuk mengambil kode induk transaksi (misal: GG-930010-1 -> GG-930010)
  String _getBatchCode(String orderCode) {
    final parts = orderCode.split('-');
    if (parts.length >= 2) {
      return '${parts[0]}-${parts[1]}';
    }
    return orderCode;
  }

  // --- DIALOG MODUL 1: TAMBAH / UBAH ALAT (KATEGORI DINAMIS + VALIDASI KODE UNIK + GALERI/KAMERA) ---
  void _showGearFormDialog({GearItem? existingGear}) {
    final isEdit = existingGear != null;
    final formKey = GlobalKey<FormState>();

    final codeCtrl = TextEditingController(
      text: isEdit ? existingGear.unitCode : 'GEAR-0${_gears.length + 1}',
    );
    final nameCtrl = TextEditingController(
      text: isEdit ? existingGear.name : '',
    );
    final categoryCtrl = TextEditingController(
      text: isEdit ? existingGear.category : '',
    );
    final priceCtrl = TextEditingController(
      text: isEdit ? existingGear.pricePerDay.toStringAsFixed(0) : '',
    );
    final weightCtrl = TextEditingController(
      text: isEdit ? existingGear.weightKg.toString() : '',
    );
    final stockCtrl = TextEditingController(
      text: isEdit ? existingGear.stock.toString() : '',
    );
    final descCtrl = TextEditingController(
      text: isEdit ? (existingGear.description ?? '') : '',
    );

    final existingCategories = _gears.map((g) => g.category).toSet().toList();
    if (existingCategories.isEmpty) {
      existingCategories.addAll([
        'Tenda',
        'Carrier',
        'Sleeping Bag',
        'Sepatu Gunung',
        'Alat Masak',
      ]);
    }

    String? pickedImagePath = isEdit ? existingGear.imageAsset : null;
    String? duplicateCodeError;
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickProductImage(ImageSource source) async {
            final XFile? image = await picker.pickImage(
              source: source,
              imageQuality: 80,
            );
            if (image != null) {
              final permanentPath = await GearImageHelper.saveImagePermanently(
                image.path,
              );
              setDialogState(() {
                pickedImagePath = permanentPath;
              });
            }
          }

          return AlertDialog(
            title: Text(
              isEdit ? 'Ubah Katalog Alat' : 'Tambah Inventaris Alat',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Preview Gambar Produk (Bisa diklik untuk diperbesar)
                    GestureDetector(
                      onTap: pickedImagePath != null
                          ? () => GearImageHelper.showZoomablePreview(
                              context,
                              imagePath: pickedImagePath,
                              title: nameCtrl.text.isEmpty
                                  ? 'Preview Foto Produk'
                                  : nameCtrl.text,
                            )
                          : null,
                      child: Container(
                        height: 130,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4EFE6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: pickedImagePath != null
                              ? GearImageDisplay(
                                  imagePath: pickedImagePath,
                                  fit: pickedImagePath!.startsWith('assets/')
                                      ? BoxFit.contain
                                      : BoxFit.cover,
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    Text(
                                      'Belum ada foto produk',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tombol Pilih Galeri atau Kamera
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                pickProductImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: const Text(
                              'Galeri',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B4332),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                pickProductImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text(
                              'Kamera',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Kode Unit Fisik (Dengan Validasi Unik)
                    TextFormField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Kode Unit Unik (misal: PKY-A01) *',
                        errorText: duplicateCodeError,
                      ),
                      onChanged: (_) {
                        if (duplicateCodeError != null) {
                          setDialogState(() => duplicateCodeError = null);
                        }
                      },
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Kode unit wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 8),

                    // Nama Alat
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Alat *',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nama alat wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 8),

                    // Kategori Dinamis
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: categoryCtrl.text),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return existingCategories;
                        }
                        return existingCategories.where(
                          (option) => option.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                        );
                      },
                      onSelected: (String selection) {
                        categoryCtrl.text = selection;
                      },
                      fieldViewBuilder:
                          (
                            context,
                            textEditingController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            textEditingController.addListener(() {
                              categoryCtrl.text = textEditingController.text;
                            });
                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Kategori (Pilih / Ketik Baru) *',
                                hintText: 'Contoh: Penerangan, Pakaian Outdoor',
                                suffixIcon: Icon(Icons.arrow_drop_down),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Kategori wajib diisi'
                                  : null,
                            );
                          },
                    ),
                    const SizedBox(height: 8),

                    // Harga Sewa / Hari
                    TextFormField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga Sewa / Hari (Rp) *',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Harga wajib diisi';
                        }
                        if (double.tryParse(v.trim()) == null ||
                            double.parse(v.trim()) <= 0) {
                          return 'Masukkan harga valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Berat (kg)
                    TextFormField(
                      controller: weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Berat (kg) *',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Berat wajib diisi';
                        }
                        if (double.tryParse(v.trim()) == null ||
                            double.parse(v.trim()) <= 0) {
                          return 'Masukkan berat valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Jumlah Stok
                    TextFormField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Stok *',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Stok wajib diisi';
                        }
                        if (int.tryParse(v.trim()) == null ||
                            int.parse(v.trim()) < 0) {
                          return 'Masukkan jumlah stok valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Deskripsi
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Spesifikasi',
                      ),
                    ),
                  ],
                ),
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
                  if (!formKey.currentState!.validate()) return;

                  final formattedCode = codeCtrl.text.trim().toUpperCase();

                  final exists = await DatabaseHelper.instance.isUnitCodeExists(
                    formattedCode,
                    excludeGearId: isEdit ? existingGear.id : null,
                  );

                  if (exists) {
                    setDialogState(() {
                      duplicateCodeError =
                          'Kode "$formattedCode" sudah digunakan barang lain!';
                    });
                    return;
                  }

                  final rawCat = categoryCtrl.text.trim();
                  final formattedCategory = rawCat
                      .split(' ')
                      .where((word) => word.isNotEmpty)
                      .map(
                        (word) =>
                            word[0].toUpperCase() +
                            word.substring(1).toLowerCase(),
                      )
                      .join(' ');

                  final gearData = GearItem(
                    id: isEdit ? existingGear.id : null,
                    unitCode: formattedCode,
                    name: nameCtrl.text.trim(),
                    category: formattedCategory,
                    pricePerDay: double.parse(priceCtrl.text.trim()),
                    weightKg: double.parse(weightCtrl.text.trim()),
                    stock: int.parse(stockCtrl.text.trim()),
                    rating: isEdit ? existingGear.rating : 5.0,
                    imageAsset:
                        pickedImagePath ?? 'assets/images/logo_geargo.png',
                    description: descCtrl.text.trim().isEmpty
                        ? 'Unit terverifikasi GearGo.'
                        : descCtrl.text.trim(),
                    lastRentedDate: isEdit ? existingGear.lastRentedDate : '-',
                    lastCleanedDate: isEdit
                        ? existingGear.lastCleanedDate
                        : DateTime.now().toString().substring(0, 10),
                    waterproofStatus: isEdit
                        ? existingGear.waterproofStatus
                        : 'Lolos QC Awal',
                    maintenanceNotes: isEdit
                        ? existingGear.maintenanceNotes
                        : 'Kondisi 100% siap sewa',
                    passportPhotoPath: isEdit
                        ? existingGear.passportPhotoPath
                        : null,
                  );

                  if (isEdit) {
                    await DatabaseHelper.instance.updateGear(gearData);
                  } else {
                    await DatabaseHelper.instance.insertGear(gearData);
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadAllData();
                  ToastHelper.show(
                    context,
                    isEdit
                        ? 'Katalog "${gearData.name}" berhasil diperbarui!'
                        : 'Alat "${gearData.name}" (Kategori: ${gearData.category}) ditambahkan!',
                  );
                },
                child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- DIALOG MODUL 1: UPDATE GEAR PASSPORT (KHUSUS KAMERA LANGSUNG) ---
  void _showMaintenanceDialog(GearItem gear) {
    final nowStr = DateTime.now().toString().substring(0, 16);
    final cleanCtrl = TextEditingController(
      text: '$nowStr (Sterilisasi & Cuci)',
    );
    final waterproofCtrl = TextEditingController(
      text: gear.waterproofStatus ?? 'Lolos Uji Air',
    );
    final noteCtrl = TextEditingController(text: gear.maintenanceNotes ?? '');
    String? liveCameraPhotoPath = gear.passportPhotoPath;
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> captureLivePhoto() async {
            final XFile? photo = await picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 80,
            );
            if (photo != null) {
              final permanentPath = await GearImageHelper.saveImagePermanently(
                photo.path,
              );
              setDialogState(() {
                liveCameraPhotoPath = permanentPath;
              });
            }
          }

          return AlertDialog(
            title: Text('Update Gear Passport (${gear.unitCode})'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: liveCameraPhotoPath != null
                        ? () => GearImageHelper.showZoomablePreview(
                            context,
                            imagePath: liveCameraPhotoPath,
                            title: 'Gear Passport: ${gear.unitCode}',
                          )
                        : null,
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4EFE6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1B4332)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: liveCameraPhotoPath != null
                            ? GearImageDisplay(
                                imagePath: liveCameraPhotoPath,
                                fit: BoxFit.cover,
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_enhance,
                                    size: 40,
                                    color: Color(0xFF1B4332),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Wajib foto kondisi fisik langsung\nmenggunakan kamera saat ini',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF37021),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: captureLivePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Potret Kondisi Fisik Sekarang'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: cleanCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Waktu Pencucian / Sterilisasi',
                    ),
                  ),
                  TextField(
                    controller: waterproofCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Hasil Tes Waterproofing',
                    ),
                  ),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Kondisi Fisik Gudang',
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
                  await DatabaseHelper.instance.updateGearPassport(
                    gearId: gear.id!,
                    lastCleanedDate: cleanCtrl.text.trim(),
                    waterproofStatus: waterproofCtrl.text.trim(),
                    maintenanceNotes: noteCtrl.text.trim(),
                    passportPhotoPath: liveCameraPhotoPath,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadAllData();
                },
                child: const Text('Simpan Log'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- DIALOG MODUL 3: FULFILLMENT & BERITA ACARA SERAH TERIMA ---
  void _showFulfillmentDialog(
    String batchCode,
    List<BookingOrder> groupOrders,
  ) {
    final primaryOrder = groupOrders.first;
    final resiCtrl = TextEditingController(
      text: primaryOrder.trackingNumber ?? '',
    );
    bool checkPart1 = true;
    bool checkPart2 = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Serah Terima ($batchCode)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metode: ${primaryOrder.deliveryMethod}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total Jenis Alat: ${groupOrders.length} item',
                  style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                ),
                if (primaryOrder.deliveryMethod == 'Pengiriman Online') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: resiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Input Nomor Resi / Kurir Instan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                const Text(
                  'Berita Acara Checklist Fisik Keluar:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Kelengkapan komponen & pasak lengkap',
                    style: TextStyle(fontSize: 12.5),
                  ),
                  value: checkPart1,
                  onChanged: (v) => setDialogState(() => checkPart1 = v!),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Kondisi bersih, kering & tidak robek',
                    style: TextStyle(fontSize: 12.5),
                  ),
                  value: checkPart2,
                  onChanged: (v) => setDialogState(() => checkPart2 = v!),
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
                for (final order in groupOrders) {
                  order.trackingNumber = resiCtrl.text.trim();
                  order.paymentVerified = 1;
                  order.status = 'Sedang Disewa';
                  await DatabaseHelper.instance.updateOrder(order);
                }
                if (!mounted) return;
                Navigator.pop(context);
                _loadAllData();
                ToastHelper.show(
                  context,
                  'Serah terima $batchCode (${groupOrders.length} item) berhasil!',
                );
              },
              child: const Text('Serahkan Barang'),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG MODUL 4: QUICK INSPECTION & LEPAS JAMINAN ---
  void _showReturnInspectionDialog(BookingOrder order) {
    final fineCtrl = TextEditingController(text: '0');
    final noteCtrl = TextEditingController(
      text: 'Alat kembali lengkap & kondisi baik.',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Inspeksi Pengembalian (${order.orderCode})'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fineCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Denda Keterlambatan / Kerusakan (Rp)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan Hasil Inspeksi Fisik',
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
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final fine = double.tryParse(fineCtrl.text) ?? 0.0;
              await DatabaseHelper.instance.completeOrderAndRestoreStock(
                order,
                fine,
                noteCtrl.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(context);
              _loadAllData();
              ToastHelper.show(
                context,
                'Pesanan Selesai! Jaminan ${order.guaranteeType} dilepas & stok dikembalikan.',
              );
            },
            child: const Text('Selesai & Lepas Jaminan'),
          ),
        ],
      ),
    );
  }

  // --- DIALOG MODUL 5: BALAS ULASAN CUSTOMER ---
  void _showReplyReviewDialog(ReviewModel review) {
    final replyCtrl = TextEditingController(text: review.ownerReply ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Balas Ulasan Pelanggan'),
        content: TextField(
          controller: replyCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Tulis balasan resmi toko...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.replyReview(
                review.id!,
                replyCtrl.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(context);
              _loadAllData();
            },
            child: const Text('Kirim Balasan'),
          ),
        ],
      ),
    );
  }

  // --- DIALOG DETAIL LENGKAP PESANAN & DATA KYC ---
  void _showOrderGroupDetailDialog(
    String batchCode,
    List<BookingOrder> groupOrders,
  ) {
    final order = groupOrders.first;
    final totalBatchPrice = groupOrders.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    Widget detailRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
            ),
            const Text(': ', style: TextStyle(fontSize: 12.5)),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Color(0xFF1B4332)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Detail Pesanan $batchCode',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Informasi Penyewa & Jaminan KYC',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4332),
                  fontSize: 13,
                ),
              ),
              const Divider(),
              detailRow('Nama Penyewa', order.renterName),
              detailRow('No. WhatsApp', order.phoneNumber),
              detailRow('Jenis KYC', order.guaranteeType),
              detailRow('Nomor Identitas', order.guaranteeNumber),
              detailRow(
                'Status KYC',
                order.kycVerified == 1
                    ? 'Terverifikasi (Diterima)'
                    : (order.kycVerified == 2
                          ? 'Ditolak'
                          : 'Menunggu Verifikasi'),
              ),
              if (order.kycPhotoPath != null &&
                  order.kycPhotoPath!.isNotEmpty) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => GearImageHelper.showZoomablePreview(
                    context,
                    imagePath: order.kycPhotoPath,
                    title: 'KYC ${order.guaranteeType}: ${order.renterName}',
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: GearImageDisplay(
                      imagePath: order.kycPhotoPath,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'Ketuk foto identitas untuk memperbesar',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Daftar Alat Disewa (${groupOrders.length} Item)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4332),
                  fontSize: 13,
                ),
              ),
              const Divider(),
              ...groupOrders.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${item.gearName} (${item.quantity}x) — Rp ${item.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              detailRow('Tanggal Mulai', order.startDate),
              detailRow('Tanggal Kembali', order.endDate),
              detailRow('Durasi Sewa', '${order.durationDays} Hari'),
              detailRow(
                'Total Biaya Sewa',
                'Rp ${totalBatchPrice.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 14),
              const Text(
                'Pembayaran & Pengiriman',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4332),
                  fontSize: 13,
                ),
              ),
              const Divider(),
              detailRow('Metode Bayar', order.paymentMethod),
              detailRow(
                'Status Bayar',
                order.paymentVerified == 1 ? 'Lunas' : 'COD (Bayar di Tempat)',
              ),
              detailRow('Opsi Pengambilan', order.deliveryMethod),
              detailRow(
                'Alamat / Lokasi',
                order.deliveryAddress ?? 'Ambil di Store',
              ),
              if (order.trackingNumber != null &&
                  order.trackingNumber!.isNotEmpty)
                detailRow('Nomor Resi', order.trackingNumber!),
              detailRow('Status Pesanan', order.status),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = _orders
        .where((o) => o.status != 'Selesai' && o.kycVerified != 2)
        .toList();
    final returnTrackerOrders = _orders
        .where(
          (o) =>
              o.status == 'Sedang Disewa' || o.status == 'Proses Pengembalian',
        )
        .toList();

    final double totalRevenue = _orders
        .where((o) => o.kycVerified != 2)
        .fold(0.0, (sum, item) => sum + item.totalPrice + item.fineAmount);
    // Kelompokkan activeOrders berdasarkan Batch Code (1x checkout = 1 kartu)
    final Map<String, List<BookingOrder>> groupedActiveOrders = {};
    for (final order in activeOrders) {
      final batchCode = _getBatchCode(order.orderCode);
      groupedActiveOrders.putIfAbsent(batchCode, () => []).add(order);
    }
    final activeOrderGroups = groupedActiveOrders.entries.toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GearGo Owner Dashboard'),
          backgroundColor: const Color(0xFF1B4332),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await DatabaseHelper.instance.clearSession();
                if (!context.mounted) return;
                DatabaseHelper.currentUser = null;
                ScaffoldMessenger.of(context).clearSnackBars();
                DatabaseHelper.currentUser = null;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Color(0xFFF37021),
            tabs: [
              Tab(icon: Icon(Icons.inventory_2), text: '1. Katalog & Passport'),
              Tab(icon: Icon(Icons.verified_user), text: '2. Pesanan & KYC'),
              Tab(
                icon: Icon(Icons.assignment_return),
                text: '3. Return & Inspeksi',
              ),
              Tab(icon: Icon(Icons.analytics), text: '4. Analitik & Ulasan'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFF37021),
          foregroundColor: Colors.white,
          onPressed: () => _showGearFormDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Alat'),
        ),
        body: TabBarView(
          children: [
            // TAB 1: MODUL 1 - KATALOG (TAMBAH/UBAH/HAPUS) & GEAR PASSPORT
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: _gears.length,
              itemBuilder: (context, index) {
                final gear = _gears[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        // Thumbnail Gambar Produk (Klik untuk Perbesar)
                        GestureDetector(
                          onTap: () => GearImageHelper.showZoomablePreview(
                            context,
                            imagePath: gear.imageAsset,
                            title: '[${gear.unitCode}] ${gear.name}',
                          ),
                          child: Stack(
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4EFE6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: GearImageDisplay(
                                    imagePath: gear.imageAsset,
                                    fit: gear.imageAsset.startsWith('assets/')
                                        ? BoxFit.contain
                                        : BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Detail Katalog
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '[${gear.unitCode}] ${gear.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${gear.category} • ${gear.weightKg} kg • Stok: ${gear.stock}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                'Rp ${gear.pricePerDay.toStringAsFixed(0)} / hari',
                                style: const TextStyle(
                                  color: Color(0xFFF37021),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tombol Aksi: Edit Katalog, Update Gear Passport, Hapus
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Ubah Katalog Alat',
                              onPressed: () =>
                                  _showGearFormDialog(existingGear: gear),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.build_circle,
                                color: Color(0xFF1B4332),
                              ),
                              tooltip: 'Update Gear Passport',
                              onPressed: () => _showMaintenanceDialog(gear),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Hapus Alat',
                              onPressed: () async {
                                await DatabaseHelper.instance.deleteGear(
                                  gear.id!,
                                );
                                _loadAllData();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // TAB 2: MODUL 2 & 3 - PESANAN, VERIFIKASI FOTO KYC & FULFILLMENT
            activeOrderGroups.isEmpty
                ? const Center(child: Text('Tidak ada pesanan aktif.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: activeOrderGroups.length,
                    itemBuilder: (context, index) {
                      final batchCode = activeOrderGroups[index].key;
                      final groupOrders = activeOrderGroups[index].value;
                      final order = groupOrders.first;
                      final isRejected = order.kycVerified == 2;
                      final totalBatchPrice = groupOrders.fold<double>(
                        0,
                        (sum, item) => sum + item.totalPrice,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _showOrderGroupDetailDialog(
                            batchCode,
                            groupOrders,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          batchCode,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (groupOrders.length > 1) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1B4332),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${groupOrders.length} Item',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Flexible(
                                      child: Chip(
                                        backgroundColor: isRejected
                                            ? Colors.red.shade100
                                            : (order.kycVerified == 1
                                                  ? Colors.green.shade100
                                                  : Colors.orange.shade100),
                                        label: Text(
                                          order.status,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isRejected
                                                ? Colors.red.shade900
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Penyewa: ${order.renterName} • Total: Rp ${totalBatchPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Daftar seluruh alat dalam 1 checkout
                                ...groupOrders.map(
                                  (item) => Text(
                                    '• ${item.gearName} (${item.quantity}x)',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'KYC: ${order.guaranteeType} - ${order.guaranteeNumber}',
                                ),
                                Text(
                                  'Bayar: ${order.paymentMethod} (${order.paymentVerified == 1 ? "Lunas" : "COD"})',
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Ketuk kartu ini untuk melihat detail lengkap pesanan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF1B4332),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Foto Live Camera KYC
                                if (order.kycPhotoPath != null &&
                                    order.kycPhotoPath!.isNotEmpty) ...[
                                  const Text(
                                    'Foto Kartu Identitas (Ketuk foto untuk perbesar):',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B4332),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () =>
                                        GearImageHelper.showZoomablePreview(
                                          context,
                                          imagePath: order.kycPhotoPath,
                                          title:
                                              'KYC ${order.guaranteeType}: ${order.renterName}',
                                        ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: GearImageDisplay(
                                        imagePath: order.kycPhotoPath,
                                        width: double.infinity,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                // Tombol Terima / Tolak KYC (1x untuk seluruh item di grup)
                                if (order.kycVerified == 0)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[700],
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () async {
                                            for (final item in groupOrders) {
                                              item.kycVerified = 1;
                                              item.status =
                                                  'Siap Diambil/Dikirim';
                                              await DatabaseHelper.instance
                                                  .updateOrder(item);
                                            }
                                            _loadAllData();
                                            if (!mounted) return;
                                            ToastHelper.show(
                                              context,
                                              'KYC $batchCode (${groupOrders.length} item) Diterima!',
                                              backgroundColor: Colors.green,
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.check_circle,
                                            size: 18,
                                          ),
                                          label: const Text('Terima KYC'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(
                                              color: Colors.red,
                                            ),
                                          ),
                                          onPressed: () {
                                            final reasonCtrl =
                                                TextEditingController(
                                                  text: 'Foto identitas buram / tidak sesuai',
                                                );
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: Text(
                                                  'Tolak KYC ($batchCode)',
                                                ),
                                                content: SingleChildScrollView(
                                                  child: TextField(
                                                    controller: reasonCtrl,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText: 'Alasan Penolakan',
                                                          border:
                                                              OutlineInputBorder(),
                                                        ),
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx),
                                                    child: const Text('Batal'),
                                                  ),
                                                  ElevatedButton(
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    onPressed: () async {
                                                      for (final item
                                                          in groupOrders) {
                                                        await DatabaseHelper
                                                            .instance
                                                            .rejectOrderAndRestoreStock(
                                                              item,
                                                              reasonCtrl.text
                                                                  .trim(),
                                                            );
                                                      }
                                                      if (!mounted) return;
                                                      Navigator.pop(ctx);
                                                      _loadAllData();
                                                      ToastHelper.show(
                                                        context,
                                                        'Pesanan $batchCode ditolak & stok dikembalikan.',
                                                        backgroundColor:
                                                            Colors.red,
                                                      );
                                                    },
                                                    child: const Text(
                                                      'Tolak Pesanan',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.cancel,
                                            size: 18,
                                          ),
                                          label: const Text('Tolak KYC'),
                                        ),
                                      ),
                                    ],
                                  ),

                                // FIX NO. 6: Tombol Serah Terima HANYA muncul saat status 'Siap Diambil/Dikirim'
                                if (order.kycVerified == 1 &&
                                    order.status == 'Siap Diambil/Dikirim')
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1B4332,
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => _showFulfillmentDialog(
                                        batchCode,
                                        groupOrders,
                                      ),
                                      icon: const Icon(Icons.local_shipping),
                                      label: const Text(
                                        'Serah Terima / Input Resi',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

            // TAB 3: MODUL 4 - RETURN TRACKER & QUICK INSPECTION
            returnTrackerOrders.isEmpty
                ? const Center(
                    child: Text('Tidak ada barang yang sedang disewa.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: returnTrackerOrders.length,
                    itemBuilder: (context, index) {
                      final order = returnTrackerOrders[index];
                      final isReturning = order.status == 'Proses Pengembalian';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${order.orderCode} - ${order.gearName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isReturning
                                          ? Colors.orange.shade100
                                          : Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      order.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isReturning
                                            ? Colors.orange.shade900
                                            : Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Penyewa: ${order.renterName}'),
                              Text('Batas Kembali: ${order.endDate}'),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isReturning
                                        ? const Color(0xFFF37021)
                                        : Colors.grey.shade400,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: isReturning
                                      ? () => _showReturnInspectionDialog(order)
                                      : null,
                                  icon: Icon(
                                    isReturning
                                        ? Icons.fact_check
                                        : Icons.hourglass_bottom,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isReturning
                                        ? 'Inspeksi & Selesai (Lepas Jaminan)'
                                        : 'Menunggu Penyewa Ajukan Pengembalian',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

            // TAB 4: MODUL 5 - ANALITIK & MODERASI ULASAN
            ListView(
              padding: const EdgeInsets.all(14),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4332),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Pendapatan Sewa & Denda',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Rp ${totalRevenue.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Total Transaksi: ${_orders.length} • Unit Terdaftar: ${_gears.length}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Moderasi Ulasan & Rating Pelanggan:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ..._reviews.map(
                  (rev) => Card(
                    child: ListTile(
                      title: Text('${rev.userName} • ⭐ ${rev.rating}'),
                      subtitle: Text(
                        '"${rev.comment}"\nBalasan: ${rev.ownerReply ?? "Belum dibalas"}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.reply, color: Color(0xFF1B4332)),
                        onPressed: () => _showReplyReviewDialog(rev),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
