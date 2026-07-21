import 'package:flutter/material.dart';
import '../models/menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
  });

  double get totalPrice => menuItem.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItem.id,
      'name': menuItem.name,
      'price': menuItem.price,
      'quantity': quantity,
    };
  }
}

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount {
    int count = 0;
    for (var item in _items) {
      count += item.quantity;
    }
    return count;
  }

  double get totalAmount {
    double total = 0;
    for (var item in _items) {
      total += item.totalPrice;
    }
    return total;
  }

  bool get isEmpty => _items.isEmpty;

  void addItem(MenuItem menuItem) {
    // Check if item already exists in cart
    final existingIndex = _items.indexWhere(
      (item) => item.menuItem.id == menuItem.id,
    );

    if (existingIndex >= 0) {
      // Increase quantity
      _items[existingIndex].quantity++;
    } else {
      // Add new item
      _items.add(CartItem(menuItem: menuItem));
    }
    notifyListeners();
  }

  void removeItem(MenuItem menuItem) {
    final existingIndex = _items.indexWhere(
      (item) => item.menuItem.id == menuItem.id,
    );

    if (existingIndex >= 0) {
      if (_items[existingIndex].quantity > 1) {
        _items[existingIndex].quantity--;
      } else {
        _items.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

  void removeAllItems(MenuItem menuItem) {
    _items.removeWhere((item) => item.menuItem.id == menuItem.id);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // For checkout - convert to order format
  List<Map<String, dynamic>> getOrderItems() {
    return _items.map((item) => item.toMap()).toList();
  }
}