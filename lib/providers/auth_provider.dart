import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthProvider() {
    // Listen to Firebase auth state changes automatically.
    // This handles session restoration on app restart too.
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<void> signUp(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user!.updateDisplayName(name);

      // Create Firestore profile on sign-up
      await _db.collection('users').doc(cred.user!.uid).set({
        'displayName': name,
        'email': email,
        'totalScore': 0,
        'questsCompleted': 0,
        'fcmToken': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // _currentUser is updated automatically via authStateChanges()
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // _currentUser is set to null automatically via authStateChanges()
  }
}