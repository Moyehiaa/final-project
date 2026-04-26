import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // =========================
  // 🔥 LOAD CURRENT USER (AuthGate)
  // =========================
  Future<void> loadCurrentUser() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      _currentUser = null;
      return;
    }

    try {
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();

      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromMap(doc.data()!);

        await _db.collection('users').doc(firebaseUser.uid).update({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } else {
        _currentUser = null;
        await _auth.signOut();
      }

      notifyListeners();
    } catch (e) {
      _currentUser = null;
      _error = 'Failed to load user data';
      notifyListeners();
    }
  }

  // =========================
  // 🔥 REGISTER
  // =========================
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String linkedEmail,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final cleanName = name.trim();
      final cleanEmail = email.toLowerCase().trim();
      final cleanLinkedEmail = linkedEmail.toLowerCase().trim();

      if (cleanName.isEmpty) {
        _error = 'Please enter your name';
        notifyListeners();
        return false;
      }

      if (cleanEmail.isEmpty) {
        _error = 'Please enter your email';
        notifyListeners();
        return false;
      }

      if (password.length < 6) {
        _error = 'Password must be at least 6 characters';
        notifyListeners();
        return false;
      }

      final cred = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final uid = cred.user!.uid;

      String? linkedUserId;
      String linkStatus = 'none';

      if (cleanLinkedEmail.isNotEmpty) {
        final query = await _db
            .collection('users')
            .where('email', isEqualTo: cleanLinkedEmail)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          linkedUserId = query.docs.first.id;
          linkStatus = 'connected';

          await _db.collection('users').doc(linkedUserId).update({
            'linkedUserId': uid,
            'linkedUserEmail': cleanEmail,
            'linkStatus': 'connected',
          });
        } else {
          linkStatus = 'pending';
        }
      }

      final user = UserModel(
        uid: uid,
        name: cleanName,
        email: cleanEmail,
        role: role,
        linkedUserEmail: cleanLinkedEmail.isEmpty ? null : cleanLinkedEmail,
        linkedUserId: linkedUserId,
        linkStatus: linkStatus,
      );

      await _db.collection('users').doc(uid).set({
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      _currentUser = user;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Something went wrong';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // 🔥 LOGIN
  // =========================
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _error = null;

    try {
      final cleanEmail = email.toLowerCase().trim();

      if (cleanEmail.isEmpty) {
        _error = 'Enter your email';
        notifyListeners();
        return false;
      }

      if (password.isEmpty) {
        _error = 'Enter your password';
        notifyListeners();
        return false;
      }

      final cred = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final doc = await _db.collection('users').doc(cred.user!.uid).get();

      if (!doc.exists || doc.data() == null) {
        _error = 'User profile not found';
        notifyListeners();
        return false;
      }

      _currentUser = UserModel.fromMap(doc.data()!);

      await _db.collection('users').doc(cred.user!.uid).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Login failed';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // 🔥 LOGOUT
  // =========================
  Future<void> logout() async {
    try {
      final uid = _auth.currentUser?.uid;

      if (uid != null) {
        await _db.collection('users').doc(uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _error = 'Logout failed';
      notifyListeners();
    }
  }

  // =========================
  // 🔥 ERRORS
  // =========================
  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'weak-password':
        return 'Weak password';
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Wrong password';
      case 'invalid-credential':
        return 'Wrong email or password';
      case 'network-request-failed':
        return 'No internet connection';
      default:
        return e.message ?? 'Auth error';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
