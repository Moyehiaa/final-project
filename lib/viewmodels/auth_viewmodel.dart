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

  Future<void> refreshCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      _currentUser = UserModel.fromMap(doc.data()!);
      notifyListeners();
    }
  }

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

        await _attachPendingRequestsToCurrentUser(
          uid: firebaseUser.uid,
          email: _currentUser!.email,
        );
      } else {
        _currentUser = null;
        await _auth.signOut();
      }

      notifyListeners();
    } catch (_) {
      _currentUser = null;
      _error = 'Failed to load user data';
      notifyListeners();
    }
  }

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

      final user = UserModel(
        uid: uid,
        name: cleanName,
        email: cleanEmail,
        role: role,
        linkedUserEmail: null,
        linkedUserId: null,
        linkStatus: 'none',
      );

      await _db.collection('users').doc(uid).set({
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      _currentUser = user;

      if (cleanLinkedEmail.isNotEmpty) {
        await sendLinkRequest(cleanLinkedEmail);
      }

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authErrorMessage(e);
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Something went wrong';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

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

      await _attachPendingRequestsToCurrentUser(
        uid: cred.user!.uid,
        email: _currentUser!.email,
      );

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authErrorMessage(e);
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Login failed';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendLinkRequest(String targetEmail) async {
    final current = _currentUser;
    if (current == null) return;

    _setLoading(true);
    _error = null;

    try {
      final cleanTargetEmail = targetEmail.toLowerCase().trim();

      if (cleanTargetEmail.isEmpty) {
        _error = 'Enter user email';
        notifyListeners();
        return;
      }

      if (cleanTargetEmail == current.email) {
        _error = 'You cannot link with yourself';
        notifyListeners();
        return;
      }

      if (current.linkStatus == 'connected') {
        _error = 'You are already connected';
        notifyListeners();
        return;
      }

      final oldRequests = await _db
          .collection('linkRequests')
          .where('fromUserId', isEqualTo: current.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in oldRequests.docs) {
        await doc.reference.update({
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      }

      String? toUserId;

      final targetQuery = await _db
          .collection('users')
          .where('email', isEqualTo: cleanTargetEmail)
          .limit(1)
          .get();

      if (targetQuery.docs.isNotEmpty) {
        toUserId = targetQuery.docs.first.id;
      }

      await _db.collection('linkRequests').add({
        'fromUserId': current.uid,
        'fromName': current.name,
        'fromEmail': current.email,
        'fromRole': current.role.name,
        'toUserId': toUserId,
        'toEmail': cleanTargetEmail,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('users').doc(current.uid).update({
        'linkedUserId': null,
        'linkedUserEmail': cleanTargetEmail,
        'linkStatus': 'pending',
      });

      await refreshCurrentUser();
    } catch (_) {
      _error = 'Could not send link request';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> acceptLinkRequest({required String requestId}) async {
    final current = _currentUser;
    if (current == null) return;

    _setLoading(true);
    _error = null;

    try {
      final requestRef = _db.collection('linkRequests').doc(requestId);
      final requestDoc = await requestRef.get();

      if (!requestDoc.exists || requestDoc.data() == null) {
        _error = 'Request not found';
        notifyListeners();
        return;
      }

      final data = requestDoc.data()!;

      final fromUserId = data['fromUserId'] as String?;
      final fromEmail = data['fromEmail'] as String?;
      final toUserId = current.uid;
      final toEmail = current.email;

      if (fromUserId == null || fromEmail == null) {
        _error = 'Invalid request';
        notifyListeners();
        return;
      }

      await _db.runTransaction((transaction) async {
        transaction.update(_db.collection('users').doc(current.uid), {
          'linkedUserId': fromUserId,
          'linkedUserEmail': fromEmail,
          'linkStatus': 'connected',
        });

        transaction.update(_db.collection('users').doc(fromUserId), {
          'linkedUserId': toUserId,
          'linkedUserEmail': toEmail,
          'linkStatus': 'connected',
        });

        transaction.update(requestRef, {
          'status': 'accepted',
          'toUserId': toUserId,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });

      await refreshCurrentUser();
    } catch (_) {
      _error = 'Could not accept request';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> declineLinkRequest({required String requestId}) async {
    final current = _currentUser;
    if (current == null) return;

    _setLoading(true);
    _error = null;

    try {
      final requestRef = _db.collection('linkRequests').doc(requestId);
      final requestDoc = await requestRef.get();

      if (!requestDoc.exists || requestDoc.data() == null) return;

      final data = requestDoc.data()!;
      final fromUserId = data['fromUserId'] as String?;

      await _db.runTransaction((transaction) async {
        transaction.update(requestRef, {
          'status': 'declined',
          'declinedAt': FieldValue.serverTimestamp(),
        });

        if (fromUserId != null) {
          transaction.update(_db.collection('users').doc(fromUserId), {
            'linkedUserId': null,
            'linkedUserEmail': null,
            'linkStatus': 'none',
          });
        }

        transaction.update(_db.collection('users').doc(current.uid), {
          'linkedUserId': null,
          'linkedUserEmail': null,
          'linkStatus': 'none',
        });
      });

      await refreshCurrentUser();
    } catch (_) {
      _error = 'Could not decline request';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cancelOutgoingLinkRequest({required String requestId}) async {
    final current = _currentUser;
    if (current == null) return;

    _setLoading(true);
    _error = null;

    try {
      final requestRef = _db.collection('linkRequests').doc(requestId);
      final requestDoc = await requestRef.get();

      if (!requestDoc.exists || requestDoc.data() == null) return;

      final data = requestDoc.data()!;
      final fromUserId = data['fromUserId'];

      if (fromUserId != current.uid) {
        _error = 'You cannot cancel this request';
        notifyListeners();
        return;
      }

      await _db.runTransaction((transaction) async {
        transaction.update(requestRef, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        transaction.update(_db.collection('users').doc(current.uid), {
          'linkedUserId': null,
          'linkedUserEmail': null,
          'linkStatus': 'none',
        });
      });

      await refreshCurrentUser();
    } catch (_) {
      _error = 'Could not cancel request';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> unlinkCurrentUser() async {
    final current = _currentUser;
    if (current == null) return;

    final otherUserId = current.linkedUserId;

    _setLoading(true);
    _error = null;

    try {
      await _db.runTransaction((transaction) async {
        transaction.update(_db.collection('users').doc(current.uid), {
          'linkedUserId': null,
          'linkedUserEmail': null,
          'linkStatus': 'none',
        });

        if (otherUserId != null && otherUserId.isNotEmpty) {
          transaction.update(_db.collection('users').doc(otherUserId), {
            'linkedUserId': null,
            'linkedUserEmail': null,
            'linkStatus': 'none',
          });
        }
      });

      await refreshCurrentUser();
    } catch (_) {
      _error = 'Could not unlink user';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

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
    } catch (_) {
      _error = 'Logout failed';
      notifyListeners();
    }
  }

  Future<void> _attachPendingRequestsToCurrentUser({
    required String uid,
    required String email,
  }) async {
    final pending = await _db
        .collection('linkRequests')
        .where('toEmail', isEqualTo: email.toLowerCase().trim())
        .where('status', isEqualTo: 'pending')
        .get();

    for (final doc in pending.docs) {
      final data = doc.data();

      if (data['toUserId'] == null || data['toUserId'] == '') {
        await doc.reference.update({'toUserId': uid});
      }
    }
  }

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
