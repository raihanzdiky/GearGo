import '../database/database_helper.dart';
import '../models/gear_item.dart';

class CartItem {
  final GearItem gear;
  int quantity;
  bool isSelected;

  CartItem({
    required this.gear,
    this.quantity = 1,
    this.isSelected = true,
  });
}

class CartManager {
  static final List<CartItem> items = [];

  static int get totalBadgeCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  // Muat keranjang dari SQLite saat customer login
  static Future<void> loadForCurrentUser() async {
    items.clear();
    final userId = DatabaseHelper.currentUser?.id;
    if (userId == null) return;

    final rows = await DatabaseHelper.instance.getCartItemsByCustomer(userId);
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      map['rating'] = (map['avgRating'] as num?)?.toDouble() ?? 0.0;
      final gear = GearItem.fromMap(map);
      if (gear.stock <= 0) continue;

      final savedQty = (row['cartQuantity'] as num?)?.toInt() ?? 1;
      final clampedQty = savedQty > gear.stock ? gear.stock : savedQty;
      final isSelected = (row['cartIsSelected'] as num?)?.toInt() == 1;

      items.add(CartItem(
        gear: gear,
        quantity: clampedQty,
        isSelected: isSelected,
      ));
    }
  }

  // Simpan perubahan quantity / checkbox 1 item ke SQLite
  static void syncItem(CartItem item) {
    final userId = DatabaseHelper.currentUser?.id;
    if (userId == null || item.gear.id == null) return;
    DatabaseHelper.instance.upsertCartItem(
      customerId: userId,
      gearId: item.gear.id!,
      quantity: item.quantity,
      isSelected: item.isSelected,
    );
  }

  static void addToCart(GearItem gear, {int quantity = 1}) {
    final index = items.indexWhere((item) => item.gear.id == gear.id);
    if (index != -1) {
      final newQty = items[index].quantity + quantity;
      items[index].quantity = newQty > gear.stock ? gear.stock : newQty;
      syncItem(items[index]);
    } else {
      final newItem = CartItem(
        gear: gear,
        quantity: quantity > gear.stock ? gear.stock : quantity,
      );
      items.add(newItem);
      syncItem(newItem);
    }
  }

  static void addMultipleToCart(List<GearItem> gears) {
    for (var gear in gears) {
      addToCart(gear);
    }
  }

  static void removeItem(int gearId) {
    items.removeWhere((item) => item.gear.id == gearId);
    final userId = DatabaseHelper.currentUser?.id;
    if (userId != null) {
      DatabaseHelper.instance.deleteCartItem(userId, gearId);
    }
  }

  static List<CartItem> get selectedItems =>
      items.where((item) => item.isSelected).toList();

  static void removeSelectedItems() {
    final userId = DatabaseHelper.currentUser?.id;
    if (userId != null) {
      for (final item in selectedItems) {
        if (item.gear.id != null) {
          DatabaseHelper.instance.deleteCartItem(userId, item.gear.id!);
        }
      }
    }
    items.removeWhere((item) => item.isSelected);
  }
}