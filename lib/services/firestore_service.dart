import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---- Restaurants ----
  Stream<List<Restaurant>> getRestaurants() {
    return _firestore.collection('restaurants').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // ---- Get Restaurant by ID (NEW) ----
  Future<Restaurant?> getRestaurantById(String restaurantId) async {
    try {
      final doc = await _firestore.collection('restaurants').doc(restaurantId).get();
      if (doc.exists) {
        return Restaurant.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting restaurant: $e');
      return null;
    }
  }

  // ---- Menu Items ----
  Stream<List<MenuItem>> getMenuItems(String restaurantId) {
    return _firestore
        .collection('menu_items')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MenuItem.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // ---- Place Order ----
  Future<String> placeOrder(Map<String, dynamic> orderData) async {
    try {
      DocumentReference docRef = await _firestore.collection('orders').add(orderData);
      return docRef.id;
    } catch (e) {
      print('Error placing order: $e');
      throw e;
    }
  }

  // ---- Get Order (Real-time) ----
  Stream<DocumentSnapshot> getOrderStream(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots();
  }

  // ---- Update Order Status (for Restaurant Dashboard) ----
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---- Get All Orders (for Admin Dashboard) ----
  Stream<QuerySnapshot> getAllOrders() {
    return _firestore.collection('orders').orderBy('timestamp', descending: true).snapshots();
  }

  // ---- Get Orders for a Specific Restaurant (for Restaurant Dashboard) ----
  Stream<QuerySnapshot> getRestaurantOrders(String restaurantId) {
    return _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}