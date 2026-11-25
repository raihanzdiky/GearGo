import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/user_model.dart';
import '../models/gear_item.dart';
import '../models/booking_order.dart';
import '../models/review_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static UserModel? currentUser;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Menggunakan nama db baru v2 agar struktur tabel terbaru langsung terbentuk bersih
    _database = await _initDB('geargo_v4.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Tabel Users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    // 2. Tabel Gears + Gear Passport & Maintenance Log
    await db.execute('''
  CREATE TABLE gears (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unitCode TEXT NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    pricePerDay REAL NOT NULL,
    weightKg REAL NOT NULL,
    stock INTEGER NOT NULL,
    rating REAL NOT NULL,
    imageAsset TEXT NOT NULL,
    description TEXT,
    lastRentedDate TEXT,
    lastCleanedDate TEXT,
    waterproofStatus TEXT,
    maintenanceNotes TEXT,
    passportPhotoPath TEXT
  )
''');

    // 3. Tabel Orders (End-to-End Rental & Fulfillment)
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderCode TEXT NOT NULL,
        customerId INTEGER NOT NULL,
        renterName TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        gearId INTEGER NOT NULL,
        gearName TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        durationDays INTEGER NOT NULL,
        totalPrice REAL NOT NULL,
        guaranteeType TEXT NOT NULL,
        guaranteeNumber TEXT NOT NULL,
        kycPhotoPath TEXT,
        kycVerified INTEGER NOT NULL DEFAULT 0,
        paymentMethod TEXT NOT NULL,
        paymentVerified INTEGER NOT NULL DEFAULT 0,
        deliveryMethod TEXT NOT NULL,
        deliveryAddress TEXT,
        trackingNumber TEXT,
        status TEXT NOT NULL,
        fineAmount REAL NOT NULL DEFAULT 0,
        inspectionNotes TEXT,
        isReviewed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 4. Tabel Reviews & Moderasi Owner
    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        gearId INTEGER NOT NULL,
        userName TEXT NOT NULL,
        rating REAL NOT NULL,
        comment TEXT NOT NULL,
        ownerReply TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // --- SEED DATA AWAL ---
    await db.insert('users', {
      'fullName': 'Admin Toko GearGo',
      'email': 'owner@geargo.id',
      'phone': '081234567890',
      'password': '123',
      'role': 'owner',
    });
    await db.insert('users', {
      'fullName': 'Diky Raihan',
      'email': 'customer@geargo.id',
      'phone': '089876543210',
      'password': '123',
      'role': 'customer',
    });

    final initialGears = [
      {
        'unitCode': 'TND-A01',
        'name': 'Tenda Dome Kapasitas 4 Orang',
        'category': 'Tenda',
        'pricePerDay': 55000.0,
        'weightKg': 4.2,
        'stock': 5,
        'rating': 4.9,
        'imageAsset': 'assets/images/logo_geargo.png',
        'description': 'Tenda double layer waterproof PU 3000mm, frame alloy, lengkap 12 pasak & tali guyline.',
        'lastRentedDate': '18 Nov 2026',
        'lastCleanedDate': '20 Nov 2026 (Sterilisasi & Cuci Kering)',
        'waterproofStatus': 'Lolos Uji Semprot (100% Kedap Air)',
        'maintenanceNotes':
            'Seam seal baru diperbarui, resleting pintu utama lancar.',
      },
      {
        'unitCode': 'CRR-B02',
        'name': 'Tas Carrier 60L + Raincover',
        'category': 'Carrier',
        'pricePerDay': 40000.0,
        'weightKg': 2.1,
        'stock': 8,
        'rating': 4.8,
        'imageAsset': 'assets/images/logo_geargo.png',
        'description': 'Backsystem air-cooling ergonomis dengan rangka aluminium untuk pendakian 2-4 hari.',
        'lastRentedDate': '15 Nov 2026',
        'lastCleanedDate': '17 Nov 2026 (Cuci Antibakteri)',
        'waterproofStatus': 'Raincover Baru (Tahan Hujan Deras)',
        'maintenanceNotes': 'Semua buckle & tali kompresi utuh tanpa sobekan.',
      },
      {
        'unitCode': 'SLB-C01',
        'name': 'Sleeping Bag Polar Bulu Angsa',
        'category': 'Sleeping Bag',
        'pricePerDay': 25000.0,
        'weightKg': 1.1,
        'stock': 10,
        'rating': 4.7,
        'imageAsset': 'assets/images/logo_geargo.png',
        'description': 'Comfort rating hingga suhu 5°C, bahan luar parasut windproof, sangat ringkas.',
        'lastRentedDate': '19 Nov 2026',
        'lastCleanedDate': '21 Nov 2026 (Laundry & UV Steril)',
        'waterproofStatus': 'Water-Repellent Outer Shell',
        'maintenanceNotes': 'Wangi segar, dikemas dalam compression sack.',
      },
      {
        'unitCode': 'SPT-D04',
        'name': 'Sepatu Gunung Waterproof Mid-Cut',
        'category': 'Sepatu Gunung',
        'pricePerDay': 45000.0,
        'weightKg': 1.4,
        'stock': 4,
        'rating': 4.9,
        'imageAsset': 'assets/images/logo_geargo.png',
        'description': 'Outsole Vibram anti-slip untuk jalur berbatu dan berlumpur, perlindungan engkel maksimal.',
        'lastRentedDate': '14 Nov 2026',
        'lastCleanedDate': '16 Nov 2026 (Deep Clean & Deodorizer)',
        'waterproofStatus': 'Membran Gore-Tex Aktif',
        'maintenanceNotes': 'Sol masih tebal 95%, tali sepatu baru.',
      },
      {
        'unitCode': 'MSK-E01',
        'name': 'Kompor Portable Windproof + Nesting',
        'category': 'Alat Masak',
        'pricePerDay': 20000.0,
        'weightKg': 0.9,
        'stock': 7,
        'rating': 4.8,
        'imageAsset': 'assets/images/logo_geargo.png',
        'description':
            'Kompor bunga tahan angin + set panci teflon untuk 3-4 orang.',
        'lastRentedDate': '20 Nov 2026',
        'lastCleanedDate': '21 Nov 2026 (Sanitasi Food Grade)',
        'waterproofStatus': 'Pemantik Piezo Normal',
        'maintenanceNotes': 'Selang gas aman, tidak ada kebocoran.',
      },
    ];

    for (var gear in initialGears) {
      await db.insert('gears', gear);
    }

    // Seed 1 Ulasan awal agar Gear Passport langsung terlihat hidup
    await db.insert('reviews', {
      'orderId': 0,
      'gearId': 1,
      'userName': 'Saiful Aziz',
      'rating': 5.0,
      'comment': 'Tenda bersih banget, wangi, dan pas hujan badai di Papandayan sama sekali tidak rembes!',
      'ownerReply': 'Terima kasih Kak Saiful! Ditunggu petualangan berikutnya bersama GearGo.',
      'createdAt': '19 Nov 2026',
    });
  }

  // --- USERS ---
  // Tambahkan method ini di dalam class DatabaseHelper (bagian --- USERS ---)
  Future<int> updateUserProfile(UserModel user) async {
    final db = await instance.database;
    currentUser = user;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> registerUser(UserModel user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> loginUser(String email, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isNotEmpty) return UserModel.fromMap(maps.first);
    return null;
  }

  // --- GEARS & GEAR PASSPORT ---
  Future<List<GearItem>> getAllGears() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT g.*, COALESCE(AVG(r.rating), 0.0) AS avgRating
      FROM gears g
      LEFT JOIN reviews r ON g.id = r.gearId
      GROUP BY g.id
      ORDER BY g.id DESC
    ''');
    return result.map((json) {
      final map = Map<String, dynamic>.from(json);
      map['rating'] = (map['avgRating'] as num?)?.toDouble() ?? 0.0;
      return GearItem.fromMap(map);
    }).toList();
  }

  // Mengambil daftar kategori unik yang tersedia di database (otomatis mengikuti input Owner)
  Future<List<String>> getDistinctCategories() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT category FROM gears ORDER BY category ASC',
    );
    return result.map((row) => row['category'] as String).toList();
  }

  // Cek apakah kode unit sudah digunakan oleh alat lain (case-insensitive)
  Future<bool> isUnitCodeExists(String unitCode, {int? excludeGearId}) async {
    final db = await instance.database;
    final cleanCode = unitCode.trim().toUpperCase();
    final result = await db.query(
      'gears',
      where: excludeGearId != null
          ? 'UPPER(unitCode) = ? AND id != ?'
          : 'UPPER(unitCode) = ?',
      whereArgs: excludeGearId != null
          ? [cleanCode, excludeGearId]
          : [cleanCode],
    );
    return result.isNotEmpty;
  }

  Future<int> insertGear(GearItem gear) async {
    final db = await instance.database;
    return await db.insert('gears', gear.toMap());
  }

  Future<int> updateGear(GearItem gear) async {
    final db = await instance.database;
    return await db.update(
      'gears',
      gear.toMap(),
      where: 'id = ?',
      whereArgs: [gear.id],
    );
  }

  Future<int> updateGearPassport({
    required int gearId,
    required String lastCleanedDate,
    required String waterproofStatus,
    required String maintenanceNotes,
    String? passportPhotoPath,
  }) async {
    final db = await instance.database;
    final Map<String, dynamic> data = {
      'lastCleanedDate': lastCleanedDate,
      'waterproofStatus': waterproofStatus,
      'maintenanceNotes': maintenanceNotes,
    };
    if (passportPhotoPath != null) {
      data['passportPhotoPath'] = passportPhotoPath;
    }
    return await db.update('gears', data, where: 'id = ?', whereArgs: [gearId]);
  }

  Future<int> deleteGear(int id) async {
    final db = await instance.database;
    return await db.delete('gears', where: 'id = ?', whereArgs: [id]);
  }

  // --- ORDERS ---
  // Jika Owner menolak KYC, ubah status menjadi Ditolak dan kembalikan stok barang
  Future<void> rejectOrderAndRestoreStock(
    BookingOrder order,
    String reason,
  ) async {
    final db = await instance.database;
    order.kycVerified = 2;
    order.status = 'Ditolak ($reason)';
    await updateOrder(order);

    final gears = await db.query(
      'gears',
      where: 'id = ?',
      whereArgs: [order.gearId],
    );
    if (gears.isNotEmpty) {
      int currentStock = gears.first['stock'] as int;
      await db.update(
        'gears',
        {'stock': currentStock + order.quantity},
        where: 'id = ?',
        whereArgs: [order.gearId],
      );
    }
  }

  Future<int> insertOrder(BookingOrder order, int currentGearStock) async {
    final db = await instance.database;
    await db.update(
      'gears',
      {
        'stock': currentGearStock - order.quantity,
        'lastRentedDate': order.startDate,
      },
      where: 'id = ?',
      whereArgs: [order.gearId],
    );
    return await db.insert('orders', order.toMap());
  }

  Future<List<BookingOrder>> getAllOrders() async {
    final db = await instance.database;
    final result = await db.query('orders', orderBy: 'id DESC');
    return result.map((json) => BookingOrder.fromMap(json)).toList();
  }

  // Mengambil daftar pesanan khusus milik customer yang sedang login
  Future<List<BookingOrder>> getOrdersByCustomer(int customerId) async {
    final db = await instance.database;
    final result = await db.query(
      'orders',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'id DESC',
    );
    return result.map((json) => BookingOrder.fromMap(json)).toList();
  }

  Future<int> updateOrder(BookingOrder order) async {
    final db = await instance.database;
    return await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<void> completeOrderAndRestoreStock(
    BookingOrder order,
    double fine,
    String notes,
  ) async {
    final db = await instance.database;
    order.status = 'Selesai';
    order.fineAmount = fine;
    order.inspectionNotes = notes;
    await updateOrder(order);

    // Kembalikan stok alat
    final gears = await db.query(
      'gears',
      where: 'id = ?',
      whereArgs: [order.gearId],
    );
    if (gears.isNotEmpty) {
      int currentStock = gears.first['stock'] as int;
      await db.update(
        'gears',
        {'stock': currentStock + order.quantity},
        where: 'id = ?',
        whereArgs: [order.gearId],
      );
    }
  }

  // --- REVIEWS ---
  Future<int> insertReview(ReviewModel review, int orderId) async {
    final db = await instance.database;
    await db.update(
      'orders',
      {'isReviewed': 1},
      where: 'id = ?',
      whereArgs: [orderId],
    );
    return await db.insert('reviews', review.toMap());
  }

  Future<List<ReviewModel>> getReviewsByGear(int gearId) async {
    final db = await instance.database;
    final result = await db.query(
      'reviews',
      where: 'gearId = ?',
      whereArgs: [gearId],
      orderBy: 'id DESC',
    );
    return result.map((json) => ReviewModel.fromMap(json)).toList();
  }

  Future<List<ReviewModel>> getAllReviews() async {
    final db = await instance.database;
    final result = await db.query('reviews', orderBy: 'id DESC');
    return result.map((json) => ReviewModel.fromMap(json)).toList();
  }

  Future<int> replyReview(int reviewId, String replyText) async {
    final db = await instance.database;
    return await db.update(
      'reviews',
      {'ownerReply': replyText},
      where: 'id = ?',
      whereArgs: [reviewId],
    );
  }
}
