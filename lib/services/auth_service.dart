import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String? _userRole;
  String? _assignedRestaurantId;
  bool _isLoading = true;

  User? get user => _user;
  String? get userRole => _userRole;
  String? get assignedRestaurantId => _assignedRestaurantId;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen((User? user) async {
      if (_user?.uid == user?.uid && _userRole != null) {
        // User hasn't changed and we already have the role, just update the user object
        _user = user;
        notifyListeners();
        return;
      }
      
      _user = user;
      if (user != null) {
        await _fetchUserData(user.uid);
      } else {
        _userRole = null;
        _assignedRestaurantId = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserData(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      print('🔍 Fetching role for UID: $uid');
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        _userRole = data?['role']?.toString().toLowerCase().trim();
        _assignedRestaurantId = data?['restaurantId'];
        print('✅ Role found: $_userRole');
      } else {
        print('⚠️ No user document found in Firestore for UID: $uid');
        _userRole = 'customer'; // Fallback
      }
    } catch (e) {
      print('❌ Error fetching user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Data will be fetched by the authStateChanges listener
      return result.user;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<User?> registerWithEmail(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await user.updateDisplayName(name.trim());
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': email.trim(),
          'name': name.trim(),
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('✅ Registration successful for: $email');
        return user;
      }
      return null;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}