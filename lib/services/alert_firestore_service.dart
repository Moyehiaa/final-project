import 'package:cloud_firestore/cloud_firestore.dart';

class AlertFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendAlertToCaregiver({
    required String deafUserId,
    required String deafUserName,
    required String caregiverId,
    required String soundType,
    required double confidence,
  }) async {
    if (caregiverId.isEmpty) return;

    await _firestore.collection('alerts').add({
      'deafUserId': deafUserId,
      'deafUserName': deafUserName,
      'caregiverId': caregiverId,
      'soundType': soundType,
      'confidence': confidence,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
