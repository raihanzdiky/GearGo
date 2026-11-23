import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/user_model.dart';
import '../models/gear_item.dart';
import '../models/booking_order.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static UserModel? currentUser; // Menyimpan sesi user yang sedang login

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('geargo_uts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Tabel Users (2 Aktor: customer & owner)
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

    // 2. Tabel Gears (Katalog Alat Outdoor)
    await db.execute('''
      CREATE TABLE gears (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        pricePerDay REAL NOT NULL,
        weightKg REAL NOT NULL,
        stock INTEGER NOT NULL,
        description TEXT
      )
    ''');

    // 3. Tabel Orders (Riwayat Penyewaan)
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        renterName TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        gearId INTEGER NOT NULL,
        gearName TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        durationDays INTEGER NOT NULL,
        totalPrice REAL NOT NULL,
        notes TEXT,
        bookingDate TEXT NOT NULL
      )
    ''');

    // Seed Data Akun Default untuk memudahkan testing/presentasi
    await db.insert('users', {
      'fullName': 'Admin Toko Outdoor',
      'email': 'owner@geargo.id',
      'phone': '081234567890',
      'password': '123',
      'role': 'owner',
    });
    await db.insert('users', {
      'fullName': 'Diky & Saiful',
      'email': 'customer@geargo.id',
      'phone': '089876543210',
      'password': '123',
      'role': 'customer',
    });

    // Seed Data Peralatan Awal
    final initialGears = [
      {
        'name': 'Tenda Dome Kapasitas 4 Orang',
        'category': 'Tenda',
        'pricePerDay': 55000.0,
        'weightKg': 4.2,
        'stock': 5,
        'description':
            'Tenda double layer tahan badai, lengkap dengan pasak alloy.',
      },
      {
        'name': 'Tas Carrier 60L + Raincover',
        'category': 'Carrier',
        'pricePerDay': 40000.0,
        'weightKg': 2.1,
        'stock': 8,
        'description': 'Backsystem nyaman dengan rangka aluminium untuk pendakian 2-4 hari.',
      },
      {
        'name': 'Sleeping Bag Polar Bulu Angsa',
        'category': 'Sleeping Bag',
        'pricePerDay': 25000.0,
        'weightKg': 1.1,
        'stock': 10,
        'description':
            'Nyaman hingga suhu 5 derajat Celcius, ringkas saat dipacking.',
      },
      {
        'name': 'Sepatu Gunung Waterproof Mid-Cut',
        'category': 'Sepatu Gunung',
        'pricePerDay': 45000.0,
        'weightKg': 1.4,
        'stock': 4,
        'description':
            'Sol Vibram anti-slip untuk medan berbatu dan berlumpur.',
      },
      {
        'name': 'Kompor Portable Windproof + Nesting',
        'category': 'Alat Masak',
        'pricePerDay': 20000.0,
        'weightKg': 0.9,
        'stock': 7,
        'description': 'Paket lengkap alat masak untuk 3-4 orang.',
      },
    ];

    for (var gear in initialGears) {
      await db.insert('gears', gear);
    }
  }

  // --- OPERASI CRUD USERS (REGISTER & LOGIN) ---
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
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  // --- OPERASI CRUD GEARS (KATALOG & PEMILIK TOKO) ---
  Future<List<GearItem>> getAllGears() async {
    final db = await instance.database;
    final result = await db.query('gears', orderBy: 'id DESC');
    return result.map((json) => GearItem.fromMap(json)).toList();
  }

  Future<int> insertGear(GearItem gear) async {
    final db = await instance.database;
    return await db.insert('gears', gear.toMap());
  }

  Future<int> updateGearStock(int id, int newStock) async {
    final db = await instance.database;
    return await db.update(
      'gears',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteGear(int id) async {
    final db = await instance.database;
    return await db.delete('gears', where: 'id = ?', whereArgs: [id]);
  }

  // --- OPERASI CRUD ORDERS (TRANSAKSI PENYEWAAN) ---
  Future<int> insertOrder(BookingOrder order, int currentGearStock) async {
    final db = await instance.database;
    await updateGearStock(order.gearId, currentGearStock - order.quantity);
    return await db.insert('orders', order.toMap());
  }

  Future<List<BookingOrder>> getAllOrders() async {
    final db = await instance.database;
    final result = await db.query('orders', orderBy: 'id DESC');
    return result.map((json) => BookingOrder.fromMap(json)).toList();
  }

  Future<int> deleteOrder(BookingOrder order) async {
    final db = await instance.database;
    // Kembalikan stok barang saat pesanan dibatalkan
    final gears = await db.query(
      'gears',
      where: 'id = ?',
      whereArgs: [order.gearId],
    );
    if (gears.isNotEmpty) {
      int currentStock = gears.first['stock'] as int;
      await updateGearStock(order.gearId, currentStock + order.quantity);
    }
    return await db.delete('orders', where: 'id = ?', whereArgs: [order.id]);
  }
}
