import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  UserProvider() {
    _initialize();
  }

  void _initialize() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;

      if (user != null) {
        fetchUserData(user.uid);
      } else {
        _userData = null;
        _isLoading = false;
      }

      notifyListeners();
    });
  }

  Future<void> fetchUserData(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        _userData = doc.data();
      } else {

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set({
          'uid': userId,
          'email': _user?.email,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _userData = {
          'uid': userId,
          'email': _user?.email,
        };
      }
    } catch (e) {
      _error = e.toString();
      print('Error fetching user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await fetchUserData(_user!.uid);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      _user = null;
      _userData = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}