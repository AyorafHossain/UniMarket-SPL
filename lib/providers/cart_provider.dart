import 'dart:async';
import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  StreamSubscription<List<CartItemModel>>? _cartSubscription;
  
  List<CartItemModel> _items = [];
  String? _currentUserId;

  List<CartItemModel> get items => _items;
  
  int get itemCount => _items.length;

  double get totalPrice {
    double total = 0.0;
    for (var item in _items) {
      total += (item.price * item.quantity);
    }
    return total;
  }

  void updateUserId(String? userId) {
    if (_currentUserId == userId) return;
    
    _currentUserId = userId;
    _cartSubscription?.cancel();
    _items = [];
    
    if (userId != null) {
      _cartSubscription = _cartService.getCartStream(userId).listen((cartItems) {
        _items = cartItems;
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  Future<void> addItem(CartItemModel item) async {
    if (_currentUserId != null) {
      await _cartService.addToCart(_currentUserId!, item);
    }
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    if (_currentUserId != null) {
      await _cartService.updateQuantity(_currentUserId!, productId, newQuantity);
    }
  }

  Future<void> removeItem(String productId) async {
    if (_currentUserId != null) {
      await _cartService.removeFromCart(_currentUserId!, productId);
    }
  }

  Future<void> clearCart() async {
    if (_currentUserId != null) {
      await _cartService.clearCart(_currentUserId!);
    }
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }
}
