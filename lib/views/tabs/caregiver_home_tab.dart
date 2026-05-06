import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../const.dart';
import '../../services/local_notification_service.dart';
import '../../viewmodels/auth_viewmodel.dart';

class CaregiverHomeTab extends StatefulWidget {
  const CaregiverHomeTab({super.key});

  @override
  State<CaregiverHomeTab> createState() => _CaregiverHomeTabState();
}

class _CaregiverHomeTabState extends State<CaregiverHomeTab> {
  final Set<String> _notifiedAlertIds = {};

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final caregiver = authVm.currentUser;

    if (caregiver == null) {
      return const Scaffold(body: Center(child: Text("User not found")));
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Caregiver",
              style: TextStyle(fontSize: 14, color: kText2),
            ),
            Text(
              caregiver.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: kText,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .where('caregiverId', isEqualTo: caregiver.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Could not load alerts",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final alerts = snapshot.data!.docs;

          _notifyForNewestUnreadAlerts(alerts);

          if (alerts.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: _EmptyAlertsCard(),
            );
          }

          final latest = alerts.first;
          final latestData = latest.data();
          final latestInfo = _SoundUiInfo.fromLabel(
            latestData['soundType'] ?? '',
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _LatestAlertCard(data: latestData, info: latestInfo),

                const SizedBox(height: 24),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Recent Alerts",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: kText,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _markAllAsRead(alerts),
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text("Mark read"),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                ...alerts.map((doc) {
                  final data = doc.data();
                  final info = _SoundUiInfo.fromLabel(data['soundType'] ?? '');
                  final isRead = data['isRead'] == true;

                  return _AlertListItem(
                    docId: doc.id,
                    data: data,
                    info: info,
                    isRead: isRead,
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _notifyForNewestUnreadAlerts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> alerts,
  ) {
    for (final doc in alerts.take(3)) {
      final data = doc.data();
      final isRead = data['isRead'] == true;
      final soundType = data['soundType'] ?? '';
      final confidence = (data['confidence'] ?? 0.0).toDouble();

      if (isRead) continue;
      if (_notifiedAlertIds.contains(doc.id)) continue;
      if (soundType.isEmpty) continue;

      _notifiedAlertIds.add(doc.id);

      LocalNotificationService.showSoundAlert(
        label: soundType,
        confidence: confidence,
      );
    }
  }

  Future<void> _markAllAsRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> alerts,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in alerts) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}

class _LatestAlertCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final _SoundUiInfo info;

  const _LatestAlertCard({required this.data, required this.info});

  @override
  Widget build(BuildContext context) {
    final deafName = data['deafUserName'] ?? 'Deaf user';
    final confidence = (data['confidence'] ?? 0.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: info.color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: info.color.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 106,
            height: 106,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(info.icon, size: 58, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Text(
            info.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$deafName needs attention",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              "Confidence ${(confidence * 100).toStringAsFixed(0)}%",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertListItem extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final _SoundUiInfo info;
  final bool isRead;

  const _AlertListItem({
    required this.docId,
    required this.data,
    required this.info,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    final deafName = data['deafUserName'] ?? 'Deaf user';
    final confidence = (data['confidence'] ?? 0.0).toDouble();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead ? kSurface : info.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRead
              ? Colors.black.withOpacity(0.05)
              : info.color.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: info.color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(info.icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$deafName • ${(confidence * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kText2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('alerts').doc(docId).update(
                {'isRead': true},
              );
            },
            icon: Icon(
              isRead
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isRead ? Colors.green : kText2,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAlertsCard extends StatelessWidget {
  const _EmptyAlertsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: kText2),
          SizedBox(height: 14),
          Text(
            "No alerts yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: kText,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "When the deaf user detects an important sound, it will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: kText2, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SoundUiInfo {
  final String title;
  final IconData icon;
  final Color color;

  const _SoundUiInfo({
    required this.title,
    required this.icon,
    required this.color,
  });

  factory _SoundUiInfo.fromLabel(String label) {
    switch (label) {
      case 'alarm':
        return const _SoundUiInfo(
          title: 'ALARM',
          icon: Icons.warning_amber_rounded,
          color: Color(0xFFD32F2F),
        );
      case 'siren':
        return const _SoundUiInfo(
          title: 'SIREN',
          icon: Icons.local_police_rounded,
          color: Color(0xFFC62828),
        );
      case 'baby_cry':
        return const _SoundUiInfo(
          title: 'BABY CRY',
          icon: Icons.child_care_rounded,
          color: Color(0xFF1976D2),
        );
      case 'glass_breaking':
        return const _SoundUiInfo(
          title: 'GLASS BREAKING',
          icon: Icons.broken_image_rounded,
          color: Color(0xFFB71C1C),
        );
      case 'knock':
        return const _SoundUiInfo(
          title: 'KNOCK',
          icon: Icons.front_hand_rounded,
          color: Color(0xFF795548),
        );
      case 'bell':
        return const _SoundUiInfo(
          title: 'BELL',
          icon: Icons.notifications_active_rounded,
          color: Color(0xFFF9A825),
        );
      case 'phone_ring':
        return const _SoundUiInfo(
          title: 'PHONE RING',
          icon: Icons.phone_in_talk_rounded,
          color: Color(0xFF2E7D32),
        );
      case 'dog':
        return const _SoundUiInfo(
          title: 'DOG',
          icon: Icons.pets_rounded,
          color: Color(0xFFEF6C00),
        );
      case 'speech':
        return const _SoundUiInfo(
          title: 'SPEECH',
          icon: Icons.record_voice_over_rounded,
          color: Color(0xFF616161),
        );
      default:
        return const _SoundUiInfo(
          title: 'SOUND ALERT',
          icon: Icons.notifications_active_rounded,
          color: kAccent,
        );
    }
  }
}
