import '../models/gear_item.dart';

class CartItem {
  final GearItem gear;
  int quantity;
  bool isSelected;

  CartItem({required this.gear, this.quantity = 1, this.isSelected = true});
}

class CartManager {
  static final List<CartItem> items = [];

  static void addToCart(GearItem gear, {int quantity = 1}) {
    final index = items.indexWhere((item) => item.gear.id == gear.id);
    if (index != -1) {
      final newQty = items[index].quantity + quantity;
      items[index].quantity = newQty > gear.stock ? gear.stock : newQty;
    } else {
      items.add(
        CartItem(
          gear: gear,
          quantity: quantity > gear.stock ? gear.stock : quantity,
        ),
      );
    }
  }

  static void addMultipleToCart(List<GearItem> gears) {
    for (var gear in gears) {
      if (gear.isAvailable()) {
        addToCart(gear, quantity: 1);
      }
    }
  }

  static void removeItem(int gearId) {
    items.removeWhere((item) => item.gear.id == gearId);
  }

  static void removeSelectedItems() {
    items.removeWhere((item) => item.isSelected);
  }

  static List<CartItem> get selectedItems =>
      items.where((item) => item.isSelected).toList();

  static int get totalBadgeCount =>
      items.fold(0, (sum, item) => sum + item.quantity);
}
