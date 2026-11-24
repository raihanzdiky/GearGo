# 🏔️ GearGo — Aplikasi Mobile Rental Peralatan Outdoor

**GearGo** adalah aplikasi mobile berbasis **Flutter** dan **SQLite (`sqflite`)** yang dirancang untuk mendigitalisasi proses penyewaan peralatan *outdoor* dan pendakian gunung. Aplikasi ini memfasilitasi transaksi *end-to-end* antara **Penyewa (`Customer`)** dan **Pemilik Toko (`Owner`)** dengan standar keamanan jaminan identitas **Live Camera KYC** serta transparansi riwayat perawatan unit melalui **Gear Passport**.

---

## ✨ Fitur Utama

### 👤 Sisi Penyewa (`Customer`)
* **Katalog Dinamis & Pencarian Cepat:** Filter kategori otomatis menyesuaikan daftar peralatan yang ditambahkan oleh Owner secara *real-time*, dilengkapi pencarian nama maupun kode unit.
* **Smart Gear Checklist:** Rekomendasi paket peralatan otomatis berdasarkan jenis dan durasi perjalanan (*Camping Ceria*, *2H1M*, *Ekspedisi 3H2M+*, hingga kategori baru buatan Owner) yang dapat langsung dimasukkan ke keranjang dalam satu klik.
* **Kalkulator Berat Beban (*Weight Calculator*):** Membantu pendaki menghitung total estimasi beban perlengkapan yang akan dibawa sebelum melakukan perjalanan.
* **Keranjang Multi-Item & Sewa Langsung:** Mendukung penyewaan satu barang maupun banyak barang sekaligus dengan perhitungan durasi hari otomatis.
* **Wajib Validasi Live Camera KYC:** Penyewa wajib memotret kartu identitas asli (**KTP / KTM / SIM**) secara langsung menggunakan kamera perangkat saat *checkout* (tanpa akses galeri) untuk mencegah pemalsuan identitas.
* **Gear Passport & Zoomable Preview:** Penyewa dapat memeriksa catatan sterilisasi, status uji *waterproofing*, serta memperbesar foto kondisi fisik unit maupun foto produk dengan fitur *pinch-to-zoom* (`InteractiveViewer`).
* **Pelacakan Status & Ulasan:** Memantau status verifikasi KYC, status penyewaan, denda inspeksi, hingga memberikan rating dan ulasan setelah penyewaan selesai.

### 🛠️ Sisi Pemilik Toko (`Owner Dashboard`)
* **Manajemen Katalog Inventaris (CRUD):** Tambah, ubah, dan hapus unit peralatan dengan input kategori dinamis (`Autocomplete` + *free text*), validasi kode unit unik (*case-insensitive*), serta dukungan kamera dan galeri untuk foto produk.
* **Update Gear Passport (Live Camera):** Pencatatan log perawatan, pencucian, dan uji *waterproofing* unit yang wajib disertai foto bukti fisik langsung dari kamera gudang.
* **Verifikasi KYC (Terima / Tolak) & Pengembalian Stok Otomatis:** Owner dapat memperbesar foto kartu identitas yang dikirim penyewa untuk memvalidasi keasliannya. Jika ditolak dengan alasan tertentu, sistem otomatis membatalkan pesanan dan mengembalikan stok ke katalog.
* **Serah Terima & Input Resi:** Pencatatan berita acara kelengkapan fisik keluar serta input nomor resi pengiriman.
* **Return Tracker & Inspeksi Pengembalian:** Pemeriksaan kondisi fisik alat saat kembali, perhitungan denda keterlambatan/kerusakan, pelepasan jaminan KYC, dan pemulihan stok otomatis.
* **Analitik Pendapatan & Moderasi Ulasan:** Ringkasan total pendapatan sewa beserta denda, serta fitur membalas ulasan pelanggan secara resmi.

---

## 🏗️ Arsitektur & Struktur Proyek

```text
lib/
├── data/
│   └── cart_manager.dart            # Manajemen state keranjang multi-item
├── database/
│   └── database_helper.dart         # Pengelolaan SQLite (geargo_v4.db) & relasi stok
├── models/
│   ├── booking_order.dart           # Model transaksi, status KYC, pengiriman & denda
│   ├── gear_item.dart               # Model inventaris unit & atribut Gear Passport
│   ├── review_model.dart            # Model ulasan pelanggan & balasan Owner
│   └── user_model.dart              # Model autentikasi akun (Customer & Owner)
├── screens/
│   ├── account_screen.dart          # Profil pengguna & logout
│   ├── cart_screen.dart             # Keranjang multi-item & checkout Live Camera KYC
│   ├── detail_screen.dart           # Detail unit, Gear Passport & sewa langsung
│   ├── home_screen.dart             # Beranda katalog, pencarian & filter dinamis
│   ├── login_screen.dart            # Halaman masuk & registrasi akun
│   ├── owner_dashboard_screen.dart  # Dashboard 4-tab operasional Owner
│   ├── passport_screen.dart         # Riwayat pesanan Customer & form ulasan
│   ├── smart_checklist_screen.dart  # Rekomendasi paket alat berdasarkan perjalanan
│   └── weight_calc_screen.dart      # Kalkulator beban bawaan pendakian
├── widgets/
│   └── gear_image_widget.dart       # Renderer gambar lokal/aset & dialog pinch-to-zoom
└── main.dart                        # Entry point & konfigurasi tema aplikasi
```

## 🗄️ Skema Database (geargo_v4.db)
Aplikasi menggunakan penyimpanan lokal SQLite dengan 4 tabel utama:

users: Menyimpan data akun pengguna (fullName, username, password, phone, role).

gears: Menyimpan data inventaris alat (unitCode unik, name, category, pricePerDay, weightKg, stock, imageAsset, serta log lastCleanedDate, waterproofStatus, maintenanceNotes, passportPhotoPath).

orders: Menyimpan transaksi penyewaan (orderCode, customerId, gearId, quantity, startDate, endDate, totalPrice, guaranteeType, guaranteeNumber, kycPhotoPath, kycVerified, paymentMethod, deliveryMethod, status, fineAmount).

reviews: Menyimpan rating, komentar pelanggan, dan balasan resmi dari Owner.

## 🛠️ Teknologi & Dependensi
Framework: Flutter SDK (Dart)

Database Lokal: sqflite & path

Akses Kamera & Penyimpanan File: image_picker & path_provider

UI & Visualisasi: Material Design 3, InteractiveViewer (Pinch-to-Zoom)
